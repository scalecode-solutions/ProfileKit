import SwiftUI

/// Visual configuration for avatar views (size, shape, border, initials
/// typography). Persistable via `Codable`, value-comparable via
/// `Equatable`, and `Sendable` for use in async rendering paths.
///
/// All color and font fields use ProfileKit's own codable tokens
/// (`ProfileColor`, `ProfileFontWeight`, `ProfileFontDesign`) rather
/// than SwiftUI types, because `Color` / `Font.Weight` / `Font.Design`
/// don't conform to `Codable` reliably. The SwiftUI bridges live on
/// those tokens — `configuration.borderColor.color` gets you a `Color`,
/// `configuration.fontWeight.fontWeight` gets you a `Font.Weight`.
public struct ProfileAvatarConfiguration: Equatable, Hashable, Sendable, Codable {
    public var size: CGFloat
    public var shape: ProfileAvatarShape
    public var borderWidth: CGFloat
    public var borderColor: ProfileColor
    /// Explicit initials color. Ignored when `useDefaultForegroundColor`
    /// is true — the initials render in white regardless of this value.
    public var foregroundColor: ProfileColor
    /// When true, initials always render in white regardless of
    /// `foregroundColor`. Matches the InitialsUI convenience — white on
    /// a tinted background reads well across the deterministic palette
    /// without callers having to reason about contrast per name.
    public var useDefaultForegroundColor: Bool
    /// Font weight for the initials glyph. Defaults to `.semibold` to
    /// match the prior hardcoded behavior; callers that want a thinner
    /// or bolder look (e.g. `.regular` for a softer avatar, `.heavy`
    /// for a louder one) can override here.
    public var fontWeight: ProfileFontWeight
    /// Font design family for the initials glyph. Defaults to
    /// `.rounded` — the friendlier look that `InitialsAvatarView` has
    /// shipped with since day one. Host apps wanting a serif monogram
    /// or a monospaced look (identicon-ish) override here.
    public var fontDesign: ProfileFontDesign

    public init(
        size: CGFloat = 80,
        shape: ProfileAvatarShape = .circle,
        borderWidth: CGFloat = 0,
        borderColor: ProfileColor = .clear,
        foregroundColor: ProfileColor = .white,
        useDefaultForegroundColor: Bool = true,
        fontWeight: ProfileFontWeight = .semibold,
        fontDesign: ProfileFontDesign = .rounded
    ) {
        self.size = size
        self.shape = shape
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
        self.useDefaultForegroundColor = useDefaultForegroundColor
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
    }

    /// Resolved initials glyph color — honors `useDefaultForegroundColor`.
    var resolvedForegroundColor: ProfileColor {
        useDefaultForegroundColor ? .white : foregroundColor
    }
}
