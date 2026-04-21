import SwiftUI
import Testing
@testable import ProfileKit

struct ProfileImageEditorTextsTests {
    @Test func displayNameReturnsExactOverrideWhenPresent() {
        let texts = ProfileImageEditorTexts(
            effectDisplayNames: [.noir: "Film Noir"]
        )
        #expect(texts.displayName(for: .noir) == LocalizedStringKey("Film Noir"))
    }

    @Test func displayNameMatchesSepiaByIdentifierRegardlessOfIntensity() {
        // The default catalog registers .sepia(intensity: 0.8).
        // Looking up .sepia(intensity: 0.3) should hit the same label
        // because the identifier ignores the parameter.
        let texts = ProfileImageEditorTexts.default
        #expect(texts.displayName(for: .sepia(intensity: 0.3)) == LocalizedStringKey("Sepia"))
    }

    @Test func displayNameFallsBackToCapitalizedIdentifier() {
        // An empty override map forces the fallback path.
        let texts = ProfileImageEditorTexts(effectDisplayNames: [:])
        #expect(texts.displayName(for: .noir) == LocalizedStringKey("Noir"))
        #expect(texts.displayName(for: .sepia(intensity: 0.8)) == LocalizedStringKey("Sepia"))
    }

    @Test func defaultsHaveLabelsForWholeCatalog() {
        let texts = ProfileImageEditorTexts.default
        for effect in ProfileImageEffect.defaultCatalog {
            // Fallback returns the capitalized identifier, but we want
            // to assert the DEFAULT ships explicit labels — so either
            // the dictionary contains the exact case, or it contains a
            // sibling case with the same identifier (for parameterized
            // cases).
            let hasExact = texts.effectDisplayNames[effect] != nil
            let hasSibling = texts.effectDisplayNames.contains { key, _ in
                key.identifier == effect.identifier
            }
            #expect(hasExact || hasSibling, "Missing default label for \(effect.identifier)")
        }
    }
}
