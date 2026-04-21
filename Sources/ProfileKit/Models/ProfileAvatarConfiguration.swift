import SwiftUI

public struct ProfileAvatarConfiguration {
    public var size: CGFloat
    public var shape: ProfileAvatarShape
    public var borderWidth: CGFloat
    public var borderColor: Color
    public var foregroundColor: Color

    public init(
        size: CGFloat = 80,
        shape: ProfileAvatarShape = .circle,
        borderWidth: CGFloat = 0,
        borderColor: Color = .clear,
        foregroundColor: Color = .white
    ) {
        self.size = size
        self.shape = shape
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
    }
}
