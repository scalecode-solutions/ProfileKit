import Foundation

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

// PhotosPickerItem integration moved to
// ProfileImageWorkflow+PhotosPicker.swift so the PhotosUI import lives
// in its own file — earlier compound canImport guards in-line here
// were evaluating inconsistently in Xcode's downstream SPM builds.
