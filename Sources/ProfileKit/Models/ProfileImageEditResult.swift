import Foundation
import UniformTypeIdentifiers

/// Result of a commit-edit render pass: the rendered platform image,
/// the encoded data (JPEG or PNG per config), the content type, and a
/// snapshot of the editor state that produced it.
///
/// `@unchecked Sendable`: carries a PKPlatformImage (UIImage/NSImage)
/// which Apple hasn't audited for Sendable but is practically
/// immutable once constructed. Required because the async render path
/// returns this across actor boundaries.
public struct ProfileImageEditResult: @unchecked Sendable {
    public let image: PKPlatformImage
    public let data: Data
    public let contentType: UTType
    public let editorState: ProfileImageEditorState

    public init(
        image: PKPlatformImage,
        data: Data,
        contentType: UTType,
        editorState: ProfileImageEditorState
    ) {
        self.image = image
        self.data = data
        self.contentType = contentType
        self.editorState = editorState
    }
}
