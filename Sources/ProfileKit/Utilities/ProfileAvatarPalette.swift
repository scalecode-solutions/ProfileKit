import SwiftUI

enum ProfileAvatarPalette {
    /// Legacy 2-hue gradient — kept for `InitialsAvatarView`'s default
    /// path (no style). Equivalent to
    /// `colors(for: seed, palette: .automatic)` on the `ProfileColor`
    /// return side; preserves the `Color` return type so the existing
    /// view compiles without a cascade of edits.
    static func colors(for seed: String) -> [Color] {
        colors(for: seed, palette: .automatic).map { $0.color }
    }

    /// Palette-aware variant used by `ProfileInitialsRenderer` and by
    /// `InitialsAvatarView` when a `ProfileInitialsStyle` is present.
    ///
    /// Every palette is deterministic per-seed — the same display name
    /// always yields the same gradient in a given palette — but each
    /// palette expresses its own mood:
    /// - `.automatic`: today's two-hue gradient (saturated + darker
    ///   shifted-hue pair). Unchanged from the pre-expansion look.
    /// - `.mono`: single-hue per seed, saturation-free. Reads as
    ///   elegant grayscale-with-character.
    /// - `.warm`: orange → red → pink band. Seed controls position
    ///   within the warm slice; gradient is a 2-stop pair close in hue.
    /// - `.cool`: blue → teal → violet band. Same band-style selection
    ///   as `.warm`.
    /// - `.vibrant`: high-saturation, bright, wide-hue pairs — reads
    ///   loud and playful.
    /// - `.pastel`: low-saturation, high-brightness pairs — reads
    ///   soft and calm.
    static func colors(for seed: String, palette paletteName: ProfileAvatarPaletteName) -> [ProfileColor] {
        let seedValue = Double(InitialsGenerator.deterministicValue(for: seed) % 360) / 360.0

        switch paletteName {
        case .automatic:
            let secondary = (seedValue + 0.12).truncatingRemainder(dividingBy: 1)
            return [
                ProfileColor(Color(hue: seedValue, saturation: 0.75, brightness: 0.92)),
                ProfileColor(Color(hue: secondary, saturation: 0.60, brightness: 0.70)),
            ]

        case .mono:
            // Saturation 0, two brightnesses — a grayscale pair whose
            // darkness varies per seed so different identities still
            // feel distinct.
            let brightnessHi = 0.82 - (seedValue * 0.25)  // 0.57…0.82
            let brightnessLo = brightnessHi - 0.22
            return [
                ProfileColor(Color(hue: 0, saturation: 0, brightness: brightnessHi)),
                ProfileColor(Color(hue: 0, saturation: 0, brightness: brightnessLo)),
            ]

        case .warm:
            // Slice the warm band roughly 340°…40° (wraps through 0°).
            // Normalized seed maps into an 80° window.
            let hue = (0.944 + seedValue * 0.222).truncatingRemainder(dividingBy: 1) // 340°…56°
            let secondary = (hue + 0.05).truncatingRemainder(dividingBy: 1)
            return [
                ProfileColor(Color(hue: hue, saturation: 0.78, brightness: 0.96)),
                ProfileColor(Color(hue: secondary, saturation: 0.70, brightness: 0.78)),
            ]

        case .cool:
            // Cool band 170°…260° — teals through violets.
            let hue = 0.472 + seedValue * 0.250 // 170°…260°
            let secondary = (hue + 0.06).truncatingRemainder(dividingBy: 1)
            return [
                ProfileColor(Color(hue: hue, saturation: 0.72, brightness: 0.95)),
                ProfileColor(Color(hue: secondary, saturation: 0.65, brightness: 0.75)),
            ]

        case .vibrant:
            // Full-spectrum pair with wider hue separation (0.25 vs the
            // automatic palette's 0.12). High saturation, high
            // brightness — reads loud.
            let secondary = (seedValue + 0.25).truncatingRemainder(dividingBy: 1)
            return [
                ProfileColor(Color(hue: seedValue, saturation: 0.92, brightness: 1.0)),
                ProfileColor(Color(hue: secondary, saturation: 0.85, brightness: 0.90)),
            ]

        case .pastel:
            // Low saturation, very high brightness — soft.
            let secondary = (seedValue + 0.1).truncatingRemainder(dividingBy: 1)
            return [
                ProfileColor(Color(hue: seedValue, saturation: 0.40, brightness: 0.98)),
                ProfileColor(Color(hue: secondary, saturation: 0.32, brightness: 0.92)),
            ]
        }
    }
}
