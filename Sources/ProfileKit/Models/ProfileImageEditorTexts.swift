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
    /// Section heading for the horizontal effects strip.
    public var effectsHeading: LocalizedStringKey
    /// Display names per effect preset. Keyed by `ProfileImageEffect`
    /// so hosts can override just the labels they care about without
    /// redeclaring the whole catalog. Effects not present in the map
    /// fall back to their capitalized identifier (e.g. "Mono", "Noir").
    public var effectDisplayNames: [ProfileImageEffect: LocalizedStringKey]

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
        interactionInstructions: LocalizedStringKey = "Pinch to zoom, drag to reposition",
        effectsHeading: LocalizedStringKey = "Effects",
        effectDisplayNames: [ProfileImageEffect: LocalizedStringKey] = ProfileImageEditorTexts.makeDefaultEffectDisplayNames()
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
        self.effectsHeading = effectsHeading
        self.effectDisplayNames = effectDisplayNames
    }

    /// Resolves a display name for `effect`. Returns the host-provided
    /// label when one is registered, otherwise a fallback derived from
    /// the effect's stable identifier. Keyed by parameter-agnostic
    /// identifier through `ProfileImageEffect.Hashable`: `.sepia(0.8)`
    /// and `.sepia(0.2)` map to the same label.
    public func displayName(for effect: ProfileImageEffect) -> LocalizedStringKey {
        if let override = effectDisplayNames[effect] {
            return override
        }
        // Match by identifier so any sepia intensity hits the same label.
        for (key, value) in effectDisplayNames where key.identifier == effect.identifier {
            return value
        }
        return LocalizedStringKey(effect.identifier.capitalized)
    }

    /// Default English labels for the locked catalog. A function
    /// rather than a `static let` because the dictionary value type
    /// (`LocalizedStringKey`) isn't formally `Sendable` — Swift 6's
    /// strict concurrency flags the mutable-global pattern even though
    /// `LocalizedStringKey` is effectively immutable. Calling this
    /// on demand sidesteps the issue with zero observable cost.
    ///
    /// Keyed with a sentinel parameter value for parameterized cases —
    /// the display name lookup matches by identifier so intensity
    /// doesn't matter.
    public static func makeDefaultEffectDisplayNames() -> [ProfileImageEffect: LocalizedStringKey] {
        [
            .none:                   "None",
            .mono:                   "Mono",
            .noir:                   "Noir",
            .tonal:                  "Tonal",
            .sepia(intensity: 0.8):  "Sepia",
            .chrome:                 "Chrome",
            .fade:                   "Fade",
            .instant:                "Instant",
            .process:                "Process",
            .transfer:               "Transfer",
            .comic:                  "Comic",
        ]
    }

    public static let `default` = Self()
}
