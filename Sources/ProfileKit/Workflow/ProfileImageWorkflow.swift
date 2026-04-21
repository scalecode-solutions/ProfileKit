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

    // MARK: - Initials path

    /// Builds a ready-to-edit initials draft. Intentionally thin — the
    /// style is value-type-defaulted and the identity already carries
    /// everything the renderer needs. Symmetry with `makeDraft(from:)`
    /// on the photo side keeps the two entry points looking alike to
    /// integrators.
    public static func makeInitialsDraft(
        identity: ProfileIdentity,
        style: ProfileInitialsStyle = .default
    ) -> ProfileInitialsDraft {
        ProfileInitialsDraft(identity: identity, style: style)
    }

    /// Synchronously render an initials draft to a `ProfileImageEditResult`.
    /// Same output type as `export(draft:)` on the photo path so host
    /// code that uploads / persists the result doesn't need to know
    /// which source produced it.
    public static func export(
        initialsDraft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) throws -> ProfileImageEditResult {
        try ProfileInitialsRenderer.render(draft: initialsDraft, configuration: configuration)
    }

    /// Async variant — offloads the CGContext + Core Text pass to a
    /// detached cooperative task for large `exportDimension` values.
    public static func exportAsync(
        initialsDraft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) async throws -> ProfileImageEditResult {
        try await ProfileInitialsRenderer.renderAsync(
            draft: initialsDraft,
            configuration: configuration
        )
    }
}

// PhotosPickerItem integration moved to
// ProfileImageWorkflow+PhotosPicker.swift so the PhotosUI import lives
// in its own file — earlier compound canImport guards in-line here
// were evaluating inconsistently in Xcode's downstream SPM builds.
