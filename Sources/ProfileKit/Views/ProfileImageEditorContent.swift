import SwiftUI

/// Chromeless editor primitive — the canvas, transform toolbar, and
/// adjustment controls, without any Cancel / Reset / Use Photo
/// header. Intended for composition into a host-owned container
/// such as a `NavigationStack` with toolbar items, a split view, a
/// bottom sheet, or any custom chrome.
///
/// `ProfileImageEditorView` is the drop-in convenience on top of this
/// primitive — it renders a modal-ready header plus this content view.
/// Reach for `ProfileImageEditorContent` directly when you want to own
/// the surrounding chrome yourself (navigation toolbars, custom
/// confirm/dismiss flows, inline embeds).
///
/// State ownership contract:
/// - `editorState` is a binding. The host owns the underlying state,
///   so actions like "reset" are just `editorState.reset()` from the
///   call-site; this view listens for that transition to identity and
///   re-applies `ProfileImageViewport.recommendedInitialState()` so the
///   user gets the portrait-biased framing back.
/// - Committing is the host's job. Call
///   `ProfileImageRenderer.renderEditResultAsync(from:editorState:
///   editorConfiguration:configuration:)` with the current state +
///   source + configuration when your own "use photo" button fires.
///   This view does NOT render a confirm button, does NOT track an
///   `isExporting` state, and does NOT display commit errors — those
///   belong to whatever chrome wraps this.
public struct ProfileImageEditorContent: View {
    private let sourceImage: PKPlatformImage
    @Binding private var editorState: ProfileImageEditorState
    private let configuration: ProfileImageEditorConfiguration

    @State private var dragStartOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var zoomStart: CGFloat = 1
    @State private var isZooming = false
    @State private var didApplyRecommendedInitialState = false

    public init(
        sourceImage: PKPlatformImage,
        editorState: Binding<ProfileImageEditorState>,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) {
        self.sourceImage = sourceImage
        _editorState = editorState
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Canvas: either a fixed-dimension square (when the host
            // opts into a `.compact` / `.regular` / `.expanded` /
            // `.fixed(_:)` preset) or a fill-to-container 1:1 box.
            // Sliders and other adjustment controls stay flexible-
            // width in both cases — canvas sizing only affects the
            // crop area, per the API contract.
            if let fixedDimension = configuration.canvasSize.dimension {
                editorCanvas(in: CGSize(width: fixedDimension, height: fixedDimension))
                    .frame(width: fixedDimension, height: fixedDimension)
                    .frame(maxWidth: .infinity)
            } else {
                GeometryReader { proxy in
                    editorCanvas(in: proxy.size)
                }
                .aspectRatio(1, contentMode: .fit)
            }

            // Instruction text lives below the canvas rather than
            // overlaid inside it — keeps the photo unobscured and the
            // guidance readable regardless of crop content.
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
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            applyRecommendedInitialStateIfNeeded()
        }
        // Host-driven reset: when the binding flips back to identity
        // (typically because the host called `editorState.reset()`),
        // re-apply recommended initial state so the user lands on the
        // portrait-biased framing rather than a zero-zoom, zero-offset
        // raw view. Guarded by `didApplyRecommendedInitialState` reset
        // to avoid fighting ongoing edits.
        .onChange(of: editorState.isIdentity) { _, isIdentity in
            guard isIdentity else { return }
            didApplyRecommendedInitialState = false
            applyRecommendedInitialStateIfNeeded(force: true)
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
}
