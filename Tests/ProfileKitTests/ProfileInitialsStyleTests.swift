import Foundation
import Testing
@testable import ProfileKit

struct ProfileInitialsStyleTests {
    @Test func roundTripsThroughJSON() throws {
        let style = ProfileInitialsStyle(
            glyph: "AB",
            background: .linearGradient(stops: [.white, .black], angleDegrees: 90),
            foregroundColor: .white,
            fontDesign: .serif,
            fontWeight: .bold,
            fontScale: 0.5,
            letterSpacing: 1.5,
            verticalBias: -0.02,
            shadow: .default
        )

        let encoded = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(ProfileInitialsStyle.self, from: encoded)
        #expect(decoded == style)
    }

    @Test func defaultRoundTrips() throws {
        let style = ProfileInitialsStyle.default
        let encoded = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(ProfileInitialsStyle.self, from: encoded)
        #expect(decoded == style)
    }

    @Test func isDefaultReportsModified() {
        var style = ProfileInitialsStyle.default
        #expect(style.isDefault)

        style.fontWeight = .heavy
        #expect(!style.isDefault)
    }

    @Test func resolvedGlyphPrefersExplicitOverride() {
        let style = ProfileInitialsStyle(glyph: "TM")
        let identity = ProfileIdentity(displayName: "Something Else")
        #expect(style.resolvedGlyph(for: identity) == "TM")
    }

    @Test func resolvedGlyphFallsBackToIdentityWhenEmpty() {
        let identity = ProfileIdentity(displayName: "Jamie Doe")

        let nilGlyph = ProfileInitialsStyle(glyph: nil)
        #expect(nilGlyph.resolvedGlyph(for: identity) == "JD")

        let emptyGlyph = ProfileInitialsStyle(glyph: "")
        #expect(emptyGlyph.resolvedGlyph(for: identity) == "JD")

        let whitespaceGlyph = ProfileInitialsStyle(glyph: "   ")
        #expect(whitespaceGlyph.resolvedGlyph(for: identity) == "JD")
    }

    @Test func resolvedGlyphPreservesUserCase() {
        // User-typed glyphs pass through unchanged — supports CJK,
        // emoji, and deliberate lowercase monograms.
        let identity = ProfileIdentity(displayName: "Placeholder")
        let style = ProfileInitialsStyle(glyph: "ab")
        #expect(style.resolvedGlyph(for: identity) == "ab")
    }
}
