import SwiftUI

/// Drop-in editor view for designed initials: header (Cancel / Reset
/// / Use Avatar) + the chromeless `ProfileInitialsEditorContent`
/// primitive, with safe-area handling suitable for modal presentation
/// (`.sheet`, `.fullScreenCover`, or `ProfileInitialsEditorScreen`).
///
/// Parallels `ProfileImageEditorView` on the photo path — identical
/// header layout and safe-area ceremony so the two editors feel like
/// siblings when a host swaps between them.
///
/// When you need to compose the editor into your own chrome, reach
/// for `ProfileInitialsEditorContent` directly and drive commit via
/// `ProfileImageWorkflow.exportAsync(initialsDraft:configuration:)`.
public struct ProfileInitialsEditorView: View {
    private let identity: ProfileIdentity
    @Binding private var style: ProfileInitialsStyle
    private let configuration: ProfileImageEditorConfiguration
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var errorMessage: String?
    @State private var isExporting = false

    public init(
        identity: ProfileIdentity,
        style: Binding<ProfileInitialsStyle>,
        configuration: ProfileImageEditorConfiguration = .profilePhoto,
        onCancel: @escaping () -> Void = {},
        onCommit: @escaping (Result<ProfileImageEditResult, Error>) -> Void
    ) {
        self.identity = identity
        _style = style
        self.configuration = configuration
        self.onCancel = onCancel
        self.onCommit = onCommit
    }

    public var body: some View {
        // GeometryReader + `.ignoresSafeArea()` wrapper mirrors the
        // photo editor — same reason: `.fullScreenCover` presents
        // content into a container that in iOS 26 doesn't auto-inset
        // a plain VStack's children. Reading `proxy.safeAreaInsets`
        // explicitly and applying them as padding works reliably
        // across `.sheet` and `.fullScreenCover`. Hosts that embed
        // inside a `NavigationStack` should reach for
        // `ProfileInitialsEditorContent` directly.
        GeometryReader { proxy in
            VStack(spacing: 20) {
                header
                    .padding(.horizontal, 24)

                ProfileInitialsEditorContent(
                    identity: identity,
                    style: $style,
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
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button(configuration.texts.cancelButton, action: onCancel)
                    .buttonStyle(.glass)

                Spacer()

                Button(configuration.texts.resetButton) {
                    errorMessage = nil
                    style = .default
                }
                .buttonStyle(.glass)

                Button {
                    commit()
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Text(configuration.texts.initialsConfirmButton)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(isExporting)
            }
        }
    }

    private func commit() {
        errorMessage = nil
        isExporting = true

        let snapshotDraft = ProfileInitialsDraft(identity: identity, style: style)
        let snapshotConfig = configuration

        Task { @MainActor in
            defer { isExporting = false }
            do {
                let result = try await ProfileImageWorkflow.exportAsync(
                    initialsDraft: snapshotDraft,
                    configuration: snapshotConfig
                )
                onCommit(.success(result))
            } catch {
                errorMessage = error.localizedDescription
                onCommit(.failure(error))
            }
        }
    }
}
