import SwiftUI

public struct ProfileImageEditorView: View {
    private let sourceImage: PKPlatformImage
    @Binding private var editorState: ProfileImageEditorState
    private let configuration: ProfileImageEditorConfiguration
    private let onCancel: () -> Void
    private let onCommit: (Result<ProfileImageEditResult, Error>) -> Void

    @State private var errorMessage: String?
    @State private var dragStartOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var zoomStart: CGFloat = 1
    @State private var isZooming = false
    @State private var didApplyRecommendedInitialState = false
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
        // Split layout: image area pinned at top, adjustments scroll.
        //
        // Top (pinned): header buttons, canvas, instructions, transform
        // toolbar. These are the "framing" controls — the user needs
        // constant visibility of the image while they crop/rotate/flip.
        //
        // Bottom (scrollable): preview chip, brightness/contrast/
        // saturation/rotation sliders, error. These are the "tuning"
        // controls that can safely live below the fold and scroll up
        // under the user's thumb when they need them.
        //
        // Chrome gets the 24pt horizontal inset per-element; the canvas
        // itself goes edge-to-edge so the gesture surface is as large
        // as possible. Moving the sliders into a ScrollView means the
        // top VStack only needs to fit header + canvas + instructions
        // + toolbar, so the canvas's .aspectRatio(1,.fit) now has
        // enough vertical budget to resolve against the full width.
        // GeometryReader + `.ignoresSafeArea()` wrapper: read the hardware
        // safe-area insets explicitly and apply them as padding. This
        // pattern is load-bearing — `.fullScreenCover` presents content
        // into a container that, in iOS 26, doesn't auto-inset a plain
        // VStack's children. `.safeAreaPadding(.top, 24)` inflates the
        // safe-area VALUE descendants can read but it doesn't physically
        // push a VStack's children, so the header was still riding under
        // the Dynamic Island / clock. Reading `proxy.safeAreaInsets`
        // sidesteps all of that.
        GeometryReader { proxy in
            VStack(spacing: 20) {
                header
                    .padding(.horizontal, 24)

                GeometryReader { canvasProxy in
                    editorCanvas(in: canvasProxy.size)
                }
                .aspectRatio(1, contentMode: .fit)

                // Instruction text lives below the canvas rather than
                // overlaid inside it — keeps the photo unobscured and
                // the guidance readable regardless of crop content.
                Text(configuration.texts.interactionInstructions)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                transformToolbar
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 20) {
                        if configuration.showsLivePreview {
                            previewRow
                                .padding(.horizontal, 24)
                        }

                        if configuration.showsAdjustmentControls {
                            adjustmentControls
                                .padding(.horizontal, 24)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
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
        .onAppear {
            applyRecommendedInitialStateIfNeeded()
        }
    }

    /// Coarse transform controls: rotate 90° left, rotate 90° right,
    /// flip horizontally. These are always available — they're the
    /// Apple Photos-style "this is obviously broken, fix the
    /// orientation" affordances that users reach for first.
    private var transformToolbar: some View {
        // Circular glass buttons for the coarse transform actions.
        // Centered in the row rather than pushed left — visually reads
        // as a balanced cluster rather than a left-aligned toolbar.
        // The flipped state uses glassProminent so the user can see at
        // a glance that horizontal flip is engaged.
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        editorState.adjustments.quantizedRotationDegrees -= 90
                    }
                } label: {
                    Image(systemName: "rotate.left")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(configuration.texts.rotateLeftLabel)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        editorState.adjustments.quantizedRotationDegrees += 90
                    }
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(configuration.texts.rotateRightLabel)

                if editorState.adjustments.flippedHorizontally {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            editorState.adjustments.flippedHorizontally.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(.white)
                    .clipShape(Circle())
                    .accessibilityLabel(configuration.texts.flipHorizontalLabel)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            editorState.adjustments.flippedHorizontally.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(configuration.texts.flipHorizontalLabel)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
                    editorState.reset()
                    didApplyRecommendedInitialState = false
                    applyRecommendedInitialStateIfNeeded(force: true)
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

    private func editorCanvas(in size: CGSize) -> some View {
        let cropSize = max(1, min(size.width, size.height) - (configuration.cropPadding * 2))

        return ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.black.opacity(0.92))

            editableImage(cropSize: cropSize)
                .frame(width: cropSize, height: cropSize)
                .clipShape(ProfileAvatarClipShape(shape: configuration.cropShape))
                .overlay(
                    ProfileAvatarClipShape(shape: configuration.cropShape)
                        .stroke(.white.opacity(0.9), lineWidth: 2)
                )
                // Rule-of-thirds grid overlay, only during active cropping
                // — never rendered into the exported image. Drawn on top
                // of the clipped crop surface so it's bounded to the
                // visible framing area.
                .overlay {
                    if configuration.showsGridOverlay {
                        GridOfThirdsOverlay()
                            .frame(width: cropSize, height: cropSize)
                            .clipShape(ProfileAvatarClipShape(shape: configuration.cropShape))
                            .allowsHitTesting(false)
                    }
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(cropSize: cropSize))
                .simultaneousGesture(magnificationGesture(cropSize: cropSize))
                .simultaneousGesture(doubleTapGesture(cropSize: cropSize))
        }
        .onAppear {
            applyRecommendedInitialStateIfNeeded(availableSize: size)
        }
    }

    private func editableImage(cropSize: CGFloat) -> some View {
        let viewport = makeViewport(cropSize: cropSize)
        let pointOffset = viewport.pointOffset(from: viewport.clampedNormalizedOffset(editorState.offset))
        // Visual-rotation contract matches the renderer's contract:
        // fine slider rotation is gated by `allowsRotation`, quantized
        // (90° button) rotation is always honored.
        let displayRotation: Double = {
            if configuration.allowsRotation {
                return editorState.adjustments.effectiveRotationDegrees
            } else {
                return editorState.adjustments.quantizedRotationDegrees
            }
        }()
        // Horizontal flip lives on the editable image, NOT on the
        // container — this keeps gesture hit-testing on the un-flipped
        // local coordinate space so drag-right always moves the image
        // right, regardless of flip state.
        let flipScale: CGFloat = editorState.adjustments.flippedHorizontally ? -1 : 1

        return Image(platformImage: sourceImage)
            .resizable()
            .frame(width: viewport.baseDisplaySize.width, height: viewport.baseDisplaySize.height)
            .brightness(editorState.adjustments.brightness)
            .contrast(editorState.adjustments.contrast)
            .saturation(editorState.adjustments.saturation)
            .scaleEffect(x: flipScale, y: 1)
            .scaleEffect(viewport.effectiveZoom)
            .rotationEffect(.degrees(displayRotation))
            .offset(x: pointOffset.width, y: pointOffset.height)
    }

    private var previewRow: some View {
        HStack(spacing: 16) {
            Text(configuration.texts.previewHeading)
                .font(.headline)

            Spacer()

            editableImage(cropSize: 72)
                .frame(width: 72, height: 72)
                .clipShape(ProfileAvatarClipShape(shape: configuration.cropShape))
                .overlay(
                    ProfileAvatarClipShape(shape: configuration.cropShape)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                )
        }
    }

    private var adjustmentControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(configuration.texts.adjustmentsHeading)
                .font(.headline)

            sliderRow(title: configuration.texts.brightnessLabel, value: $editorState.adjustments.brightness, range: -0.4...0.4)
            sliderRow(title: configuration.texts.contrastLabel, value: $editorState.adjustments.contrast, range: 0.7...1.6)
            sliderRow(title: configuration.texts.saturationLabel, value: $editorState.adjustments.saturation, range: 0...1.8)
            if configuration.allowsRotation {
                sliderRow(title: configuration.texts.rotationLabel, value: $editorState.adjustments.rotationDegrees, range: -45...45)
            }
        }
    }

    private func sliderRow(
        title: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private func dragGesture(cropSize: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    dragStartOffset = editorState.offset
                    isDragging = true
                }

                let proposal = CGSize(
                    width: dragStartOffset.width + (value.translation.width / (cropSize / 2)),
                    height: dragStartOffset.height + (value.translation.height / (cropSize / 2))
                )

                editorState.offset = makeViewport(cropSize: cropSize).clampedNormalizedOffset(proposal)
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    private func magnificationGesture(cropSize: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if !isZooming {
                    zoomStart = editorState.zoom
                    isZooming = true
                }

                editorState.zoom = min(
                    max(zoomStart * value, configuration.minimumZoom),
                    configuration.maximumZoom
                )
                editorState.offset = makeViewport(cropSize: cropSize).clampedNormalizedOffset(editorState.offset)
            }
            .onEnded { _ in
                isZooming = false
            }
    }

    private func doubleTapGesture(cropSize: CGFloat) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                let targetZoom: CGFloat
                if editorState.zoom > 1.01 {
                    targetZoom = configuration.minimumZoom
                } else {
                    targetZoom = min(max(configuration.doubleTapZoomFactor, configuration.minimumZoom), configuration.maximumZoom)
                }

                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    editorState.zoom = targetZoom
                    editorState.offset = makeViewport(cropSize: cropSize).clampedNormalizedOffset(editorState.offset)
                }
            }
    }

    private func makeViewport(cropSize: CGFloat) -> ProfileImageViewport {
        ProfileImageViewport(
            sourcePixelSize: PlatformImageBridge.pixelSize(for: sourceImage),
            cropDimension: cropSize,
            editorState: editorState,
            configuration: configuration
        )
    }

    private func applyRecommendedInitialStateIfNeeded(force: Bool = false) {
        guard force || (!didApplyRecommendedInitialState && editorState.isIdentity) else { return }
        applyRecommendedInitialStateIfNeeded(
            force: force,
            cropSize: CGFloat(configuration.renderConfiguration.exportDimension)
        )
    }

    private func applyRecommendedInitialStateIfNeeded(force: Bool = false, availableSize: CGSize) {
        let cropSize = max(1, min(availableSize.width, availableSize.height) - (configuration.cropPadding * 2))
        applyRecommendedInitialStateIfNeeded(force: force, cropSize: cropSize)
    }

    private func applyRecommendedInitialStateIfNeeded(force: Bool, cropSize: CGFloat) {
        guard force || (!didApplyRecommendedInitialState && editorState.isIdentity) else { return }
        let viewport = makeViewport(cropSize: cropSize)
        editorState = viewport.recommendedInitialState()
        didApplyRecommendedInitialState = true
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
