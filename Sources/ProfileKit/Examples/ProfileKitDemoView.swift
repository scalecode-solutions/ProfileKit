import SwiftUI

public struct ProfileKitDemoView: View {
    @State private var draft: ProfileImageDraft = try! ProfileImageWorkflow.makeDraft(
        from: .image(ProfileKitDemoSamples.portraitSample()),
        identity: ProfileIdentity(displayName: "Taylor Example")
    )
    @State private var latestResult: ProfileImageEditResult?
    @State private var showingLandscape = false
    @State private var exportError: String?

    // Live-configurable knobs so the demo exercises every tier-1/tier-2
    // feature without requiring code edits.
    @State private var showsGridOverlay = true
    @State private var appearance: ProfileImageEditorAppearance = .system
    @State private var exportCircular = false
    @State private var initialsFontWeight: DemoFontWeight = .semibold

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                controlsPanel

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

            Text("Crop, rotate, flip, frame — then export. Toggle the knobs below to see each feature in action.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(showingLandscape ? "Use Portrait Sample" : "Use Landscape Sample") {
                    swapSamples()
                }

                if let latestResult {
                    Text("Exported \(latestResult.data.count) bytes · \(latestResult.contentType.preferredFilenameExtension?.uppercased() ?? "?")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Live knobs for grid, appearance, circular export, and initials
    /// font weight. The toggles flow directly into the editor config
    /// and the fallback-avatar configuration so the visual effect of
    /// each option is immediate.
    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editor knobs")
                .font(.headline)

            Toggle("Rule-of-thirds grid during crop", isOn: $showsGridOverlay)

            Picker("Appearance", selection: $appearance) {
                Text("System").tag(ProfileImageEditorAppearance.system)
                Text("Force Light").tag(ProfileImageEditorAppearance.forceLight)
                Text("Force Dark").tag(ProfileImageEditorAppearance.forceDark)
            }
            .pickerStyle(.segmented)

            Toggle("Export circular PNG (transparent corners)", isOn: $exportCircular)

            Picker("Initials font weight", selection: $initialsFontWeight) {
                ForEach(DemoFontWeight.allCases) { weight in
                    Text(weight.label).tag(weight)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var editorConfiguration: ProfileImageEditorConfiguration {
        ProfileImageEditorConfiguration(
            showsGridOverlay: showsGridOverlay,
            renderConfiguration: ProfileImageRenderConfiguration(
                cropImageCircular: exportCircular
            ),
            appearance: appearance
        )
    }

    private var avatarConfiguration: ProfileAvatarConfiguration {
        ProfileAvatarConfiguration(
            size: 120,
            shape: .circle,
            borderWidth: 2,
            borderColor: .white.opacity(0.5),
            fontWeight: initialsFontWeight.value
        )
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editor")
                .font(.title3.weight(.semibold))

            ProfileImageEditorScreen(
                draft: draft,
                configuration: editorConfiguration,
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

            // Big hero — exercises the current configuration. Uses the
            // latest export if present, else the fallback-initials path.
            ProfileAvatarView(
                image: latestResult?.image,
                identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                configuration: avatarConfiguration
            )

            // Size + shape variety row — shows how the same data looks
            // at different render sizes and in rounded-rect shape.
            HStack(spacing: 12) {
                ProfileAvatarView(
                    image: latestResult?.image,
                    identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                    configuration: .init(size: 72, shape: .circle, fontWeight: initialsFontWeight.value)
                )

                ProfileAvatarView(
                    image: latestResult?.image,
                    identity: draft.identity ?? ProfileIdentity(displayName: "Taylor Example"),
                    configuration: .init(size: 56, shape: .roundedRect(cornerRadius: 18), fontWeight: initialsFontWeight.value)
                )
            }

            // Deterministic-palette demo — three identities, no images,
            // so the initials-fallback gradient is visible per name.
            Text("Initials fallback (deterministic per name)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            HStack(spacing: 12) {
                ForEach(["Taylor Example", "Travis M.", "Shelby B."], id: \.self) { name in
                    VStack(spacing: 6) {
                        InitialsAvatarView(
                            identity: ProfileIdentity(displayName: name),
                            configuration: .init(size: 56, shape: .circle, fontWeight: initialsFontWeight.value)
                        )
                        Text(name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
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

/// Demo-side enum wrapping `Font.Weight` — SwiftUI's `Font.Weight`
/// isn't directly `Identifiable` / iterable, and this is only used to
/// drive the segmented picker in the demo view.
private enum DemoFontWeight: Int, CaseIterable, Identifiable {
    case regular, medium, semibold, bold, heavy

    var id: Int { rawValue }

    var value: Font.Weight {
        switch self {
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    var label: String {
        switch self {
        case .regular:  return "Regular"
        case .medium:   return "Medium"
        case .semibold: return "Semibold"
        case .bold:     return "Bold"
        case .heavy:    return "Heavy"
        }
    }
}

#Preview("ProfileKit Demo") {
    ProfileKitDemoView()
}
