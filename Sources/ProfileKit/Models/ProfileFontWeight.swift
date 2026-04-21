import SwiftUI

/// Codable wrapper around `SwiftUI.Font.Weight`. SwiftUI's `Font.Weight`
/// isn't `Codable` (or `Hashable` in a stable way), so persistable
/// models use this enum instead and bridge to the SwiftUI value at
/// render time.
///
/// Cases mirror the SwiftUI set one-for-one, including the rarely-used
/// `.ultraLight` / `.black`. Host apps designing initials can pick any
/// of them; the editor UI exposes a curated subset by default.
public enum ProfileFontWeight: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    public init(_ weight: Font.Weight) {
        switch weight {
        case .ultraLight: self = .ultraLight
        case .thin:       self = .thin
        case .light:      self = .light
        case .medium:     self = .medium
        case .semibold:   self = .semibold
        case .bold:       self = .bold
        case .heavy:      self = .heavy
        case .black:      self = .black
        default:          self = .regular
        }
    }

    public var fontWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}
