import CoreGraphics
import UniformTypeIdentifiers

public struct ProfileImageDraft {
    public let image: PKPlatformImage
    public let pixelSize: CGSize
    public let contentType: UTType?
    public var editorState: ProfileImageEditorState

    public init(
        image: PKPlatformImage,
        pixelSize: CGSize,
        contentType: UTType?,
        editorState: ProfileImageEditorState
    ) {
        self.image = image
        self.pixelSize = pixelSize
        self.contentType = contentType
        self.editorState = editorState
    }
}
