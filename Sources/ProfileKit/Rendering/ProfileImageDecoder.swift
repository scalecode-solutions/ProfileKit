import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct DecodedProfileImage {
    public let cgImage: CGImage
    public let pixelSize: CGSize
    public let contentType: UTType?

    public init(cgImage: CGImage, pixelSize: CGSize, contentType: UTType?) {
        self.cgImage = cgImage
        self.pixelSize = pixelSize
        self.contentType = contentType
    }
}

public enum ProfileImageDecodingError: LocalizedError {
    case unsupportedSource
    case decodeFailed
    case imageCreationFailed

    public var errorDescription: String? {
        switch self {
        case .unsupportedSource:
            return "The image source format is not supported."
        case .decodeFailed:
            return "ProfileKit could not decode the image."
        case .imageCreationFailed:
            return "ProfileKit could not create a normalized image."
        }
    }
}

public enum ProfileImageDecoder {
    private static let ciContext = CIContext(options: nil)

    public static func decode(_ source: ProfileImageSource) throws -> DecodedProfileImage {
        switch source {
        case .data(let data):
            return try decodeImageSource(CGImageSourceCreateWithData(data as CFData, nil))
        case .fileURL(let fileURL):
            return try decodeImageSource(CGImageSourceCreateWithURL(fileURL as CFURL, nil))
        case .cgImage(let cgImage):
            return DecodedProfileImage(
                cgImage: cgImage,
                pixelSize: CGSize(width: cgImage.width, height: cgImage.height),
                contentType: nil
            )
        case .image(let image):
            guard let cgImage = PlatformImageBridge.cgImage(from: image) else {
                throw ProfileImageDecodingError.unsupportedSource
            }

            return DecodedProfileImage(
                cgImage: cgImage,
                pixelSize: PlatformImageBridge.pixelSize(for: image),
                contentType: nil
            )
        }
    }

    private static func decodeImageSource(_ imageSource: CGImageSource?) throws -> DecodedProfileImage {
        guard let imageSource else {
            throw ProfileImageDecodingError.unsupportedSource
        }

        guard let rawCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ProfileImageDecodingError.decodeFailed
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        let orientationValue = (properties?[kCGImagePropertyOrientation] as? UInt32) ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up
        let cgImage = try normalize(rawCGImage, orientation: orientation)

        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let contentType = CGImageSourceGetType(imageSource).flatMap { UTType($0 as String) }

        return DecodedProfileImage(cgImage: cgImage, pixelSize: pixelSize, contentType: contentType)
    }

    private static func normalize(_ cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> CGImage {
        guard orientation != .up else {
            return cgImage
        }

        let ciImage = CIImage(cgImage: cgImage).oriented(orientation)
        let extent = ciImage.extent.integral

        guard let normalized = ciContext.createCGImage(ciImage, from: extent) else {
            throw ProfileImageDecodingError.imageCreationFailed
        }

        return normalized
    }
}
