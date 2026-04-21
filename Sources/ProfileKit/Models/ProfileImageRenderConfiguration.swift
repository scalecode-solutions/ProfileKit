import CoreGraphics
import UniformTypeIdentifiers

public struct ProfileImageRenderConfiguration: Sendable {
    public var exportDimension: Int
    public var compressionQuality: CGFloat
    public var outputType: UTType

    public init(
        exportDimension: Int = 1024,
        compressionQuality: CGFloat = 0.9,
        outputType: UTType = .jpeg
    ) {
        self.exportDimension = exportDimension
        self.compressionQuality = compressionQuality
        self.outputType = outputType
    }

    public static let profilePhoto = Self()
}
