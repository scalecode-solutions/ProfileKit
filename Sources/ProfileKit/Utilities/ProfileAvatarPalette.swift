import SwiftUI

enum ProfileAvatarPalette {
    static func colors(for seed: String) -> [Color] {
        let value = Double(InitialsGenerator.deterministicValue(for: seed) % 360) / 360.0
        let secondary = (value + 0.12).truncatingRemainder(dividingBy: 1)

        return [
            Color(hue: value, saturation: 0.75, brightness: 0.92),
            Color(hue: secondary, saturation: 0.60, brightness: 0.70),
        ]
    }
}
