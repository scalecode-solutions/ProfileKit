import SwiftUI

/// Unified editor that lets the user switch between the photo path
/// and the designed-initials path in a single modal surface.
///
/// Segmented control at the top picks the active tab. Each tab owns
/// its own internal state (photo editor state; initials style) so
/// switching preserves in-progress work. Committing from either tab
/// produces the same `ProfileImageEditResult` via a single `onCommit`
/// callback — host code reacts identically regardless of which tab
/// fired the commit.
///
/// Hosts that only need one path should present
/// `ProfileImageEditorScreen` or `ProfileInitialsEditorScreen`
/// directly — the unified editor is for apps offering both.
public struct ProfileAvatarEditor: View {
    public enum Source {
        case photo
        case initials
    }

    private let photoDraft: ProfileImageDraft?
    private let initialsDraft: ProfileInitialsDraft
    private let configuration: ProfileImageEditorConfiguration
    private let texts: UnifiedTexts
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var source: Source
    @State private var photoState: ProfileImageEditorState
    @State private var initialsStyle: ProfileInitialsStyle

    public init(
        initialSource: Source = .initials,
        photoDraft: ProfileImageDraft? = nil,
        initialsDraft: ProfileInitialsDraft,
        configuration: ProfileImageEditorConfiguration = .profilePhoto,
        texts: UnifiedTexts = .default,
        onCancel: @escaping () -> Void = {},
        onCommit: @escaping (Result<ProfileImageEditResult, Error>) -> Void
    ) {
        self.photoDraft = photoDraft
        self.initialsDraft = initialsDraft
        self.configuration = configuration
        self.texts = texts
        self.onCancel = onCancel
        self.onCommit = onCommit

        // Start on photo if a photo draft is provided AND the caller
        // opted into `.photo`. Otherwise default to initials since
        // every caller has an identity but not necessarily an image.
        let resolvedInitial: Source = (photoDraft != nil && initialSource == .photo) ? .photo : .initials
        _source = State(initialValue: resolvedInitial)
        _photoState = State(initialValue: photoDraft?.editorState ?? .init())
        _initialsStyle = State(initialValue: initialsDraft.style)
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 16) {
                sourcePicker
                    .padding(.horizontal, 24)

                Group {
                    switch source {
                    case .photo:
                        if let photoDraft {
                            ProfileImageEditorView(
                                sourceImage: photoDraft.image,
                                editorState: $photoState,
                                configuration: configuration,
                                onCancel: onCancel,
                                onCommit: onCommit
                            )
                            .background(Color.clear)
                        } else {
                            photoUnavailableFallback
                        }
                    case .initials:
                        ProfileInitialsEditorView(
                            identity: initialsDraft.identity,
                            style: $initialsStyle,
                            configuration: configuration,
                            onCancel: onCancel,
                            onCommit: onCommit
                        )
                        .background(Color.clear)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, proxy.safeAreaInsets.top + 16)
            .padding(.bottom, proxy.safeAreaInsets.bottom)
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

    private var sourcePicker: some View {
        Picker("", selection: $source) {
            Text(texts.photoTab).tag(Source.photo)
            Text(texts.initialsTab).tag(Source.initials)
        }
        .pickerStyle(.segmented)
        .disabled(photoDraft == nil && source == .initials)
    }

    private var photoUnavailableFallback: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(texts.photoUnavailable)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    /// Strings specific to the unified editor's tab picker. Kept in a
    /// dedicated struct (rather than piled onto ProfileImageEditorTexts)
    /// because these only appear in the unified editor — hosts using
    /// the individual editor screens shouldn't need to localize them.
    public struct UnifiedTexts: @unchecked Sendable {
        public var photoTab: LocalizedStringKey
        public var initialsTab: LocalizedStringKey
        public var photoUnavailable: LocalizedStringKey

        public init(
            photoTab: LocalizedStringKey = "Photo",
            initialsTab: LocalizedStringKey = "Initials",
            photoUnavailable: LocalizedStringKey = "No photo selected. Pick one from your library, then switch back here to edit."
        ) {
            self.photoTab = photoTab
            self.initialsTab = initialsTab
            self.photoUnavailable = photoUnavailable
        }

        public static let `default` = UnifiedTexts()
    }
}
