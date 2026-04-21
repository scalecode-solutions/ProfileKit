import Foundation
import SwiftUI
import Testing
@testable import ProfileKit

struct ProfileFontTokenTests {
    @Test func weightRoundTripsThroughJSON() throws {
        for weight in ProfileFontWeight.allCases {
            let encoded = try JSONEncoder().encode(weight)
            let decoded = try JSONDecoder().decode(ProfileFontWeight.self, from: encoded)
            #expect(decoded == weight)
        }
    }

    @Test func designRoundTripsThroughJSON() throws {
        for design in ProfileFontDesign.allCases {
            let encoded = try JSONEncoder().encode(design)
            let decoded = try JSONDecoder().decode(ProfileFontDesign.self, from: encoded)
            #expect(decoded == design)
        }
    }

    @Test func weightBridgeIsReflexive() {
        // Every case's `.fontWeight` fed back into the init should
        // produce the same case. Skips nothing since we map every
        // SwiftUI case we recognize.
        for weight in ProfileFontWeight.allCases {
            let bridged = ProfileFontWeight(weight.fontWeight)
            #expect(bridged == weight)
        }
    }

    @Test func designBridgeIsReflexive() {
        for design in ProfileFontDesign.allCases {
            let bridged = ProfileFontDesign(design.fontDesign)
            #expect(bridged == design)
        }
    }
}
