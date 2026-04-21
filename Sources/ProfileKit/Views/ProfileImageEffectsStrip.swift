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
                // Index-keyed ForEach because the cache's `identifier`
                // deliberately collapses parameterized variants (two
                // `.sepia` intensities share a rendered preview). If a
                // host catalog contains duplicate identifiers, keying
                // by identifier would produce duplicate SwiftUI IDs.
                // Indices are always unique; the thumbnail cache still
                // keys by identifier under the hood.
                ForEach(catalog.indices, id: \.self) { index in
                    tile(for: catalog[index])
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

        // Downsample once to a CGImage (Sendable-clean), reuse across
        // all effects. CGImage round-trips easily through detached
        // tasks; CIImage isn't formally Sendable so we reconstruct it
        // inside each detached per-effect task instead.
        guard let baseCGImage = await makeThumbnailCGImage(from: sourceImage) else {
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

            // Detached per-effect task keeps the filter + encode off
            // the main actor. The `await` between iterations yields
            // back to the run loop so tiles animate in progressively
            // rather than the strip hitching while all 11 render in a
            // blocking loop. `Self.ciContext` is a class reference
            // that Apple documents as thread-safe for the methods we
            // use; `CGImage` and `ProfileImageEffect` are both
            // effectively Sendable.
            let cgImage: CGImage? = await Task.detached(priority: .userInitiated) {
                let ciImage = CIImage(cgImage: baseCGImage)
                let filtered = EffectsPipeline.apply(entry, to: ciImage)
                return Self.ciContext.createCGImage(filtered, from: ciImage.extent)
            }.value

            guard let cgImage else { continue }
            thumbnails[entry.identifier] = Image(platformImage: PlatformImageBridge.makeImage(from: cgImage))
        }
    }

    /// Shared CIContext for thumbnail rendering. CIContext creation is
    /// expensive enough that sharing is the common pattern even for
    /// short-lived views. `nonisolated` because the View type is
    /// `@MainActor`-isolated by default but the thumbnail-generation
    /// loop reads this from a detached task — CIContext is Sendable
    /// so a plain `nonisolated` declaration is enough.
    nonisolated private static let ciContext = CIContext(options: nil)

    /// Build a center-cropped, downsampled CGImage suitable for the
    /// film strip. Detached to keep the draw off the main actor.
    /// Returns CGImage rather than CIImage because CGImage is
    /// effectively Sendable (and formally will be once Apple annotates
    /// CoreGraphics) — letting us pass the base across the actor
    /// boundary into each per-effect detached task without Swift 6
    /// Sendable complaints.
    private func makeThumbnailCGImage(from source: PKPlatformImage) async -> CGImage? {
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

            return context.makeImage()
        }.value
    }
}
