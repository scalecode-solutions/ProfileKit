import SwiftUI

/// Fully-wired initials editor screen — the initials-path analogue of
/// `ProfileImageEditorScreen`. Owns the `@State var style` internally
/// so hosts that just want a modal "design initials" experience don't
/// have to manage a binding themselves.
///
/// For hosts that want to observe or persist the style as the user
/// drives it, hold the style yourself and use `ProfileInitialsEditorView`
/// directly with your own `Binding`.
public struct ProfileInitialsEditorScreen: View {
    private let draft: ProfileInitialsDraft
    private let configuration: ProfileImageEditorConfiguration
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var style: ProfileInitialsStyle

    public init(
        draft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto,
        onCancel: @escaping () -> Void = {},
        onCommit: @escaping (Result<ProfileImageEditResult, Error>) -> Void
    ) {
        self.draft = draft
        self.configuration = configuration
        self.onCancel = onCancel
        self.onCommit = onCommit
        _style = State(initialValue: draft.style)
    }

    public var body: some View {
        ProfileInitialsEditorView(
            identity: draft.identity,
            style: $style,
            configuration: configuration,
            onCancel: onCancel,
            onCommit: onCommit
        )
    }
}
