import Foundation
import UniformTypeIdentifiers

public struct ProfileImageEditResult {
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
