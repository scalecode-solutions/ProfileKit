import CoreGraphics
import Foundation

/// Input to the decoder / renderer. Covers the common ways a host app
/// can hand us an image: raw bytes, a file URL, a ready CGImage, or a
/// platform image (UIImage/NSImage).
///
/// `@unchecked Sendable`: both CGImage and the platform image types
/// are practically immutable once constructed — they're safe to pass
/// across cooperative tasks — but Apple hasn't audited them for the
/// Sendable conformance. Marking the enum unchecked is the accepted
/// workaround for async render paths.
public enum ProfileImageSource: @unchecked Sendable {
    case data(Data)
    case fileURL(URL)
    case cgImage(CGImage)
    case image(PKPlatformImage)
}
