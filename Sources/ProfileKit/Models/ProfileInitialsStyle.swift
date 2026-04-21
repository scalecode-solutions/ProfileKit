import CoreGraphics
import Foundation

/// Design-time state for a designed initials avatar. Equivalent role
/// to `ProfileImageEditorState` on the photo path: the host owns the
/// style, the editor mutates it via a `Binding`, and a commit render
/// produces a `ProfileImageEditResult` carrying the baked output plus
/// a snapshot of the style.
///
/// Fully persistable — every field is `Equatable, Sendable, Codable`
/// — so an app can save the style and resume editing later.
public struct ProfileInitialsStyle: Equatable, Hashable, Sendable, Codable {
    /// Explicit glyph override. `nil` or empty → the renderer derives
    /// initials from the paired `ProfileIdentity`. User-typed glyphs
    /// are preserved exactly (lowercase, CJK, emoji); auto-derived
    /// initials still go through `.uppercased()` per today's behavior.
    /// The editor text field caps input at 3 characters (monogram).
    public var glyph: String?

    public var background: ProfileInitialsBackground
    public var foregroundColor: ProfileColor

    public var fontDesign: ProfileFontDesign
    public var fontWeight: ProfileFontWeight
    /// Glyph point size as a fraction of the canvas dimension. 0.38
    /// matches the historical `InitialsAvatarView` hardcode; the editor
    /// exposes a slider in the 0.3…0.7 range. No auto-shrink — if the
    /// glyph overflows, the user nudges this down.
    public var fontScale: CGFloat
    /// Additional tracking applied to the glyph in points. Matters for
    /// two-letter monograms where the default pair can look cramped or
    /// loose depending on the font.
    public var letterSpacing: CGFloat
    /// Vertical offset applied to the glyph baseline as a fraction of
    /// the canvas dimension. Negative nudges the glyph up (useful for
    /// fonts whose cap-height centering reads too low); positive
    /// pushes it down. Clamped to a sensible range in the editor.
    public var verticalBias: CGFloat

    public var shadow: ProfileInitialsShadow?

    public init(
        glyph: String? = nil,
        background: ProfileInitialsBackground = .deterministicPalette(.automatic),
        foregroundColor: ProfileColor = .white,
        fontDesign: ProfileFontDesign = .rounded,
        fontWeight: ProfileFontWeight = .semibold,
        fontScale: CGFloat = 0.38,
        letterSpacing: CGFloat = 0,
        verticalBias: CGFloat = 0,
        shadow: ProfileInitialsShadow? = nil
    ) {
        self.glyph = glyph
        self.background = background
        self.foregroundColor = foregroundColor
        self.fontDesign = fontDesign
        self.fontWeight = fontWeight
        self.fontScale = fontScale
        self.letterSpacing = letterSpacing
        self.verticalBias = verticalBias
        self.shadow = shadow
    }

    /// Sensible preset used when a host first opens the initials
    /// editor. Renders visually identical to today's `InitialsAvatarView`
    /// output when paired with the same identity — nothing regresses
    /// for callers that don't touch the style.
    public static let `default` = ProfileInitialsStyle()

    /// True when the style carries no edits. Used by the editor's
    /// "Reset" action and by host code that wants to detect whether
    /// the user has customized anything.
    public var isDefault: Bool {
        self == .default
    }

    /// Resolves the glyph that should be rendered for a given identity.
    /// `glyph` override wins when non-empty (after whitespace trim);
    /// otherwise the identity's own `initials` (already uppercased via
    /// the generator). Trailing whitespace is dropped because the
    /// editor preserves in-progress typing verbatim.
    public func resolvedGlyph(for identity: ProfileIdentity) -> String {
        if let glyph {
            let trimmed = glyph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return identity.initials
    }
}
