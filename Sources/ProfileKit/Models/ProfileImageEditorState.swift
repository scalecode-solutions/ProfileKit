import CoreGraphics

public struct ProfileImageEditorState: Equatable, Hashable, Sendable, Codable {
    public var zoom: CGFloat
    public var offset: CGSize
    public var adjustments: ProfileImageAdjustmentState

    public init(
        zoom: CGFloat = 1,
        offset: CGSize = .zero,
        adjustments: ProfileImageAdjustmentState = .neutral
    ) {
        self.zoom = zoom
        self.offset = offset
        self.adjustments = adjustments
    }

    public var isIdentity: Bool {
        zoom == 1 && offset == .zero && adjustments == .neutral
    }

    public mutating func reset() {
        zoom = 1
        offset = .zero
        adjustments = .neutral
    }
}
