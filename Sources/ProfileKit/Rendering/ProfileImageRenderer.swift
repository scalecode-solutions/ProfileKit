import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ProfileImageRenderingError: LocalizedError {
    case contextCreationFailed
    case exportFailed
    case adjustedImageCreationFailed

    public var errorDescription: String? {
        switch self {
        case .contextCreationFailed:
            return "ProfileKit could not create a rendering context."
        case .exportFailed:
            return "ProfileKit could not export the rendered image."
        case .adjustedImageCreationFailed:
            return "ProfileKit could not apply the selected image adjustments."
        }
    }
}

public enum ProfileImageRenderer {
    private static let ciContext = CIContext(options: nil)

    /// Async rendering path — offloads the CGContext draw + CoreImage
    /// filter + encoding to a detached cooperative task so a large
    /// source image doesn't stall the main thread when the user hits
    /// "Use Photo." The synchronous `renderEditResult` remains for
    /// callers that are already off-main or want immediate control;
    /// the SwiftUI editor uses this async variant via commitEdits.
    public static func renderEditResultAsync(
        from source: ProfileImageSource,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto,
        configuration: ProfileImageRenderConfiguration = .profilePhoto
    ) async throws -> ProfileImageEditResult {
        try await Task.detached(priority: .userInitiated) {
            try renderEditResult(
                from: source,
                editorState: editorState,
                editorConfiguration: editorConfiguration,
                configuration: configuration
            )
        }.value
    }

    public static func renderEditResult(
        from source: ProfileImageSource,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto,
        configuration: ProfileImageRenderConfiguration = .profilePhoto
    ) throws -> ProfileImageEditResult {
        // When circular export is requested with a circle crop, alpha
        // is required — force PNG regardless of the caller's outputType.
        // The final contentType returned reflects the actual encoding.
        let effectiveConfig = effectiveRenderConfiguration(
            configuration,
            cropShape: editorConfiguration.cropShape
        )

        let decoded = try ProfileImageDecoder.decode(source)
        let cgImage = try renderCGImage(
            from: decoded,
            editorState: editorState,
            editorConfiguration: editorConfiguration,
            renderConfiguration: effectiveConfig
        )
        let image = PlatformImageBridge.makeImage(from: cgImage)
        let data = try encodedData(from: cgImage, configuration: effectiveConfig)
        return ProfileImageEditResult(
            image: image,
            data: data,
            contentType: effectiveConfig.outputType,
            editorState: editorState
        )
    }

    /// Patches `outputType` to `.png` when the render config asks for
    /// a circular export with a circle crop. JPEG can't carry alpha;
    /// silently upgrading the format is kinder than failing the render.
    private static func effectiveRenderConfiguration(
        _ input: ProfileImageRenderConfiguration,
        cropShape: ProfileAvatarShape
    ) -> ProfileImageRenderConfiguration {
        guard input.cropImageCircular, cropShape == .circle, input.outputType != .png else {
            return input
        }

        var patched = input
        patched.outputType = .png
        return patched
    }

    public static func renderAvatar(
        from source: ProfileImageSource,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto,
        configuration: ProfileImageRenderConfiguration = .profilePhoto
    ) throws -> PKPlatformImage {
        let decoded = try ProfileImageDecoder.decode(source)
        let cgImage = try renderCGImage(
            from: decoded,
            editorState: editorState,
            editorConfiguration: editorConfiguration,
            renderConfiguration: configuration
        )
        return PlatformImageBridge.makeImage(from: cgImage)
    }

    public static func renderAvatarData(
        from source: ProfileImageSource,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto,
        configuration: ProfileImageRenderConfiguration = .profilePhoto
    ) throws -> Data {
        let decoded = try ProfileImageDecoder.decode(source)
        let cgImage = try renderCGImage(
            from: decoded,
            editorState: editorState,
            editorConfiguration: editorConfiguration,
            renderConfiguration: configuration
        )
        return try encodedData(from: cgImage, configuration: configuration)
    }

    private static func renderCGImage(
        from decoded: DecodedProfileImage,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration,
        renderConfiguration: ProfileImageRenderConfiguration
    ) throws -> CGImage {
        let dimension = max(renderConfiguration.exportDimension, 1)
        let canvasSize = CGFloat(dimension)
        let cropRect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

        guard let context = CGContext(
            data: nil,
            width: dimension,
            height: dimension,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ProfileImageRenderingError.contextCreationFailed
        }

        context.interpolationQuality = .high
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        context.fill(cropRect)

        // Circular alpha mask — only applied when the caller requested
        // a circular export AND the crop shape is a circle. Installed
        // BEFORE the image draw so the off-circle pixels never get
        // committed to the context; the resulting PNG has transparent
        // corners. Saved state is restored so the subsequent transform
        // math still operates on the full square canvas.
        let useCircularMask = renderConfiguration.cropImageCircular
            && editorConfiguration.cropShape == .circle
        if useCircularMask {
            context.saveGState()
            context.addEllipse(in: cropRect)
            context.clip()
        }

        let adjustedImage = try adjustedCGImage(from: decoded.cgImage, adjustments: editorState.adjustments)
        let clampedState = ProfileImageEditorState(
            zoom: min(max(editorState.zoom, editorConfiguration.minimumZoom), editorConfiguration.maximumZoom),
            offset: editorState.offset,
            adjustments: ProfileImageAdjustmentState(
                brightness: editorState.adjustments.brightness,
                contrast: editorState.adjustments.contrast,
                saturation: editorState.adjustments.saturation,
                // Fine rotation is only honored when the configuration
                // allows it. Quantized (90° button) rotation is always
                // honored — the configuration flag gates the slider, not
                // the fundamental axis-swap action.
                rotationDegrees: editorConfiguration.allowsRotation ? editorState.adjustments.rotationDegrees : 0,
                quantizedRotationDegrees: editorState.adjustments.quantizedRotationDegrees,
                flippedHorizontally: editorState.adjustments.flippedHorizontally
            )
        )

        let viewport = ProfileImageViewport(
            sourcePixelSize: CGSize(width: adjustedImage.width, height: adjustedImage.height),
            cropDimension: canvasSize,
            editorState: clampedState,
            configuration: editorConfiguration
        )
        let scaledSize = viewport.scaledDisplaySize
        let offset = viewport.pointOffset(from: viewport.clampedNormalizedOffset(clampedState.offset))
        let drawOrigin = CGPoint(
            x: (canvasSize - scaledSize.width) / 2 + offset.width,
            y: (canvasSize - scaledSize.height) / 2 + offset.height
        )
        let drawRect = CGRect(origin: drawOrigin, size: scaledSize)

        context.translateBy(x: 0, y: canvasSize)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: canvasSize / 2, y: canvasSize / 2)
        context.rotate(by: viewport.rotationRadians)
        // Apply horizontal flip around the canvas center. Order relative
        // to rotation matters: flip-then-rotate yields the intuitive
        // mirror-horizontally-across-the-visible-orientation behavior.
        if clampedState.adjustments.flippedHorizontally {
            context.scaleBy(x: -1, y: 1)
        }
        context.translateBy(x: -canvasSize / 2, y: -canvasSize / 2)
        context.draw(adjustedImage, in: drawRect)

        if useCircularMask {
            context.restoreGState()
        }

        guard let rendered = context.makeImage() else {
            throw ProfileImageRenderingError.exportFailed
        }

        return rendered
    }

    private static func encodedData(
        from cgImage: CGImage,
        configuration: ProfileImageRenderConfiguration
    ) throws -> Data {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            configuration.outputType.identifier as CFString,
            1,
            nil
        ) else {
            throw ProfileImageRenderingError.exportFailed
        }

        let properties: [CFString: Any]
        if configuration.outputType == .jpeg {
            properties = [kCGImageDestinationLossyCompressionQuality: configuration.compressionQuality]
        } else {
            properties = [:]
        }

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ProfileImageRenderingError.exportFailed
        }

        return mutableData as Data
    }

    private static func adjustedCGImage(
        from cgImage: CGImage,
        adjustments: ProfileImageAdjustmentState
    ) throws -> CGImage {
        guard adjustments != .neutral else {
            return cgImage
        }

        let input = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorControls") else {
            throw ProfileImageRenderingError.adjustedImageCreationFailed
        }

        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(adjustments.brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(adjustments.contrast, forKey: kCIInputContrastKey)
        filter.setValue(adjustments.saturation, forKey: kCIInputSaturationKey)

        guard
            let output = filter.outputImage,
            let rendered = ciContext.createCGImage(output, from: output.extent)
        else {
            throw ProfileImageRenderingError.adjustedImageCreationFailed
        }

        return rendered
    }
}
