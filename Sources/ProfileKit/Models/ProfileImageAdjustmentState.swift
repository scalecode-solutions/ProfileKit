import Foundation

public struct ProfileImageAdjustmentState: Equatable, Sendable {
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    public var rotationDegrees: Double

    public init(
        brightness: Double = 0,
        contrast: Double = 1,
        saturation: Double = 1,
        rotationDegrees: Double = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.rotationDegrees = rotationDegrees
    }

    public static let neutral = Self()
}
