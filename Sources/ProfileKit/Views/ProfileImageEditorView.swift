import SwiftUI

/// Drop-in editor view: header (Cancel / Reset / Use Photo) + the
/// chromeless `ProfileImageEditorContent` primitive, with safe-area
/// handling suitable for modal presentation (`.sheet`,
/// `.fullScreenCover`, or `ProfileImageEditorScreen`).
///
/// When you need to compose the editor into your own chrome — e.g.
/// push onto a `NavigationStack` and wire Reset / Use Photo to
/// `ToolbarItem`s — reach for `ProfileImageEditorContent` directly
/// instead, and drive commit via
/// `ProfileImageRenderer.renderEditResultAsync(...)`.
public struct ProfileImageEditorView: View {
    private let sourceImage: PKPlatformImage
    @Binding private var editorState: ProfileImageEditorState
    private let configuration: ProfileImageEditorConfiguration
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var errorMessage: String?
    /// True while the async render is in-flight. Disables the confirm
    /// button and shows a progress indicator so the user knows their
    /// tap was received — large source images can take a few hundred
    /// ms to encode even on the background thread.
    @State private var isExporting = false

    public init(
        sourceImage: PKPlatformImage,
        editorState: Binding<ProfileImageEditorState>,
        configuration: ProfileImageEditorConfiguration = .profilePhoto,
        onCancel: @escaping () -> Void = {},
        onCommit: @escaping (Result<ProfileImageEditResult, Error>) -> Void
    ) {
        self.sourceImage = sourceImage
        _editorState = editorState
        self.configuration = configuration
        self.onCancel = onCancel
        self.onCommit = onCommit
    }

    public var body: some View {
        // GeometryReader + `.ignoresSafeArea()` wrapper: read the hardware
        // safe-area insets explicitly and apply them as padding. This
        // pattern is load-bearing — `.fullScreenCover` presents content
        // into a container that, in iOS 26, doesn't auto-inset a plain
        // VStack's children. `.safeAreaPadding(.top, 24)` inflates the
        // safe-area VALUE descendants can read but it doesn't physically
        // push a VStack's children, so the header was still riding under
        // the Dynamic Island / clock. Reading `proxy.safeAreaInsets`
        // sidesteps all of that. Consumers who embed the editor inside
        // a `NavigationStack` or other container that handles safe area
        // themselves should use `ProfileImageEditorContent` directly —
        // this safe-area ceremony is specific to the modal drop-in.
        GeometryReader { proxy in
            VStack(spacing: 20) {
                header
                    .padding(.horizontal, 24)

                ProfileImageEditorContent(
                    sourceImage: sourceImage,
                    editorState: $editorState,
                    configuration: configuration
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
            .padding(.top, proxy.safeAreaInsets.top + 24)
            .padding(.bottom, proxy.safeAreaInsets.bottom + 8)
            .padding(.leading, proxy.safeAreaInsets.leading)
            .padding(.trailing, proxy.safeAreaInsets.trailing)
            .frame(
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            .background(.background)
        }
        .ignoresSafeArea()
        .preferredColorScheme(configuration.appearance.preferredColorScheme)
    }

    private var header: some View {
        // Group the three header buttons inside a GlassEffectContainer
        // so adjacent glass surfaces share a sampling region — the
        // standard iOS 26 pattern for button clusters. Cancel + Reset
        // are secondary actions (.glass); Use Photo is the primary
        // action (.glassProminent).
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button(configuration.texts.cancelButton, action: onCancel)
                    .buttonStyle(.glass)

                Spacer()

                Button(configuration.texts.resetButton) {
                    errorMessage = nil
                    // Content observes the transition to identity and
                    // re-applies recommended initial state (portrait
                    // bias, initial zoom). No private state to poke.
                    editorState.reset()
                }
                .buttonStyle(.glass)

                Button {
                    commitEdits()
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Text(configuration.texts.confirmButton)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(isExporting)
            }
        }
    }

    private func commitEdits() {
        errorMessage = nil
        isExporting = true

        // Snapshot the state on the main actor so the async call
        // doesn't reach back into MainActor-isolated editor state
        // while the detached render is running.
        let snapshotState = editorState
        let snapshotConfig = configuration
        let snapshotSource = sourceImage

        Task { @MainActor in
            defer { isExporting = false }
            do {
                let result = try await ProfileImageRenderer.renderEditResultAsync(
                    from: .image(snapshotSource),
                    editorState: snapshotState,
                    editorConfiguration: snapshotConfig,
                    configuration: snapshotConfig.renderConfiguration
                )
                onCommit(.success(result))
            } catch {
                errorMessage = error.localizedDescription
                onCommit(.failure(error))
            }
        }
    }
}
