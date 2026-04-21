import Foundation
import SwiftUI
import Testing
@testable import ProfileKit

struct ProfileColorTests {
    @Test func roundTripsThroughJSON() throws {
        let original = ProfileColor(red: 0.2, green: 0.5, blue: 0.9, opacity: 0.75)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProfileColor.self, from: encoded)

        #expect(decoded == original)
    }

    @Test func constantsHaveExpectedComponents() {
        #expect(ProfileColor.white == ProfileColor(red: 1, green: 1, blue: 1, opacity: 1))
        #expect(ProfileColor.black == ProfileColor(red: 0, green: 0, blue: 0, opacity: 1))
        #expect(ProfileColor.clear.opacity == 0)
    }

    @Test func colorBridgeRoundTripsConcreteValues() {
        // Round-tripping a Color built from concrete RGBA components
        // should preserve those components (within Float→Double
        // precision). This is the common case — user-picked colors
        // from a ColorPicker are always concrete.
        let source = Color(.sRGB, red: 0.3, green: 0.6, blue: 0.1, opacity: 0.8)
        let profileColor = ProfileColor(source)

        #expect(abs(profileColor.red - 0.3) < 0.001)
        #expect(abs(profileColor.green - 0.6) < 0.001)
        #expect(abs(profileColor.blue - 0.1) < 0.001)
        #expect(abs(profileColor.opacity - 0.8) < 0.001)
    }

    @Test func cgColorReflectsComponents() {
        let profileColor = ProfileColor(red: 0.25, green: 0.5, blue: 0.75, opacity: 0.5)
        let components = profileColor.cgColor.components ?? []

        #expect(components.count == 4)
        #expect(abs(components[0] - 0.25) < 0.001)
        #expect(abs(components[1] - 0.5) < 0.001)
        #expect(abs(components[2] - 0.75) < 0.001)
        #expect(abs(components[3] - 0.5) < 0.001)
    }
}
