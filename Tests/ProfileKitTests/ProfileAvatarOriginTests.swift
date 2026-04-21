import Foundation
import Testing
@testable import ProfileKit

struct ProfileAvatarOriginTests {
    @Test func photoOriginRoundTripsThroughJSON() throws {
        let origin = ProfileAvatarOrigin.photo(
            ProfileImageEditorState(
                zoom: 1.5,
                offset: CGSize(width: 0.1, height: -0.2),
                adjustments: ProfileImageAdjustmentState(
                    brightness: 0.1,
                    effect: .noir
                )
            )
        )

        let encoded = try JSONEncoder().encode(origin)
        let decoded = try JSONDecoder().decode(ProfileAvatarOrigin.self, from: encoded)
        #expect(decoded == origin)
    }

    @Test func initialsOriginRoundTripsThroughJSON() throws {
        let origin = ProfileAvatarOrigin.initials(
            identity: ProfileIdentity(displayName: "Jamie Doe"),
            style: ProfileInitialsStyle(
                glyph: "JD",
                background: .solid(ProfileColor(red: 0.3, green: 0.5, blue: 0.7)),
                fontWeight: .bold
            )
        )

        let encoded = try JSONEncoder().encode(origin)
        let decoded = try JSONDecoder().decode(ProfileAvatarOrigin.self, from: encoded)
        #expect(decoded == origin)
    }

    @Test func accessorsReturnNilForWrongVariant() {
        let photo = ProfileAvatarOrigin.photo(.init())
        #expect(photo.photoState != nil)
        #expect(photo.initialsStyle == nil)
        #expect(photo.initialsIdentity == nil)

        let initials = ProfileAvatarOrigin.initials(
            identity: ProfileIdentity(displayName: "X"),
            style: .default
        )
        #expect(initials.photoState == nil)
        #expect(initials.initialsStyle == .default)
        #expect(initials.initialsIdentity?.displayName == "X")
    }

    @Test func photoRendererPopulatesPhotoOrigin() throws {
        let cgImage = TestImageFactory.makeCGImage(width: 20, height: 20)
        let result = try ProfileImageRenderer.renderEditResult(
            from: .cgImage(cgImage),
            editorState: .init(),
            configuration: .init(exportDimension: 64, compressionQuality: 1, outputType: .png)
        )

        guard case .photo = result.origin else {
            Issue.record("Photo renderer produced non-photo origin: \(result.origin)")
            return
        }
    }

    @Test func initialsRendererPopulatesInitialsOrigin() throws {
        let draft = ProfileInitialsDraft(
            identity: ProfileIdentity(displayName: "Jamie")
        )
        let result = try ProfileInitialsRenderer.render(
            draft: draft,
            configuration: ProfileImageEditorConfiguration(
                renderConfiguration: .init(exportDimension: 64, compressionQuality: 1, outputType: .png)
            )
        )

        guard case .initials(let identity, _) = result.origin else {
            Issue.record("Initials renderer produced non-initials origin: \(result.origin)")
            return
        }
        #expect(identity.displayName == "Jamie")
    }
}
