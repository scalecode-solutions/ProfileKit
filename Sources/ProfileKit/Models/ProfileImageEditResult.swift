import Foundation
import UniformTypeIdentifiers

/// Result of a commit-edit render pass: the rendered platform image,
/// the encoded data (JPEG or PNG per config), the content type, and
/// the origin — which editor source produced the result and the full
/// state needed to re-open it for further editing.
///
/// `@unchecked Sendable`: carries a PKPlatformImage (UIImage/NSImage)
/// which Apple hasn't audited for Sendable but is practically
/// immutable once constructed. Required because the async render path
/// returns this across actor boundaries.
public struct ProfileImageEditResult: @unchecked Sendable {
    public let image: PKPlatformImage
    public let data: Data
    public let contentType: UTType
    /// Where this result came from (photo / initials) and the state
    /// needed to re-open it. Replaced the previous `editorState` field;
    /// see `origin.photoState` for the photo-path-equivalent accessor.
    public let origin: ProfileAvatarOrigin

    public init(
        image: PKPlatformImage,
        data: Data,
        contentType: UTType,
        origin: ProfileAvatarOrigin
    ) {
        self.image = image
        self.data = data
        self.contentType = contentType
        self.origin = origin
    }
}
