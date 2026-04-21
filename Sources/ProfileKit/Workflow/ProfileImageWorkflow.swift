import Foundation

#if canImport(UIKit) && canImport(PhotosUI)
import PhotosUI
#endif

public enum ProfileImageWorkflowError: LocalizedError {
    case missingTransferableData

    public var errorDescription: String? {
        switch self {
        case .missingTransferableData:
            return "The selected photo could not be loaded."
        }
    }
}

public enum ProfileImageWorkflow {
    public static func makeDraft(
        from source: ProfileImageSource,
        identity: ProfileIdentity? = nil,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) throws -> ProfileImageDraft {
        let decoded = try ProfileImageDecoder.decode(source)
        let image = PlatformImageBridge.makeImage(from: decoded.cgImage)
        let viewport = ProfileImageViewport(
            sourcePixelSize: decoded.pixelSize,
            cropDimension: CGFloat(configuration.renderConfiguration.exportDimension),
            editorState: .init(),
            configuration: configuration
        )

        return ProfileImageDraft(
            image: image,
            pixelSize: decoded.pixelSize,
            contentType: decoded.contentType,
            identity: identity,
            editorState: viewport.recommendedInitialState()
        )
    }

    public static func export(
        draft: ProfileImageDraft,
        editorState: ProfileImageEditorState? = nil,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto
    ) throws -> ProfileImageEditResult {
        try ProfileImageRenderer.renderEditResult(
            from: .image(draft.image),
            editorState: editorState ?? draft.editorState,
            editorConfiguration: editorConfiguration,
            configuration: editorConfiguration.renderConfiguration
        )
    }
}

#if canImport(UIKit) && canImport(PhotosUI)
@available(iOS 16.0, macOS 13.0, *)
public extension ProfileImageWorkflow {
    static func makeDraft(
        from item: PhotosPickerItem,
        identity: ProfileIdentity? = nil,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) async throws -> ProfileImageDraft {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw ProfileImageWorkflowError.missingTransferableData
        }

        return try makeDraft(from: .data(data), identity: identity, configuration: configuration)
    }
}
#endif
