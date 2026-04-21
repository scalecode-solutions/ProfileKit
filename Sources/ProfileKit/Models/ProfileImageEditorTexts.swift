import SwiftUI

/// Customizable strings shown in the profile image editor.
///
/// Uses `LocalizedStringKey` so host apps can pipe in their own
/// localization tables via `String.LocalizationValue` interpolation,
/// or pass literal strings where localization isn't needed. Defaults
/// ship in English; ProfileKit doesn't bundle its own `.strings`
/// resources — consumers own their translation story.
///
/// `@unchecked Sendable`: `LocalizedStringKey` is a value type whose
/// internal storage is safe to share across actors, but Apple hasn't
/// audited it for the `Sendable` conformance. Marking the container
/// unchecked is the accepted workaround until Apple annotates the
/// SwiftUI type.
public struct ProfileImageEditorTexts: @unchecked Sendable {
    public var cancelButton: LocalizedStringKey
    public var resetButton: LocalizedStringKey
    public var confirmButton: LocalizedStringKey
    public var rotateLeftLabel: LocalizedStringKey
    public var rotateRightLabel: LocalizedStringKey
    public var flipHorizontalLabel: LocalizedStringKey
    public var brightnessLabel: LocalizedStringKey
    public var contrastLabel: LocalizedStringKey
    public var saturationLabel: LocalizedStringKey
    public var rotationLabel: LocalizedStringKey
    public var adjustmentsHeading: LocalizedStringKey
    public var previewHeading: LocalizedStringKey
    public var interactionInstructions: LocalizedStringKey

    public init(
        cancelButton: LocalizedStringKey = "Cancel",
        resetButton: LocalizedStringKey = "Reset",
        confirmButton: LocalizedStringKey = "Use Photo",
        rotateLeftLabel: LocalizedStringKey = "Rotate left",
        rotateRightLabel: LocalizedStringKey = "Rotate right",
        flipHorizontalLabel: LocalizedStringKey = "Flip horizontally",
        brightnessLabel: LocalizedStringKey = "Brightness",
        contrastLabel: LocalizedStringKey = "Contrast",
        saturationLabel: LocalizedStringKey = "Saturation",
        rotationLabel: LocalizedStringKey = "Rotation",
        adjustmentsHeading: LocalizedStringKey = "Adjustments",
        previewHeading: LocalizedStringKey = "Preview",
        interactionInstructions: LocalizedStringKey = "Pinch to zoom, drag to reposition"
    ) {
        self.cancelButton = cancelButton
        self.resetButton = resetButton
        self.confirmButton = confirmButton
        self.rotateLeftLabel = rotateLeftLabel
        self.rotateRightLabel = rotateRightLabel
        self.flipHorizontalLabel = flipHorizontalLabel
        self.brightnessLabel = brightnessLabel
        self.contrastLabel = contrastLabel
        self.saturationLabel = saturationLabel
        self.rotationLabel = rotationLabel
        self.adjustmentsHeading = adjustmentsHeading
        self.previewHeading = previewHeading
        self.interactionInstructions = interactionInstructions
    }

    public static let `default` = Self()
}
