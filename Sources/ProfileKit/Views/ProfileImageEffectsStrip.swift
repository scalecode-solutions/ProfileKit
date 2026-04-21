import CoreGraphics
import CoreImage
import SwiftUI

/// Horizontal film-strip of effect previews. Each tile shows the
/// source image with that preset applied, tappable to select.
///
/// Tiles render against a downsampled, center-cropped version of the
/// source so the 11-preset catalog doesn't pay for 11 full-resolution
/// filter passes. Thumbnails are generated lazily on appear and
/// cached in-view; when the source image changes, the cache rebuilds
/// from scratch. The cache lives in-view (not in a global singleton)
/// so it's collected with the editor when it closes.
///
/// The strip is a chromeless row — horizontal padding is the caller's
/// responsibility, matching the convention of the transform toolbar
/// and adjustment controls. A section heading lives above the strip
/// (provided by `ProfileImageEditorContent`), not inside it.
struct ProfileImageEffectsStrip: View {
    let sourceImage: PKPlatformImage
    @Binding var effect: ProfileImageEffect
    let catalog: [ProfileImageEffect]
    let texts: ProfileImageEditorTexts

    /// In-memory thumbnail cache keyed by effect identifier so two
    /// sepia intensities can share a rendered preview. Value is a
    /// SwiftUI Image so the cell doesn't re-render on every state tick.
    @State private var thumbnails: [String: Image] = [:]
    /// Object identity of the source that produced the current cache.
    /// When the source changes, the cache is rebuilt from scratch.
    @State private var thumbnailSourceID: ObjectIdentifier?

    private let tileDimension: CGFloat = 72
    private let thumbnailRenderDimension: CGFloat = 256

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(catalog, id: \.identifier) { entry in
                    tile(for: entry)
                }
            }
            .padding(.horizontal, 24)
        }
        .task(id: ObjectIdentifier(sourceImage)) {
            await rebuildThumbnails()
        }
    }

    // MARK: - Tile

    private func tile(for entry: ProfileImageEffect) -> some View {
        let isSelected = entry.identifier == effect.identifier

        return Button {
            effect = entry
        } label: {
            VStack(spacing: 6) {
                Group {
                    if let thumbnail = thumbnails[entry.identifier] {
                        thumbnail
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Placeholder while the thumbnail renders.
                        // Uses the same shape/size as the final tile so
                        // the strip layout doesn't jump.
                        Rectangle()
                            .fill(.secondary.opacity(0.15))
                    }
                }
                .frame(width: tileDimension, height: tileDimension)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                            lineWidth: isSelected ? 3 : 1
                        )
                )

                Text(texts.displayName(for: entry))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Thumbnail generation

    /// Rebuilds the thumbnail cache from a downsampled version of the
    /// source image. Runs in a cooperative task so the UI stays
    /// responsive while the 11 filter passes execute; tiles animate in
    /// as each identifier's preview lands.
    private func rebuildThumbnails() async {
        let currentID = ObjectIdentifier(sourceImage)
        // Clear stale thumbnails from a prior source immediately so the
        // user doesn't see the wrong photo under the new effects.
        if thumbnailSourceID != currentID {
            thumbnails.removeAll(keepingCapacity: true)
            thumbnailSourceID = currentID
        }

        // Downsample once, reuse across all effects.
        guard let base = await makeThumbnailCIImage(from: sourceImage) else {
            return
        }

        // Seed unique identifiers so we don't render the same filter
        // twice when the catalog contains duplicates (host error, but
        // harmless to defend against).
        var rendered: Set<String> = []

        for entry in catalog {
            guard !Task.isCancelled else { return }
            guard !rendered.contains(entry.identifier) else { continue }
            rendered.insert(entry.identifier)

            let filtered = EffectsPipeline.apply(entry, to: base)
            guard let cgImage = Self.ciContext.createCGImage(filtered, from: base.extent) else {
                continue
            }
            let platformImage = PlatformImageBridge.makeImage(from: cgImage)
            thumbnails[entry.identifier] = Image(platformImage: platformImage)
        }
    }

    /// Shared CIContext for thumbnail rendering. Created once per view
    /// lifetime; CIContext creation is expensive enough that sharing is
    /// the common pattern even for short-lived views.
    private static let ciContext = CIContext(options: nil)

    /// Build a center-cropped, downsampled CIImage suitable for the
    /// film strip. Detached to keep the draw off the main actor.
    private func makeThumbnailCIImage(from source: PKPlatformImage) async -> CIImage? {
        await Task.detached(priority: .userInitiated) { [thumbnailRenderDimension] in
            let pixelSize = PlatformImageBridge.pixelSize(for: source)
            guard pixelSize.width > 0, pixelSize.height > 0 else { return nil }

            let shortEdge = min(pixelSize.width, pixelSize.height)
            let cropOriginX = (pixelSize.width - shortEdge) / 2
            let cropOriginY = (pixelSize.height - shortEdge) / 2

            // Build a square-crop CGImage at thumbnailRenderDimension.
            guard let fullCG = PlatformImageBridge.cgImage(from: source) else { return nil }

            let dimension = Int(thumbnailRenderDimension.rounded())
            guard let context = CGContext(
                data: nil,
                width: dimension,
                height: dimension,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            context.interpolationQuality = .medium

            // Draw the source centered so the short edge fills the
            // square. Standard "aspectFill to square" math — the
            // thumbnail cache can then share a single base across all
            // effects instead of recomputing the crop per-preset.
            let scale = thumbnailRenderDimension / shortEdge
            let drawWidth = pixelSize.width * scale
            let drawHeight = pixelSize.height * scale
            let drawRect = CGRect(
                x: -cropOriginX * scale,
                y: -cropOriginY * scale,
                width: drawWidth,
                height: drawHeight
            )
            context.draw(fullCG, in: drawRect)

            guard let cropped = context.makeImage() else { return nil }
            return CIImage(cgImage: cropped)
        }.value
    }
}
