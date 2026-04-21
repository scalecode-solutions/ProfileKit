import Foundation
import Testing
@testable import ProfileKit

struct ProfileInitialsBackgroundTests {
    @Test func allVariantsRoundTripThroughJSON() throws {
        let cases: [ProfileInitialsBackground] = [
            .solid(.white),
            .linearGradient(stops: [.white, .black], angleDegrees: 135),
            .linearGradient(
                stops: [
                    ProfileColor(red: 0.2, green: 0.5, blue: 0.9),
                    ProfileColor(red: 0.6, green: 0.1, blue: 0.3),
                    ProfileColor(red: 1.0, green: 0.9, blue: 0.2)
                ],
                angleDegrees: 270
            ),
            .radialGradient(stops: [.white, .black]),
            .deterministicPalette(.automatic),
            .deterministicPalette(.pastel),
        ]

        for value in cases {
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(ProfileInitialsBackground.self, from: encoded)
            #expect(decoded == value)
        }
    }

    @Test func usesDeterministicPaletteOnlyForPaletteCase() {
        #expect(ProfileInitialsBackground.deterministicPalette(.automatic).usesDeterministicPalette)
        #expect(ProfileInitialsBackground.deterministicPalette(.pastel).usesDeterministicPalette)
        #expect(!ProfileInitialsBackground.solid(.white).usesDeterministicPalette)
        #expect(!ProfileInitialsBackground.linearGradient(stops: [.white, .black], angleDegrees: 0)
            .usesDeterministicPalette)
    }

    @Test func paletteNameCoversFullCatalog() {
        // The palette expansion in step 17 registers colors for each
        // of these. Locking the set here makes the expansion a pure
        // implementation-side change.
        #expect(ProfileAvatarPaletteName.allCases.count == 6)
    }

    @Test func shadowDefaultResolvesOpacity() {
        let shadow = ProfileInitialsShadow.default
        // Black @ opacity 1, combined with shadow.opacity 0.35 -> 0.35.
        #expect(abs(shadow.resolvedOpacity - 0.35) < 0.0001)
    }

    @Test func shadowRoundTripsThroughJSON() throws {
        let shadow = ProfileInitialsShadow(
            color: ProfileColor(red: 0, green: 0, blue: 0, opacity: 0.5),
            radius: 8,
            offset: CGSize(width: 0, height: 3),
            opacity: 0.8
        )
        let encoded = try JSONEncoder().encode(shadow)
        let decoded = try JSONDecoder().decode(ProfileInitialsShadow.self, from: encoded)
        #expect(decoded == shadow)
    }
}
