import CoreGraphics
import UniformTypeIdentifiers

public struct ProfileImageDraft {
    public let image: PKPlatformImage
    public let pixelSize: CGSize
    public let contentType: UTType?
    public let identity: ProfileIdentity?
    public var editorState: ProfileImageEditorState

    public init(
        image: PKPlatformImage,
        pixelSize: CGSize,
        contentType: UTType?,
        identity: ProfileIdentity?,
        editorState: ProfileImageEditorState
    ) {
        self.image = image
        self.pixelSize = pixelSize
        self.contentType = contentType
        self.identity = identity
        self.editorState = editorState
    }
}
