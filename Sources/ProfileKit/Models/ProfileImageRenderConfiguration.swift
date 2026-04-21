import CoreGraphics
import UniformTypeIdentifiers

public struct ProfileImageRenderConfiguration: Sendable {
    public var exportDimension: Int
    public var compressionQuality: CGFloat
    public var outputType: UTType
    /// When true AND the editor's `cropShape` is `.circle`, the exported
    /// image is masked to a circle with transparent corners. JPEG can't
    /// carry alpha, so the renderer forces `.png` output in this mode
    /// regardless of `outputType`. Useful for hosts that display the
    /// avatar on non-uniform backgrounds where a square image with a
    /// white/black background would show visible corners.
    ///
    /// When false (default), the export is always a square image — the
    /// consumer clips it at render time. Produces smaller files when
    /// the host always clips to circle anyway.
    public var cropImageCircular: Bool

    public init(
        exportDimension: Int = 1024,
        compressionQuality: CGFloat = 0.9,
        outputType: UTType = .jpeg,
        cropImageCircular: Bool = false
    ) {
        self.exportDimension = exportDimension
        self.compressionQuality = compressionQuality
        self.outputType = outputType
        self.cropImageCircular = cropImageCircular
    }

    public static let profilePhoto = Self()
}
