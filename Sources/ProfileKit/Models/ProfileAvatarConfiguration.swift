import SwiftUI

public struct ProfileAvatarConfiguration {
    public var size: CGFloat
    public var shape: ProfileAvatarShape
    public var borderWidth: CGFloat
    public var borderColor: Color
    /// Explicit initials color. Ignored when `useDefaultForegroundColor`
    /// is true — the initials render in white regardless of this value.
    public var foregroundColor: Color
    /// When true, initials always render in white regardless of
    /// `foregroundColor`. Matches the InitialsUI convenience — white on
    /// a tinted background reads well across the deterministic palette
    /// without callers having to reason about contrast per name.
    public var useDefaultForegroundColor: Bool
    /// Font weight for the initials glyph. Defaults to `.semibold` to
    /// match the prior hardcoded behavior; callers that want a thinner
    /// or bolder look (e.g. `.regular` for a softer avatar, `.heavy`
    /// for a louder one) can override here.
    public var fontWeight: Font.Weight

    public init(
        size: CGFloat = 80,
        shape: ProfileAvatarShape = .circle,
        borderWidth: CGFloat = 0,
        borderColor: Color = .clear,
        foregroundColor: Color = .white,
        useDefaultForegroundColor: Bool = true,
        fontWeight: Font.Weight = .semibold
    ) {
        self.size = size
        self.shape = shape
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
        self.useDefaultForegroundColor = useDefaultForegroundColor
        self.fontWeight = fontWeight
    }

    /// Resolved initials glyph color — honors `useDefaultForegroundColor`.
    var resolvedForegroundColor: Color {
        useDefaultForegroundColor ? .white : foregroundColor
    }
}
