import SwiftUI

public struct ProfileKitDemoView: View {
    @State private var draft: ProfileImageDraft = try! ProfileImageWorkflow.makeDraft(
        from: .image(ProfileKitDemoSamples.portraitSample()),
        identity: ProfileIdentity(displayName: "Taylor Example")
    )
    @State private var latestResult: ProfileImageEditResult?
    @State private var showingLandscape = false
    @State private var exportError: String?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                HStack(alignment: .top, spacing: 24) {
                    editorColumn
                    previewColumn
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ProfileKit Demo")
                .font(.largeTitle.weight(.bold))

            Text("A package-level example for crop, framing, fallback identity, and export.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(showingLandscape ? "Use Portrait Sample" : "Use Landscape Sample") {
                    swapSamples()
                }

                if let latestResult {
                    Text("Exported \(latestResult.data.count) bytes")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editor")
                .font(.title3.weight(.semibold))

            ProfileImageEditorScreen(
                draft: draft,
                onCancel: {},
                onCommit: handleCommit
            )
            .frame(maxWidth: 560)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.thinMaterial)
            )
        }
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.title3.weight(.semibold))

            Group {
                if let latestResult {
                    ProfileAvatarView(
                        image: latestResult.image,
                        identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                        configuration: .init(size: 120, shape: .circle, borderWidth: 2, borderColor: .white.opacity(0.5))
                    )
                } else {
                    ProfileAvatarView(
                        image: nil,
                        identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                        configuration: .init(size: 120, shape: .circle)
                    )
                }
            }

            HStack(spacing: 12) {
                ProfileAvatarView(
                    image: latestResult?.image,
                    identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                    configuration: .init(size: 72, shape: .circle)
                )

                ProfileAvatarView(
                    image: latestResult?.image,
                    identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                    configuration: .init(size: 56, shape: .roundedRect(cornerRadius: 18))
                )
            }

            if let exportError {
                Text(exportError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func handleCommit(_ result: Result<ProfileImageEditResult, Error>) {
        switch result {
        case .success(let value):
            latestResult = value
            exportError = nil
        case .failure(let error):
            exportError = error.localizedDescription
        }
    }

    private func swapSamples() {
        showingLandscape.toggle()
        let image = showingLandscape ? ProfileKitDemoSamples.landscapeSample() : ProfileKitDemoSamples.portraitSample()
        do {
            draft = try ProfileImageWorkflow.makeDraft(
                from: .image(image),
                identity: ProfileIdentity(displayName: "Taylor Example")
            )
            latestResult = nil
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}

#Preview("ProfileKit Demo") {
    ProfileKitDemoView()
}
