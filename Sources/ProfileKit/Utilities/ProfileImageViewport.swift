import CoreGraphics

struct ProfileImageViewport {
    let sourcePixelSize: CGSize
    let cropDimension: CGFloat
    let editorState: ProfileImageEditorState
    let configuration: ProfileImageEditorConfiguration

    init(
        sourcePixelSize: CGSize,
        cropDimension: CGFloat,
        editorState: ProfileImageEditorState,
        configuration: ProfileImageEditorConfiguration
    ) {
        self.sourcePixelSize = sourcePixelSize
        self.cropDimension = cropDimension
        self.editorState = editorState
        self.configuration = configuration
    }

    var imageAspectRatio: CGFloat {
        max(sourcePixelSize.width, 1) / max(sourcePixelSize.height, 1)
    }

    var baseDisplaySize: CGSize {
        if imageAspectRatio >= 1 {
            return CGSize(width: cropDimension * imageAspectRatio, height: cropDimension)
        } else {
            return CGSize(width: cropDimension, height: cropDimension / imageAspectRatio)
        }
    }

    var scaledDisplaySize: CGSize {
        CGSize(
            width: baseDisplaySize.width * effectiveZoom,
            height: baseDisplaySize.height * effectiveZoom
        )
    }

    var effectiveZoom: CGFloat {
        min(max(editorState.zoom, configuration.minimumZoom), configuration.maximumZoom)
    }

    var rotationRadians: CGFloat {
        configuration.allowsRotation
            ? (CGFloat(editorState.adjustments.rotationDegrees) * .pi / 180)
            : 0
    }

    var rotatedBoundingSize: CGSize {
        let width = scaledDisplaySize.width
        let height = scaledDisplaySize.height
        let radians = rotationRadians

        return CGSize(
            width: abs(width * cos(radians)) + abs(height * sin(radians)),
            height: abs(width * sin(radians)) + abs(height * cos(radians))
        )
    }

    var maxOffsetPoints: CGSize {
        CGSize(
            width: max(0, (rotatedBoundingSize.width - cropDimension) / 2),
            height: max(0, (rotatedBoundingSize.height - cropDimension) / 2)
        )
    }

    func normalizedOffset(from pointOffset: CGSize) -> CGSize {
        guard cropDimension > 0 else { return .zero }
        return CGSize(
            width: pointOffset.width / (cropDimension / 2),
            height: pointOffset.height / (cropDimension / 2)
        )
    }

    func pointOffset(from normalizedOffset: CGSize) -> CGSize {
        CGSize(
            width: normalizedOffset.width * cropDimension / 2,
            height: normalizedOffset.height * cropDimension / 2
        )
    }

    func clampedNormalizedOffset(_ proposal: CGSize) -> CGSize {
        let maxOffset = maxOffsetPoints

        let normalizedX = maxOffset.width == 0
            ? 0
            : min(max(proposal.width, -(maxOffset.width / (cropDimension / 2))), maxOffset.width / (cropDimension / 2))

        let normalizedY = maxOffset.height == 0
            ? 0
            : min(max(proposal.height, -(maxOffset.height / (cropDimension / 2))), maxOffset.height / (cropDimension / 2))

        return CGSize(width: normalizedX, height: normalizedY)
    }

    func recommendedInitialState() -> ProfileImageEditorState {
        let portraitBias = sourcePixelSize.height > sourcePixelSize.width ? configuration.initialVerticalBias : 0
        var state = ProfileImageEditorState(
            zoom: min(max(configuration.initialZoom, configuration.minimumZoom), configuration.maximumZoom),
            offset: CGSize(width: 0, height: portraitBias),
            adjustments: .neutral
        )
        let viewport = ProfileImageViewport(
            sourcePixelSize: sourcePixelSize,
            cropDimension: cropDimension,
            editorState: state,
            configuration: configuration
        )
        state.offset = viewport.clampedNormalizedOffset(state.offset)
        return state
    }
}
