import SwiftUI

public struct ProfileImageEditorScreen: View {
    private let draft: ProfileImageDraft
    private let configuration: ProfileImageEditorConfiguration
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var editorState: ProfileImageEditorState

    public init(
        draft: ProfileImageDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto,
        onCancel: @escaping () -> Void = {},
        onCommit: @escaping (Result<ProfileImageEditResult, Error>) -> Void
    ) {
        self.draft = draft
        self.configuration = configuration
        self.onCancel = onCancel
        self.onCommit = onCommit
        _editorState = State(initialValue: draft.editorState)
    }

    public var body: some View {
        ProfileImageEditorView(
            sourceImage: draft.image,
            editorState: $editorState,
            configuration: configuration,
            onCancel: onCancel,
            onCommit: onCommit
        )
    }
}
