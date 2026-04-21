import Foundation
import Testing
@testable import ProfileKit

struct ProfileInitialsDraftTests {
    @Test func roundTripsThroughJSON() throws {
        let draft = ProfileInitialsDraft(
            identity: ProfileIdentity(displayName: "Jamie Doe", fallbackSeed: "jamie-42"),
            style: ProfileInitialsStyle(
                glyph: "JD",
                background: .solid(ProfileColor(red: 0.3, green: 0.1, blue: 0.8)),
                fontWeight: .bold
            )
        )

        let encoded = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(ProfileInitialsDraft.self, from: encoded)

        #expect(decoded == draft)
    }

    @Test func defaultStyleDraftReproducesIdentityInitials() {
        let identity = ProfileIdentity(displayName: "Jamie Doe")
        let draft = ProfileInitialsDraft(identity: identity)

        #expect(draft.style.resolvedGlyph(for: draft.identity) == "JD")
    }
}
