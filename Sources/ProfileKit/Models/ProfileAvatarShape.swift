import CoreGraphics

public enum ProfileAvatarShape: Sendable, Equatable {
    case circle
    case roundedRect(cornerRadius: CGFloat)
}
