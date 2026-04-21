import Foundation

public struct ProfileImageAdjustmentState: Equatable, Sendable {
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    /// Photo effect preset applied before the brightness / contrast /
    /// saturation controls at render time. `.none` leaves the image
    /// untouched (default). Effects are baked into the committed
    /// render — saved `ProfileImageEditResult.data` reflects the
    /// selected preset with no additional work from callers.
    public var effect: ProfileImageEffect
    /// User-controlled fine rotation in degrees. Combined with
    /// `quantizedRotationDegrees` at render time — this is the slider
    /// adjustment, the quantized value is the snap-to-90° button state.
    public var rotationDegrees: Double
    /// Snap-to-90° rotation state set by the rotate-left / rotate-right
    /// buttons. Accumulates in ±90° steps. Kept separate from
    /// `rotationDegrees` so the fine slider doesn't fight button clicks
    /// and reset is distinct per axis.
    public var quantizedRotationDegrees: Double
    /// Horizontal mirror. Selfie cameras deliver pre-mirrored previews
    /// and users often want to un-mirror them. Applied at render time
    /// via a negative x-axis scale.
    public var flippedHorizontally: Bool

    public init(
        brightness: Double = 0,
        contrast: Double = 1,
        saturation: Double = 1,
        effect: ProfileImageEffect = .none,
        rotationDegrees: Double = 0,
        quantizedRotationDegrees: Double = 0,
        flippedHorizontally: Bool = false
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.effect = effect
        self.rotationDegrees = rotationDegrees
        self.quantizedRotationDegrees = quantizedRotationDegrees
        self.flippedHorizontally = flippedHorizontally
    }

    /// True when the color-controls trio (brightness / contrast /
    /// saturation) is at its identity values. Lets the renderer skip
    /// the `CIColorControls` pass when only an effect is active.
    var isColorControlsNeutral: Bool {
        brightness == 0 && contrast == 1 && saturation == 1
    }

    /// Total rotation applied at render time — fine slider + quantized
    /// button state. Keeping them separate in storage but composed on
    /// read lets the editor show each as its own control without the
    /// user fighting themselves when both change.
    public var effectiveRotationDegrees: Double {
        rotationDegrees + quantizedRotationDegrees
    }

    public static let neutral = Self()
}
