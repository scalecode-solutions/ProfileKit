import CoreGraphics
import Foundation

/// Background fill for a designed initials avatar. Paired with the
/// rest of `ProfileInitialsStyle` — foreground color, typography,
/// optional shadow — to produce a commit-ready rendered image on
/// par with a cropped photo.
///
/// Four variants locked:
/// - `solid(_:)` — single color fill.
/// - `linearGradient(stops:angleDegrees:)` — two or three stops,
///   angle in degrees with 0° pointing right and increasing clockwise.
///   Default in `ProfileInitialsStyle.default` is 135° (top-leading to
///   bottom-trailing) which reads diagonal on most canvases.
/// - `radialGradient(stops:)` — two or three stops, center fixed to
///   the canvas center. Positionable center is deliberately deferred;
///   adds a drag-handle UI that dominates the editor for a niche need.
/// - `deterministicPalette(_:)` — the per-identity auto gradient,
///   equivalent to today's `ProfileAvatarPalette` output. Named palette
///   variants let hosts pick a mood without losing the per-name
///   determinism.
///
/// Gradient stops are stored as a `[ProfileColor]` with a documented
/// 2…3 range rather than a `GradientStops` struct because SwiftUI's
/// own gradient APIs take arrays and forcing a bespoke struct would
/// just duplicate that shape without buying anything. The editor UI
/// clamps stop counts on entry.
public enum ProfileInitialsBackground: Equatable, Hashable, Sendable, Codable {
    case solid(ProfileColor)
    case linearGradient(stops: [ProfileColor], angleDegrees: Double)
    case radialGradient(stops: [ProfileColor])
    case deterministicPalette(ProfileAvatarPaletteName)

    /// True when the background produces a per-identity look via the
    /// palette catalog. Lets the renderer resolve the final colors
    /// lazily from the identity rather than stamping a fixed pair
    /// into the style.
    public var usesDeterministicPalette: Bool {
        if case .deterministicPalette = self { return true }
        return false
    }
}

/// Named palette variants for the deterministic auto-gradient
/// background. `.automatic` matches today's `ProfileAvatarPalette`
/// output exactly; the other names give hosts a mood control without
/// losing the per-identity determinism.
///
/// Resolution happens at render time via the palette catalog
/// expansion in step 17. Until then the renderer will treat every
/// variant as `.automatic`.
public enum ProfileAvatarPaletteName: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case automatic
    case mono
    case warm
    case cool
    case vibrant
    case pastel
}
