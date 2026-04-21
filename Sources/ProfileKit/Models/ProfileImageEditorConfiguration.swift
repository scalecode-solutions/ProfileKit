import SwiftUI

public struct ProfileImageEditorConfiguration: Sendable {
    public var cropShape: ProfileAvatarShape
    public var minimumZoom: CGFloat
    public var maximumZoom: CGFloat
    public var cropPadding: CGFloat
    public var initialZoom: CGFloat
    public var initialVerticalBias: CGFloat
    public var allowsRotation: Bool
    public var doubleTapZoomFactor: CGFloat
    public var showsLivePreview: Bool
    public var showsAdjustmentControls: Bool
    /// Whether the rule-of-thirds grid overlay is drawn over the crop
    /// canvas during editing. Helps the user frame the subject. The
    /// grid never appears in the exported image.
    public var showsGridOverlay: Bool
    public var renderConfiguration: ProfileImageRenderConfiguration
    /// All user-visible strings in the editor. Swap in localized
    /// versions or custom voice here; defaults ship in English.
    public var texts: ProfileImageEditorTexts
    /// Editor chrome appearance. `.system` follows the device setting
    /// (default). `.forceDark` / `.forceLight` pin the editor for apps
    /// with bespoke theming that want the editor to match rather than
    /// follow the OS.
    public var appearance: ProfileImageEditorAppearance
    /// Crop canvas sizing. Defaults to `.fill` (grow to fit container,
    /// pre-0.3.0 behavior). Use `.compact` / `.regular` / `.expanded`
    /// or `.fixed(_:)` to pin the canvas to a specific point dimension
    /// for inline embeds, split-view layouts, or sheet-detent hosts
    /// where a full-screen canvas is inappropriate.
    public var canvasSize: ProfileImageEditorCanvasSize

    public init(
        cropShape: ProfileAvatarShape = .circle,
        minimumZoom: CGFloat = 1,
        maximumZoom: CGFloat = 4,
        cropPadding: CGFloat = 0,
        initialZoom: CGFloat = 1.05,
        initialVerticalBias: CGFloat = -0.08,
        allowsRotation: Bool = true,
        doubleTapZoomFactor: CGFloat = 2,
        showsLivePreview: Bool = true,
        showsAdjustmentControls: Bool = true,
        showsGridOverlay: Bool = true,
        renderConfiguration: ProfileImageRenderConfiguration = .profilePhoto,
        texts: ProfileImageEditorTexts = .default,
        appearance: ProfileImageEditorAppearance = .system,
        canvasSize: ProfileImageEditorCanvasSize = .fill
    ) {
        self.cropShape = cropShape
        self.minimumZoom = minimumZoom
        self.maximumZoom = maximumZoom
        self.cropPadding = cropPadding
        self.initialZoom = initialZoom
        self.initialVerticalBias = initialVerticalBias
        self.allowsRotation = allowsRotation
        self.doubleTapZoomFactor = doubleTapZoomFactor
        self.showsLivePreview = showsLivePreview
        self.showsAdjustmentControls = showsAdjustmentControls
        self.showsGridOverlay = showsGridOverlay
        self.renderConfiguration = renderConfiguration
        self.texts = texts
        self.appearance = appearance
        self.canvasSize = canvasSize
    }

    public static let profilePhoto = Self()
}
