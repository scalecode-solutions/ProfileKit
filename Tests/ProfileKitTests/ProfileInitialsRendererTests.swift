import CoreGraphics
import Foundation
import Testing
@testable import ProfileKit

struct ProfileInitialsRendererTests {
    @Test func rendersConfiguredSize() throws {
        let draft = ProfileInitialsDraft(
            identity: ProfileIdentity(displayName: "Jamie Doe")
        )
        let config = ProfileImageEditorConfiguration(
            renderConfiguration: ProfileImageRenderConfiguration(
                exportDimension: 128,
                compressionQuality: 1,
                outputType: .png
            )
        )

        let result = try ProfileInitialsRenderer.render(draft: draft, configuration: config)

        let renderedSize = PlatformImageBridge.pixelSize(for: result.image)
        #expect(Int(renderedSize.width.rounded()) == 128)
        #expect(Int(renderedSize.height.rounded()) == 128)
        #expect(!result.data.isEmpty)
        #expect(result.contentType == .png)
    }

    @Test func circularExportUpgradesJPEGtoPNG() throws {
        // Same format-forcing rule as the photo renderer: .jpeg +
        // circular crop -> PNG because JPEG can't carry alpha.
        let draft = ProfileInitialsDraft(
            identity: ProfileIdentity(displayName: "Jamie Doe")
        )
        let config = ProfileImageEditorConfiguration(
            cropShape: .circle,
            renderConfiguration: ProfileImageRenderConfiguration(
                exportDimension: 96,
                compressionQuality: 0.9,
                outputType: .jpeg,
                cropImageCircular: true
            )
        )

        let result = try ProfileInitialsRenderer.render(draft: draft, configuration: config)
        #expect(result.contentType == .png)
    }

    @Test func differentBackgroundsProduceDifferentBytes() throws {
        let identity = ProfileIdentity(displayName: "Jamie Doe")

        let solid = try ProfileInitialsRenderer.render(
            draft: ProfileInitialsDraft(
                identity: identity,
                style: ProfileInitialsStyle(background: .solid(.black))
            ),
            configuration: ProfileImageEditorConfiguration(
                renderConfiguration: .init(
                    exportDimension: 128, compressionQuality: 1, outputType: .png
                )
            )
        )

        let gradient = try ProfileInitialsRenderer.render(
            draft: ProfileInitialsDraft(
                identity: identity,
                style: ProfileInitialsStyle(
                    background: .linearGradient(stops: [.white, .black], angleDegrees: 135)
                )
            ),
            configuration: ProfileImageEditorConfiguration(
                renderConfiguration: .init(
                    exportDimension: 128, compressionQuality: 1, outputType: .png
                )
            )
        )

        #expect(solid.data != gradient.data)
    }

    @Test func glyphOverrideWinsOverIdentity() throws {
        // Two renders with the same identity but different glyph
        // overrides must differ — proves resolvedGlyph() is actually
        // consulted by the renderer.
        let identity = ProfileIdentity(displayName: "Jamie Doe")

        let base = try ProfileInitialsRenderer.render(
            draft: ProfileInitialsDraft(
                identity: identity,
                style: ProfileInitialsStyle(glyph: nil)
            ),
            configuration: ProfileImageEditorConfiguration(
                renderConfiguration: .init(
                    exportDimension: 128, compressionQuality: 1, outputType: .png
                )
            )
        )

        let overridden = try ProfileInitialsRenderer.render(
            draft: ProfileInitialsDraft(
                identity: identity,
                style: ProfileInitialsStyle(glyph: "XYZ")
            ),
            configuration: ProfileImageEditorConfiguration(
                renderConfiguration: .init(
                    exportDimension: 128, compressionQuality: 1, outputType: .png
                )
            )
        )

        #expect(base.data != overridden.data)
    }
}
