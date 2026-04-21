import CoreGraphics
import CoreText
import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders a designed-initials avatar to a `ProfileImageEditResult` —
/// same output shape as the photo path so host code that persists /
/// uploads `ProfileImageEditResult.data` doesn't need to learn about
/// initials as a separate case.
///
/// Pipeline:
///   1. CGBitmapContext at `exportDimension × exportDimension`.
///   2. Optional circular alpha mask (same rule as the photo renderer:
///      caller asked for circular export AND the crop shape is a
///      circle).
///   3. Background fill — solid color, CGGradient, or palette-derived
///      gradient.
///   4. Optional drop shadow via `CGContext.setShadow`.
///   5. Glyph draw via Core Text (CTLine) with cap-height-centered
///      positioning + vertical bias offset.
///   6. Encode to JPEG / PNG via the shared ProfileImageEncoding.
///
/// The renderer is cross-platform — it goes through CTFont rather than
/// UIFont/NSFont helpers so there's no platform-conditional drawing
/// code past the font construction.
public enum ProfileInitialsRenderer {
    /// Async convenience — offloads the CGContext draw + Core Text
    /// measure + encode to a detached cooperative task so a large
    /// `exportDimension` doesn't stall the main thread on commit.
    public static func renderAsync(
        draft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) async throws -> ProfileImageEditResult {
        try await Task.detached(priority: .userInitiated) {
            try render(draft: draft, configuration: configuration)
        }.value
    }

    public static func render(
        draft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) throws -> ProfileImageEditResult {
        // JPEG can't carry alpha. The photo renderer silently upgrades
        // to PNG when circular export is requested — match that
        // behavior here via the shared encoding helper so hosts don't
        // see divergent format rules across the two paths.
        let renderConfiguration = ProfileImageEncoding.effectiveRenderConfiguration(
            configuration.renderConfiguration,
            cropShape: configuration.cropShape
        )

        let dimension = max(renderConfiguration.exportDimension, 1)
        let canvasSize = CGFloat(dimension)
        let rect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

        guard let context = CGContext(
            data: nil,
            width: dimension,
            height: dimension,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ProfileImageRenderingError.contextCreationFailed
        }

        context.interpolationQuality = .high

        // Same circular-mask pattern as the photo renderer. Installed
        // before the background fill so off-circle pixels stay
        // transparent in the final PNG.
        let useCircularMask = renderConfiguration.cropImageCircular
            && configuration.cropShape == .circle
        if useCircularMask {
            context.saveGState()
            context.addEllipse(in: rect)
            context.clip()
        }

        drawBackground(draft.style.background, seed: draft.identity.resolvedSeed,
                       in: rect, context: context)

        drawGlyph(
            draft: draft,
            canvasSize: canvasSize,
            context: context
        )

        if useCircularMask {
            context.restoreGState()
        }

        guard let cgImage = context.makeImage() else {
            throw ProfileImageRenderingError.exportFailed
        }

        let platformImage = PlatformImageBridge.makeImage(from: cgImage)
        let data = try ProfileImageEncoding.encodedData(from: cgImage, configuration: renderConfiguration)

        return ProfileImageEditResult(
            image: platformImage,
            data: data,
            contentType: renderConfiguration.outputType,
            origin: .initials(identity: draft.identity, style: draft.style)
        )
    }

    // MARK: - Background

    private static func drawBackground(
        _ background: ProfileInitialsBackground,
        seed: String,
        in rect: CGRect,
        context: CGContext
    ) {
        switch background {
        case .solid(let color):
            context.setFillColor(color.cgColor)
            context.fill(rect)

        case .linearGradient(let stops, let angleDegrees):
            drawLinearGradient(stops: stops, angleDegrees: angleDegrees, rect: rect, context: context)

        case .radialGradient(let stops):
            drawRadialGradient(stops: stops, rect: rect, context: context)

        case .deterministicPalette(let paletteName):
            let colors = ProfileAvatarPalette.colors(for: seed, palette: paletteName)
            // Deterministic palette renders as a linear gradient from
            // top-leading to bottom-trailing — matches today's
            // InitialsAvatarView default look exactly.
            drawLinearGradient(
                stops: colors,
                angleDegrees: 135,
                rect: rect,
                context: context
            )
        }
    }

    private static func drawLinearGradient(
        stops: [ProfileColor],
        angleDegrees: Double,
        rect: CGRect,
        context: CGContext
    ) {
        guard let gradient = makeCGGradient(from: stops) else {
            // Fallback: fill with the first stop. Guards against the
            // zero-stop edge case — the editor enforces 2…3 but a host
            // constructing styles by hand could land here.
            if let first = stops.first {
                context.setFillColor(first.cgColor)
                context.fill(rect)
            }
            return
        }

        // Convert degrees (compass-style, 0° = right, CW) to radians
        // and compute start / end points at the rect's bounding circle.
        // Using the bounding circle rather than the rect edges means
        // the gradient reads the same at any angle without the
        // "compressed at diagonal angles" artifact you get when
        // clamping to rect edges.
        let radians = angleDegrees * .pi / 180
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfDiagonal = sqrt(rect.width * rect.width + rect.height * rect.height) / 2
        let dx = cos(radians) * halfDiagonal
        let dy = sin(radians) * halfDiagonal
        // CG's default coordinate system is Y-up but angleDegrees is a
        // display-space angle where positive Y goes down. Negate dy so
        // 90° (display "down") draws toward the bottom of the canvas.
        let start = CGPoint(x: center.x - dx, y: center.y + dy)
        let end = CGPoint(x: center.x + dx, y: center.y - dy)

        context.drawLinearGradient(
            gradient,
            start: start,
            end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    private static func drawRadialGradient(
        stops: [ProfileColor],
        rect: CGRect,
        context: CGContext
    ) {
        guard let gradient = makeCGGradient(from: stops) else {
            if let first = stops.first {
                context.setFillColor(first.cgColor)
                context.fill(rect)
            }
            return
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) / 2

        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    private static func makeCGGradient(from stops: [ProfileColor]) -> CGGradient? {
        guard !stops.isEmpty else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = stops.map { $0.cgColor } as CFArray

        // Distribute stops evenly across 0…1 — the editor doesn't
        // currently expose per-stop locations, so the visual result is
        // "two stops: 0 and 1", "three stops: 0, 0.5, 1". If a future
        // UI exposes custom locations, this array becomes a parameter.
        let locations: [CGFloat]
        switch stops.count {
        case 1: locations = [0]
        case 2: locations = [0, 1]
        default:
            let last = CGFloat(stops.count - 1)
            locations = (0..<stops.count).map { CGFloat($0) / last }
        }

        return CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations)
    }

    // MARK: - Glyph

    private static func drawGlyph(
        draft: ProfileInitialsDraft,
        canvasSize: CGFloat,
        context: CGContext
    ) {
        let glyph = draft.style.resolvedGlyph(for: draft.identity)
        guard !glyph.isEmpty else { return }

        let pointSize = canvasSize * draft.style.fontScale
        let font = makeCTFont(
            size: pointSize,
            weight: draft.style.fontWeight,
            design: draft.style.fontDesign
        )

        // Core Text attributes. Note: `.kern` is a CoreText attribute
        // (CFNumber) — bridging an NSNumber works because the key is
        // CFString-bridged to NSAttributedString.Key.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: draft.style.foregroundColor.cgColor,
            .kern: NSNumber(value: Double(draft.style.letterSpacing))
        ]

        let attributedString = NSAttributedString(string: glyph, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)

        // Typographic bounds give us ascent / descent / leading. We
        // center on cap-height rather than glyph bbox so variable-
        // width glyph sets (single M vs narrow I) sit at the same
        // optical height. Cap height is approximated as ascent * 0.72
        // — tuned against SF Pro Rounded semibold; close enough
        // visually across the other ProfileFontDesign variants without
        // per-font calibration.
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let typographicWidth = CGFloat(
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        )
        let capHeight = ascent * 0.72

        // Vertical bias applied as a fraction of the canvas. Negative
        // biases push the glyph UP in display space, which in CG's Y-up
        // coord system means ADDING to y.
        let verticalOffset = canvasSize * draft.style.verticalBias

        let textPosition = CGPoint(
            x: (canvasSize - typographicWidth) / 2,
            y: (canvasSize - capHeight) / 2 - verticalOffset
        )

        // Shadow: installed immediately before the CTLineDraw call.
        // Core Graphics shadows apply to subsequent draws until the
        // state is restored, so bracketing with saveGState /
        // restoreGState keeps the mask (if any) and the background
        // fill free of the shadow.
        if let shadow = draft.style.shadow {
            context.saveGState()
            let cgColor = shadow.color.opacity(shadow.opacity).cgColor
            // CGContext.setShadow expects display-space offsets but
            // interprets them in Y-up coordinates. Negate the Y
            // component so positive `offset.y` pushes the shadow
            // DOWN visually, matching SwiftUI's .shadow convention.
            let offset = CGSize(width: shadow.offset.width, height: -shadow.offset.height)
            context.setShadow(offset: offset, blur: shadow.radius, color: cgColor)
        }

        context.textPosition = textPosition
        CTLineDraw(line, context)

        if draft.style.shadow != nil {
            context.restoreGState()
        }
    }

    /// Build a `CTFont` for the given size / weight / design. Bridges
    /// through the platform-native font APIs because they're the
    /// canonical path to the SF Pro family — constructing directly
    /// through Core Text skips the platform's weight-per-design
    /// mapping table and can yield the wrong face on some weight /
    /// design combinations.
    private static func makeCTFont(
        size: CGFloat,
        weight: ProfileFontWeight,
        design: ProfileFontDesign
    ) -> CTFont {
        #if canImport(UIKit)
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        if design == .default {
            return baseFont as CTFont
        }
        if let descriptor = baseFont.fontDescriptor.withDesign(design.uiFontDescriptorDesign) {
            return UIFont(descriptor: descriptor, size: size) as CTFont
        }
        return baseFont as CTFont
        #elseif canImport(AppKit)
        let baseFont = NSFont.systemFont(ofSize: size, weight: weight.nsFontWeight)
        if design == .default {
            return baseFont as CTFont
        }
        if let descriptor = baseFont.fontDescriptor.withDesign(design.nsFontDescriptorDesign) {
            return NSFont(descriptor: descriptor, size: size).map { $0 as CTFont } ?? (baseFont as CTFont)
        }
        return baseFont as CTFont
        #endif
    }
}

// MARK: - Platform font bridges

#if canImport(UIKit)
private extension ProfileFontWeight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}

private extension ProfileFontDesign {
    var uiFontDescriptorDesign: UIFontDescriptor.SystemDesign {
        switch self {
        case .default:     return .default
        case .serif:       return .serif
        case .rounded:     return .rounded
        case .monospaced:  return .monospaced
        }
    }
}
#elseif canImport(AppKit)
private extension ProfileFontWeight {
    var nsFontWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}

private extension ProfileFontDesign {
    var nsFontDescriptorDesign: NSFontDescriptor.SystemDesign {
        switch self {
        case .default:     return .default
        case .serif:       return .serif
        case .rounded:     return .rounded
        case .monospaced:  return .monospaced
        }
    }
}
#endif
