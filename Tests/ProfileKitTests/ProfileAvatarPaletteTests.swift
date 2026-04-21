import Foundation
import Testing
@testable import ProfileKit

struct ProfileAvatarPaletteTests {
    @Test func allPalettesReturnTwoStops() {
        for palette in ProfileAvatarPaletteName.allCases {
            let colors = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: palette)
            #expect(colors.count == 2, "Palette \(palette) returned \(colors.count) stops")
        }
    }

    @Test func samePaletteSameSeedIsDeterministic() {
        let first = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: .warm)
        let second = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: .warm)
        #expect(first == second)
    }

    @Test func differentSeedsDiffer() {
        let jamie = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: .vibrant)
        let shelby = ProfileAvatarPalette.colors(for: "Shelby B.", palette: .vibrant)
        #expect(jamie != shelby)
    }

    @Test func monoPaletteHasNoSaturation() {
        // Mono should have saturation == 0 -> R, G, B should be equal.
        let colors = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: .mono)
        for color in colors {
            let delta = abs(color.red - color.green) + abs(color.green - color.blue)
            #expect(delta < 0.01, "Mono color has chromaticity: \(color)")
        }
    }

    @Test func legacyAccessorMatchesAutomaticPalette() {
        // The SwiftUI-Color legacy accessor must match .automatic
        // element-by-element so InitialsAvatarView's non-style path
        // doesn't regress.
        let legacy = ProfileAvatarPalette.colors(for: "Jamie Doe")
        let automatic = ProfileAvatarPalette.colors(for: "Jamie Doe", palette: .automatic)
            .map { $0.color }

        // SwiftUI Color doesn't have reliable Equatable so compare via
        // their ProfileColor round-trip.
        #expect(legacy.count == automatic.count)
        for (a, b) in zip(legacy, automatic) {
            let pa = ProfileColor(a)
            let pb = ProfileColor(b)
            #expect(pa == pb)
        }
    }
}
