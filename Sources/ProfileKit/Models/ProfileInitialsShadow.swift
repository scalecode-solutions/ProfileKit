import CoreGraphics
import Foundation

/// Optional drop shadow behind the initials glyph. Applied in the
/// renderer via `CGContext.setShadow` before the glyph draw so the
/// shadow renders underneath the text without affecting the
/// background fill.
///
/// Units:
/// - `radius` is a Core Graphics blur radius in points (0 = sharp).
/// - `offset` is in points, positive `y` pushes the shadow down in
///   display coordinates (the renderer handles the Y-flip math
///   internally so callers don't need to reason about CG's Y-up
///   default coordinate system).
/// - `opacity` multiplies `color.opacity` for the final alpha, so
///   callers can keep `color` fully opaque and dial the intensity
///   via the opacity field like SwiftUI's `.shadow(color:…)` convention.
public struct ProfileInitialsShadow: Equatable, Hashable, Sendable, Codable {
    public var color: ProfileColor
    public var radius: CGFloat
    public var offset: CGSize
    public var opacity: Double

    public init(
        color: ProfileColor = .black,
        radius: CGFloat = 4,
        offset: CGSize = CGSize(width: 0, height: 2),
        opacity: Double = 0.35
    ) {
        self.color = color
        self.radius = radius
        self.offset = offset
        self.opacity = opacity
    }

    /// Subtle default shown when the user first taps "Add shadow" in
    /// the editor. Tuned to read on both light and dark backgrounds
    /// without looking like a mistake.
    public static let `default` = ProfileInitialsShadow()

    /// Final per-pixel alpha for the shadow, combining `color.opacity`
    /// with the separate `opacity` field. The renderer reads this to
    /// avoid multiplying the two factors inline at every draw call.
    public var resolvedOpacity: Double {
        color.opacity * opacity
    }
}
