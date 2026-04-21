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

    public init(
        cropShape: ProfileAvatarShape = .circle,
        minimumZoom: CGFloat = 1,
        maximumZoom: CGFloat = 4,
        cropPadding: CGFloat = 24,
        initialZoom: CGFloat = 1.05,
        initialVerticalBias: CGFloat = -0.08,
        allowsRotation: Bool = true,
        doubleTapZoomFactor: CGFloat = 2,
        showsLivePreview: Bool = true,
        showsAdjustmentControls: Bool = true,
        showsGridOverlay: Bool = true,
        renderConfiguration: ProfileImageRenderConfiguration = .profilePhoto,
        texts: ProfileImageEditorTexts = .default
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
    }

    public static let profilePhoto = Self()
}
