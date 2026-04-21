import Foundation
import Testing
@testable import ProfileKit

struct ProfileImageEffectTests {
    @Test func roundTripsThroughJSON() throws {
        let cases: [ProfileImageEffect] = [
            .none, .mono, .noir, .tonal,
            .sepia(intensity: 0.6),
            .chrome, .fade, .instant, .process, .transfer,
            .comic,
        ]

        for effect in cases {
            let encoded = try JSONEncoder().encode(effect)
            let decoded = try JSONDecoder().decode(ProfileImageEffect.self, from: encoded)
            #expect(decoded == effect)
        }
    }

    @Test func defaultCatalogHasElevenEntries() {
        // Locked: 11 presets (including .none) in a fixed order.
        #expect(ProfileImageEffect.defaultCatalog.count == 11)
        #expect(ProfileImageEffect.defaultCatalog.first == ProfileImageEffect.none)
        #expect(ProfileImageEffect.defaultCatalog.last == ProfileImageEffect.comic)
    }

    @Test func identifierIsStableAcrossSepiaIntensities() {
        // Two sepia cases at different intensities share the same
        // identifier — matters for thumbnail-cache keys that group
        // "same effect kind, different tuning."
        #expect(ProfileImageEffect.sepia(intensity: 0.3).identifier
            == ProfileImageEffect.sepia(intensity: 0.9).identifier)
    }

    @Test func identityReportsNoOpCases() {
        #expect(ProfileImageEffect.none.isIdentity)
        #expect(ProfileImageEffect.sepia(intensity: 0).isIdentity)
        #expect(!ProfileImageEffect.sepia(intensity: 0.5).isIdentity)
        #expect(!ProfileImageEffect.noir.isIdentity)
    }
}
