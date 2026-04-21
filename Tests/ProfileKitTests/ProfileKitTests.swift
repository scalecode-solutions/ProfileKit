import CoreGraphics
import Testing
@testable import ProfileKit

struct ProfileKitTests {
    @Test func initialsGenerationPrefersFirstAndLastWord() {
        #expect(InitialsGenerator.initials(from: "John Doe") == "JD")
        #expect(InitialsGenerator.initials(from: "Mary Jane Watson") == "MW")
    }

    @Test func initialsGenerationFallsBackSafely() {
        #expect(InitialsGenerator.initials(from: "Plato") == "P")
        #expect(InitialsGenerator.initials(from: "   ") == "?")
        #expect(InitialsGenerator.initials(from: nil) == "?")
    }

    @Test func decoderReadsPNGData() throws {
        let data = try TestImageFactory.makePNGData(width: 22, height: 14)
        let decoded = try ProfileImageDecoder.decode(.data(data))

        #expect(decoded.pixelSize.width == 22)
        #expect(decoded.pixelSize.height == 14)
        #expect(decoded.contentType == .png)
    }

    @Test func rendererExportsConfiguredSize() throws {
        let cgImage = TestImageFactory.makeCGImage(width: 40, height: 20)
        let result = try ProfileImageRenderer.renderEditResult(
            from: .cgImage(cgImage),
            editorState: .init(zoom: 1.2, offset: CGSize(width: 0.1, height: -0.1)),
            configuration: .init(exportDimension: 128, compressionQuality: 0.85, outputType: .jpeg)
        )

        let renderedSize = PlatformImageBridge.pixelSize(for: result.image)
        #expect(Int(renderedSize.width.rounded()) == 128)
        #expect(Int(renderedSize.height.rounded()) == 128)
        #expect(!result.data.isEmpty)
        #expect(result.contentType == .jpeg)
    }

    @Test func portraitRecommendedStateBiasesUpward() {
        let configuration = ProfileImageEditorConfiguration.profilePhoto
        let viewport = ProfileImageViewport(
            sourcePixelSize: CGSize(width: 1000, height: 1600),
            cropDimension: 300,
            editorState: .init(),
            configuration: configuration
        )

        let state = viewport.recommendedInitialState()
        #expect(state.zoom >= configuration.minimumZoom)
        #expect(state.offset.height < 0)
    }

    @Test func workflowBuildsDraftWithRecommendedState() throws {
        let data = try TestImageFactory.makePNGData(width: 300, height: 500)
        let draft = try ProfileImageWorkflow.makeDraft(
            from: .data(data),
            identity: ProfileIdentity(displayName: "Jamie Doe")
        )

        #expect(draft.contentType == .png)
        #expect(draft.identity?.initials == "JD")
        #expect(draft.editorState.zoom >= ProfileImageEditorConfiguration.profilePhoto.minimumZoom)
    }

    @Test func workflowExportsFromDraft() throws {
        let data = try TestImageFactory.makePNGData(width: 400, height: 400)
        let draft = try ProfileImageWorkflow.makeDraft(from: .data(data))
        let result = try ProfileImageWorkflow.export(draft: draft)

        #expect(!result.data.isEmpty)
        #expect(result.contentType == .jpeg)
    }
}
