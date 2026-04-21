import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Shared encoding helpers for the photo and initials renderers. Both
/// paths produce a final `CGImage` and want to serialize it to bytes
/// with identical format-forcing behavior (circular crop + JPEG input
/// gets upgraded to PNG because JPEG can't carry alpha).
///
/// Extracted out of `ProfileImageRenderer` in step 13 so the initials
/// renderer (step 14) can share the logic without duplication. Pure
/// refactor — no behavior change; existing callers get identical
/// output down to the byte.
enum ProfileImageEncoding {
    /// Patches `outputType` to `.png` when the render config asks for
    /// a circular export with a circle crop. JPEG can't carry alpha;
    /// silently upgrading the format is kinder than failing the render.
    static func effectiveRenderConfiguration(
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

    /// Encodes a `CGImage` to the format dictated by `configuration`.
    /// Throws `ProfileImageRenderingError.exportFailed` on failure —
    /// matches the pre-refactor behavior of `ProfileImageRenderer`.
    static func encodedData(
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
}
