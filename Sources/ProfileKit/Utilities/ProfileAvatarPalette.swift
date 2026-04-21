import SwiftUI

enum ProfileAvatarPalette {
    /// Legacy 2-hue gradient — kept for `InitialsAvatarView`'s current
    /// SwiftUI rendering path. Equivalent to
    /// `colors(for: seed, palette: .automatic)` on the `ProfileColor`
    /// return side; preserves the original `Color` return type so the
    /// existing view compiles without a cascade of edits.
    static func colors(for seed: String) -> [Color] {
        colors(for: seed, palette: .automatic).map { $0.color }
    }

    /// Palette-aware variant used by `ProfileInitialsRenderer`. Returns
    /// `ProfileColor` so the renderer can feed values directly into
    /// `CGGradient` without a SwiftUI round-trip.
    ///
    /// Step-14 shim: every palette name resolves to the historical
    /// two-hue automatic gradient. The full catalog expansion lands in
    /// step 17 — at which point this function differentiates by
    /// `paletteName` and the other cases produce distinct looks.
    static func colors(for seed: String, palette paletteName: ProfileAvatarPaletteName) -> [ProfileColor] {
        _ = paletteName // consumed in step 17
        let value = Double(InitialsGenerator.deterministicValue(for: seed) % 360) / 360.0
        let secondary = (value + 0.12).truncatingRemainder(dividingBy: 1)

        return [
            ProfileColor(Color(hue: value, saturation: 0.75, brightness: 0.92)),
            ProfileColor(Color(hue: secondary, saturation: 0.60, brightness: 0.70)),
        ]
    }
}
