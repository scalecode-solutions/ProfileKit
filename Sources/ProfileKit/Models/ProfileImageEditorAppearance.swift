import SwiftUI

/// Controls how the editor chrome adapts to the system appearance.
///
/// `.system` follows the device's light/dark setting (the default,
/// matches typical SwiftUI behavior). `.forceDark` and `.forceLight`
/// pin the editor regardless — useful for apps with their own theming
/// that want the editor to match a specific look rather than the OS.
///
/// The pinned modes apply `preferredColorScheme` on the editor root,
/// which only affects the editor view tree; the host app's surfaces
/// are not impacted.
public enum ProfileImageEditorAppearance: Sendable {
    case system
    case forceLight
    case forceDark

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:     return nil
        case .forceLight: return .light
        case .forceDark:  return .dark
        }
    }
}
