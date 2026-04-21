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
    public var renderConfiguration: ProfileImageRenderConfiguration

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
        renderConfiguration: ProfileImageRenderConfiguration = .profilePhoto
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
        self.renderConfiguration = renderConfiguration
    }

    public static let profilePhoto = Self()
}
