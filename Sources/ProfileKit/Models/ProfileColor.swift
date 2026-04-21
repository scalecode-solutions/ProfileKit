import CoreGraphics
import CoreImage
import SwiftUI

/// Codable RGBA color used throughout ProfileKit's persistable models
/// (initials styles, avatar configuration, effect parameters).
///
/// SwiftUI's `Color` isn't reliably `Equatable`, `Sendable`, or
/// `Codable` — it carries a resolver closure behind the scenes that
/// depends on the current environment. `ProfileColor` sidesteps that
/// by storing concrete RGBA components in extended sRGB, which is
/// what the renderer ultimately needs anyway (CGColor / CIColor). The
/// SwiftUI bridges go both ways so the editor UI can hand back a
/// `Color` from a `ColorPicker`, and the Core Graphics / Core Image
/// renderers get the component values directly without a round-trip
/// through the SwiftUI rendering pipeline.
///
/// Components are stored in the extended sRGB range — values outside
/// 0…1 are permitted (wide-gamut displays, P3 pickers) and passed
/// through to the renderer without clamping. Equality is exact on the
/// stored Doubles; two `ProfileColor`s round-tripped through JSON
/// compare equal because `Double` JSON encoding is lossless for the
/// values a `ColorPicker` produces.
public struct ProfileColor: Equatable, Hashable, Sendable, Codable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    // MARK: - Common constants

    public static let white = ProfileColor(red: 1, green: 1, blue: 1)
    public static let black = ProfileColor(red: 0, green: 0, blue: 0)
    public static let clear = ProfileColor(red: 0, green: 0, blue: 0, opacity: 0)

    /// Returns a copy with the opacity multiplied by `factor`. Mirrors
    /// `Color.opacity(_:)` so call-sites can write
    /// `ProfileColor.white.opacity(0.5)` without dropping into the
    /// full-component initializer.
    public func opacity(_ factor: Double) -> ProfileColor {
        ProfileColor(red: red, green: green, blue: blue, opacity: opacity * factor)
    }

    // MARK: - SwiftUI bridge

    /// Build a `ProfileColor` from a SwiftUI `Color`. Uses
    /// `Color.resolve(in:)` (iOS 17+/macOS 14+) to pull real RGBA
    /// components out of the color, evaluated against a default
    /// environment. This is the same approach SwiftUI itself uses when
    /// a `Color` needs to be rendered into a bitmap context.
    public init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.red = Double(resolved.red)
        self.green = Double(resolved.green)
        self.blue = Double(resolved.blue)
        self.opacity = Double(resolved.opacity)
    }

    /// Convert to a SwiftUI `Color`. Uses the extended sRGB color space
    /// so wide-gamut values round-trip correctly.
    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    // MARK: - Core Graphics / Core Image bridges

    /// CGColor in the extended sRGB color space. The renderer uses this
    /// directly with `CGContext.setFillColor` / `CGGradient`.
    public var cgColor: CGColor {
        CGColor(
            colorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB) ?? CGColorSpaceCreateDeviceRGB(),
            components: [CGFloat(red), CGFloat(green), CGFloat(blue), CGFloat(opacity)]
        ) ?? CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
    }

    /// CIColor for Core Image filter parameters (e.g. `CIColorMonochrome`
    /// tint). Core Image accepts extended-range components natively.
    public var ciColor: CIColor {
        CIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
    }
}
