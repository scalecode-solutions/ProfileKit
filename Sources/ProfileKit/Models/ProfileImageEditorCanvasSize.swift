import CoreGraphics

/// Sizing for the editor's crop canvas. Defaults to `.fill` (the
/// canvas grows to fit the container, preserving the pre-0.3.0
/// behavior); named presets and `.fixed(_:)` let hosts constrain the
/// canvas for inline embeds, split-view layouts, bottom-sheet
/// detents, or any context where the full-screen canvas is too much.
///
/// Sliders and other adjustment controls are intentionally NOT
/// size-aware — they take whatever horizontal space their container
/// provides. Canvas sizing only affects the crop area.
public struct ProfileImageEditorCanvasSize: Equatable, Sendable {
    /// Point dimension for the canvas's square edge, or `nil` to fill
    /// the available container space (the default, pre-0.3.0 behavior).
    public let dimension: CGFloat?

    public init(dimension: CGFloat?) {
        self.dimension = dimension
    }

    /// Canvas fills the available container space (aspect-ratio 1:1).
    /// Best for full-screen editors where the user benefits from the
    /// largest possible gesture surface.
    public static let fill = Self(dimension: nil)

    /// 240pt square. For compact embeds — inline in a form, inside a
    /// narrow split pane, or a small bottom sheet.
    public static let compact = Self(dimension: 240)

    /// 320pt square. A middle-ground size for medium embeds or
    /// `.medium`-detent sheets where you want room for adjustment
    /// sliders below without shrinking the canvas to feel cramped.
    public static let regular = Self(dimension: 320)

    /// 420pt square. Near-full-width on most phones; roomy gesture
    /// surface while still leaving space for chrome above and below.
    public static let expanded = Self(dimension: 420)

    /// Pin the canvas to an explicit point dimension. Use when none of
    /// the named presets fit — for example, sizing the canvas to match
    /// a sibling view's measured width.
    public static func fixed(_ dimension: CGFloat) -> Self {
        Self(dimension: dimension)
    }
}
