import SwiftUI

/// Codable wrapper around `SwiftUI.Font.Design`. Mirrors the SwiftUI
/// cases one-for-one so persistable initials styles can record and
/// restore the design family without round-tripping through a runtime
/// `Font.Design` value (which isn't `Codable`).
///
/// `default` tracks whatever system font the platform uses (SF Pro on
/// Apple platforms). `rounded` is the avatar-friendly default —
/// `InitialsAvatarView` has shipped with it since day one.
public enum ProfileFontDesign: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case `default`
    case serif
    case rounded
    case monospaced

    public init(_ design: Font.Design) {
        switch design {
        case .serif:       self = .serif
        case .rounded:     self = .rounded
        case .monospaced:  self = .monospaced
        default:           self = .default
        }
    }

    public var fontDesign: Font.Design {
        switch self {
        case .default:     return .default
        case .serif:       return .serif
        case .rounded:     return .rounded
        case .monospaced:  return .monospaced
        }
    }
}
