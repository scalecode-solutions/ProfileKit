import CoreGraphics

public enum ProfileAvatarShape: Equatable, Hashable, Sendable, Codable {
    case circle
    case roundedRect(cornerRadius: CGFloat)
}
