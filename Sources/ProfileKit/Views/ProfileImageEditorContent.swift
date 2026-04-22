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
    /// Core-Image-filtered version of `sourceImage` matching the
    /// currently selected effect, paired with the key that produced
    /// it. `displayImage` only returns the image when its key matches
    /// the current `effectPreviewKey` — which means during the brief
    /// render window between tapping a new preset and the detached
    /// filter completing, the canvas falls back to the raw source.
    /// Prevents a stale prior-preset preview from reading as the
    /// current selection when the user taps through effects quickly.
    @State private var effectPreviewImage: PKPlatformImage?
    @State private var effectPreviewKeyLanded: EffectPreviewKey?

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
                    if configuration.showsEffects {
                        effectsSection
                    }

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
        // Keep the canvas / preview-row image in sync with the current
        // effect preset. Keyed by both source identity and effect so
        // switching source images OR flipping presets both retrigger.
        // Detached filter pass keeps the main actor responsive while
        // the effect renders (same pattern as the effects strip's
        // per-tile thumbnailing).
        .task(id: effectPreviewKey) {
            await refreshEffectPreview()
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

        return Image(platformImage: displayImage)
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

    /// Image shown in the canvas + preview row. Returns the cached
    /// effect preview only when its key matches the current effect
    /// selection; otherwise falls back to the raw source. This means
    /// rapidly tapping through presets shows "source → filtered" per
    /// selection rather than "previous filter → current filter",
    /// which would briefly misrepresent the user's intent on each tap.
    private var displayImage: PKPlatformImage {
        guard
            let preview = effectPreviewImage,
            effectPreviewKeyLanded == effectPreviewKey
        else {
            return sourceImage
        }
        return preview
    }

    /// Section above the adjustment sliders: heading + horizontal
    /// film-strip of effect presets. The strip drives
    /// `editorState.adjustments.effect` directly so the renderer picks
    /// up the selection without any additional plumbing.
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(configuration.texts.effectsHeading)
                .font(.headline)
                .padding(.horizontal, 24)

            ProfileImageEffectsStrip(
                sourceImage: sourceImage,
                effect: $editorState.adjustments.effect,
                catalog: configuration.effectsCatalog,
                texts: configuration.texts
            )
        }
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

    // MARK: - Effect preview

    /// Composite key that drives the `.task(id:)` for the effect
    /// preview. Hashable struct (rather than stringified hashes) so
    /// `.task` gets type-safe equality and collisions are impossible.
    /// Embedding the full `ProfileImageEffect` — not just its
    /// `identifier` — means parameterized variants (e.g. two `.sepia`
    /// intensities) retrigger the render if the UI ever exposes a
    /// parameter slider.
    private struct EffectPreviewKey: Hashable {
        let sourceID: ObjectIdentifier
        let effect: ProfileImageEffect
    }

    private var effectPreviewKey: EffectPreviewKey {
        EffectPreviewKey(
            sourceID: ObjectIdentifier(sourceImage),
            effect: editorState.adjustments.effect
        )
    }

    /// Refresh `effectPreviewImage` for the current effect. Identity
    /// effects clear the cache (canvas shows raw `sourceImage`);
    /// otherwise the filter runs on a detached task and the result is
    /// published back on the main actor if the task hasn't been
    /// cancelled (which `.task(id:)` does automatically when the id
    /// changes mid-render).
    ///
    /// Cancellation note: `Task.detached` deliberately doesn't inherit
    /// the parent task's cancellation — switching this to a child
    /// `Task { }` would inherit MainActor isolation and run the filter
    /// on the main thread, defeating the offload. Rapid preset
    /// switching can therefore queue multiple concurrent background
    /// renders; their results land after the parent task is cancelled
    /// and are discarded via the `Task.isCancelled` check + the
    /// key-match gate on `displayImage`. Redundant CPU but no
    /// correctness issue.
    private func refreshEffectPreview() async {
        let currentKey = effectPreviewKey
        let effect = currentKey.effect

        if effect.isIdentity {
            effectPreviewImage = nil
            effectPreviewKeyLanded = currentKey
            return
        }

        let source = sourceImage
        let rendered = await Task.detached(priority: .userInitiated) {
            ProfileImageEditorContent.makeEffectPreview(source: source, effect: effect)
        }.value

        guard !Task.isCancelled else { return }
        effectPreviewImage = rendered
        effectPreviewKeyLanded = currentKey
    }

    /// Downsample + filter helper. Matches the rendering contract of
    /// `ProfileImageRenderer.adjustedCGImage` (same `EffectsPipeline`)
    /// so the canvas preview and the committed export can't drift.
    /// Downsamples to a 1024pt longest edge — enough detail for any
    /// typical canvas size, fast enough that a filter + encode round
    /// trip lands in a frame or two on real devices.
    nonisolated private static func makeEffectPreview(source: PKPlatformImage, effect: ProfileImageEffect) -> PKPlatformImage? {
        guard let cgSource = PlatformImageBridge.cgImage(from: source) else { return nil }

        let pixelSize = PlatformImageBridge.pixelSize(for: source)
        let longEdge = max(pixelSize.width, pixelSize.height)
        let maxDimension: CGFloat = 1024
        let scale = longEdge > maxDimension ? maxDimension / longEdge : 1.0
        let targetWidth = max(1, Int((pixelSize.width * scale).rounded()))
        let targetHeight = max(1, Int((pixelSize.height * scale).rounded()))

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(cgSource, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        guard let downsampled = context.makeImage() else { return nil }

        let ciImage = CIImage(cgImage: downsampled)
        let filtered = EffectsPipeline.apply(effect, to: ciImage)
        guard let filteredCG = previewCIContext.createCGImage(filtered, from: ciImage.extent) else {
            return nil
        }

        return PlatformImageBridge.makeImage(from: filteredCG)
    }

    /// Dedicated CIContext for the canvas preview. Separate from the
    /// effects-strip thumbnail context so concurrent renders (the
    /// canvas filter + a strip tile filter) don't serialize on the
    /// same CIContext. `nonisolated` because the View is MainActor-
    /// isolated but the preview render runs detached.
    nonisolated private static let previewCIContext = CIContext(options: nil)
}
