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

    public static func renderEditResult(
        from source: ProfileImageSource,
        editorState: ProfileImageEditorState,
        editorConfiguration: ProfileImageEditorConfiguration = .profilePhoto,
        configuration: ProfileImageRenderConfiguration = .profilePhoto
    ) throws -> ProfileImageEditResult {
        let decoded = try ProfileImageDecoder.decode(source)
        let cgImage = try renderCGImage(
            from: decoded,
            editorState: editorState,
            editorConfiguration: editorConfiguration,
            renderConfiguration: configuration
        )
        let image = PlatformImageBridge.makeImage(from: cgImage)
        let data = try encodedData(from: cgImage, configuration: configuration)
        return ProfileImageEditResult(
            image: image,
            data: data,
            contentType: configuration.outputType,
            editorState: editorState
        )
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

        let adjustedImage = try adjustedCGImage(from: decoded.cgImage, adjustments: editorState.adjustments)
        let clampedState = ProfileImageEditorState(
            zoom: min(max(editorState.zoom, editorConfiguration.minimumZoom), editorConfiguration.maximumZoom),
            offset: editorState.offset,
            adjustments: ProfileImageAdjustmentState(
                brightness: editorState.adjustments.brightness,
                contrast: editorState.adjustments.contrast,
                saturation: editorState.adjustments.saturation,
                rotationDegrees: editorConfiguration.allowsRotation ? editorState.adjustments.rotationDegrees : 0
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
        context.translateBy(x: -canvasSize / 2, y: -canvasSize / 2)
        context.draw(adjustedImage, in: drawRect)

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
