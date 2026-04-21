import SwiftUI

/// SwiftUI live preview for a designed initials avatar. Two paths:
/// - Pass only a `ProfileIdentity` + `ProfileAvatarConfiguration`
///   (the original entry point) — renders today's look: deterministic
///   auto gradient, semibold rounded glyph, border per configuration.
/// - Pass a `ProfileInitialsStyle` as well — the style wins on every
///   axis the initials renderer cares about (background, glyph,
///   typography, shadow), so the SwiftUI preview visually matches
///   what `ProfileInitialsRenderer.render(...)` will bake on commit.
///
/// The second path is how the initials editor displays its canvas:
/// style binds to the editor's state, the view re-renders live as
/// the user drags sliders, and committing pushes the same style
/// through the renderer to produce the final pixel-identical image.
public struct InitialsAvatarView: View {
    public let identity: ProfileIdentity
    public let style: ProfileInitialsStyle?
    public let configuration: ProfileAvatarConfiguration

    public init(
        identity: ProfileIdentity,
        style: ProfileInitialsStyle? = nil,
        configuration: ProfileAvatarConfiguration = .init()
    ) {
        self.identity = identity
        self.style = style
        self.configuration = configuration
    }

    public var body: some View {
        ZStack {
            background
            glyph
        }
        .frame(width: configuration.size, height: configuration.size)
        .clipShape(ProfileAvatarClipShape(shape: configuration.shape))
        .overlay(
            ProfileAvatarClipShape(shape: configuration.shape)
                .inset(by: configuration.borderWidth / 2)
                .stroke(configuration.borderColor.color, lineWidth: configuration.borderWidth)
        )
        .accessibilityLabel(identity.displayName.isEmpty ? resolvedGlyph : identity.displayName)
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if let style {
            renderedBackground(for: style.background)
        } else {
            // Legacy path: today's auto gradient from .automatic palette.
            LinearGradient(
                colors: ProfileAvatarPalette.colors(for: identity.resolvedSeed),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private func renderedBackground(for background: ProfileInitialsBackground) -> some View {
        switch background {
        case .solid(let color):
            color.color
        case .linearGradient(let stops, let angleDegrees):
            LinearGradient(
                stops: gradientStops(for: stops),
                startPoint: gradientStartPoint(angleDegrees: angleDegrees),
                endPoint: gradientEndPoint(angleDegrees: angleDegrees)
            )
        case .radialGradient(let stops):
            RadialGradient(
                stops: gradientStops(for: stops),
                center: .center,
                startRadius: 0,
                // endRadius proportional to the canvas so live preview
                // at any configuration.size matches the renderer's
                // max-edge radius choice.
                endRadius: configuration.size / 2
            )
        case .deterministicPalette(let paletteName):
            LinearGradient(
                colors: ProfileAvatarPalette.colors(for: identity.resolvedSeed, palette: paletteName)
                    .map { $0.color },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func gradientStops(for colors: [ProfileColor]) -> [Gradient.Stop] {
        guard !colors.isEmpty else { return [] }
        if colors.count == 1 {
            return [Gradient.Stop(color: colors[0].color, location: 0)]
        }
        let last = Double(colors.count - 1)
        return colors.enumerated().map { index, color in
            Gradient.Stop(color: color.color, location: Double(index) / last)
        }
    }

    /// Convert compass-style angle (0° = right, CW positive) to a
    /// SwiftUI `UnitPoint` for the gradient's start. Mirrors the
    /// renderer's angle convention so the SwiftUI preview and the
    /// baked output match.
    private func gradientStartPoint(angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(
            x: 0.5 - cos(radians) * 0.5,
            y: 0.5 + sin(radians) * 0.5
        )
    }

    private func gradientEndPoint(angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(
            x: 0.5 + cos(radians) * 0.5,
            y: 0.5 - sin(radians) * 0.5
        )
    }

    // MARK: - Glyph

    private var resolvedGlyph: String {
        style?.resolvedGlyph(for: identity) ?? identity.initials
    }

    @ViewBuilder
    private var glyph: some View {
        let weight = style?.fontWeight ?? configuration.fontWeight
        let design = style?.fontDesign ?? configuration.fontDesign
        let scale = style?.fontScale ?? 0.38
        let foreground = style?.foregroundColor ?? configuration.resolvedForegroundColor
        let letterSpacing = style?.letterSpacing ?? 0
        let verticalBias = style?.verticalBias ?? 0

        let text = Text(resolvedGlyph)
            .font(.system(
                size: configuration.size * scale,
                weight: weight.fontWeight,
                design: design.fontDesign
            ))
            .tracking(letterSpacing)
            .foregroundStyle(foreground.color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .offset(y: configuration.size * verticalBias)

        if let shadow = style?.shadow {
            text.shadow(
                color: shadow.color.opacity(shadow.opacity).color,
                radius: shadow.radius,
                x: shadow.offset.width,
                y: shadow.offset.height
            )
        } else {
            text
        }
    }
}
