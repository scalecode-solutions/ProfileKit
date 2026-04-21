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
        VStack(spacing: 20) {
            header

            GeometryReader { proxy in
                editorCanvas(in: proxy.size)
            }
            .aspectRatio(1, contentMode: .fit)

            transformToolbar

            if configuration.showsLivePreview {
                previewRow
            }

            if configuration.showsAdjustmentControls {
                adjustmentControls
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .background(.background)
        .onAppear {
            applyRecommendedInitialStateIfNeeded()
        }
    }

    /// Coarse transform controls: rotate 90° left, rotate 90° right,
    /// flip horizontally. These are always available — they're the
    /// Apple Photos-style "this is obviously broken, fix the
    /// orientation" affordances that users reach for first.
    private var transformToolbar: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    editorState.adjustments.quantizedRotationDegrees -= 90
                }
            } label: {
                Image(systemName: "rotate.left")
                    .font(.title3)
            }
            .accessibilityLabel(configuration.texts.rotateLeftLabel)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    editorState.adjustments.quantizedRotationDegrees += 90
                }
            } label: {
                Image(systemName: "rotate.right")
                    .font(.title3)
            }
            .accessibilityLabel(configuration.texts.rotateRightLabel)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    editorState.adjustments.flippedHorizontally.toggle()
                }
            } label: {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.title3)
            }
            .accessibilityLabel(configuration.texts.flipHorizontalLabel)

            Spacer()
        }
    }

    private var header: some View {
        HStack {
            Button(configuration.texts.cancelButton, action: onCancel)

            Spacer()

            Button(configuration.texts.resetButton) {
                errorMessage = nil
                editorState.reset()
                didApplyRecommendedInitialState = false
                applyRecommendedInitialStateIfNeeded(force: true)
            }

            Button(configuration.texts.confirmButton) {
                commitEdits()
            }
            .buttonStyle(.borderedProminent)
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

            VStack {
                Spacer()
                Text(configuration.texts.interactionInstructions)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.bottom, 16)
            }
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
        do {
            errorMessage = nil
            let result = try ProfileImageRenderer.renderEditResult(
                from: .image(sourceImage),
                editorState: editorState,
                editorConfiguration: configuration,
                configuration: configuration.renderConfiguration
            )
            onCommit(.success(result))
        } catch {
            errorMessage = error.localizedDescription
            onCommit(.failure(error))
        }
    }
}
