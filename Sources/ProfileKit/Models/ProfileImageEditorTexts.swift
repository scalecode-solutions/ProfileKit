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

    // MARK: - Initials editor strings (step 18)

    public var initialsConfirmButton: LocalizedStringKey
    public var initialsGlyphLabel: LocalizedStringKey
    public var initialsGlyphPlaceholder: LocalizedStringKey
    public var initialsGlyphFromNameLabel: LocalizedStringKey
    public var initialsBackgroundHeading: LocalizedStringKey
    public var initialsBackgroundSolid: LocalizedStringKey
    public var initialsBackgroundLinear: LocalizedStringKey
    public var initialsBackgroundRadial: LocalizedStringKey
    public var initialsBackgroundAuto: LocalizedStringKey
    public var initialsGradientAngleLabel: LocalizedStringKey
    public var initialsGradientAddStopLabel: LocalizedStringKey
    public var initialsGradientRemoveStopLabel: LocalizedStringKey
    public var initialsPaletteLabel: LocalizedStringKey
    public var initialsPaletteDisplayNames: [ProfileAvatarPaletteName: LocalizedStringKey]
    public var initialsForegroundLabel: LocalizedStringKey
    public var initialsTypographyHeading: LocalizedStringKey
    public var initialsFontDesignLabel: LocalizedStringKey
    public var initialsFontDesignDisplayNames: [ProfileFontDesign: LocalizedStringKey]
    public var initialsFontWeightLabel: LocalizedStringKey
    public var initialsFontWeightDisplayNames: [ProfileFontWeight: LocalizedStringKey]
    public var initialsFontScaleLabel: LocalizedStringKey
    public var initialsLetterSpacingLabel: LocalizedStringKey
    public var initialsVerticalBiasLabel: LocalizedStringKey
    public var initialsShadowHeading: LocalizedStringKey
    public var initialsShadowAddLabel: LocalizedStringKey
    public var initialsShadowRemoveLabel: LocalizedStringKey
    public var initialsShadowOpacityLabel: LocalizedStringKey
    public var initialsShadowRadiusLabel: LocalizedStringKey
    public var initialsShadowOffsetYLabel: LocalizedStringKey

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
        effectDisplayNames: [ProfileImageEffect: LocalizedStringKey] = ProfileImageEditorTexts.makeDefaultEffectDisplayNames(),
        initialsConfirmButton: LocalizedStringKey = "Use Avatar",
        initialsGlyphLabel: LocalizedStringKey = "Initials",
        initialsGlyphPlaceholder: LocalizedStringKey = "e.g. JD",
        initialsGlyphFromNameLabel: LocalizedStringKey = "From name",
        initialsBackgroundHeading: LocalizedStringKey = "Background",
        initialsBackgroundSolid: LocalizedStringKey = "Solid",
        initialsBackgroundLinear: LocalizedStringKey = "Linear",
        initialsBackgroundRadial: LocalizedStringKey = "Radial",
        initialsBackgroundAuto: LocalizedStringKey = "Auto",
        initialsGradientAngleLabel: LocalizedStringKey = "Angle",
        initialsGradientAddStopLabel: LocalizedStringKey = "Add third color",
        initialsGradientRemoveStopLabel: LocalizedStringKey = "Remove third color",
        initialsPaletteLabel: LocalizedStringKey = "Palette",
        initialsPaletteDisplayNames: [ProfileAvatarPaletteName: LocalizedStringKey] = ProfileImageEditorTexts.makeDefaultPaletteDisplayNames(),
        initialsForegroundLabel: LocalizedStringKey = "Foreground",
        initialsTypographyHeading: LocalizedStringKey = "Typography",
        initialsFontDesignLabel: LocalizedStringKey = "Design",
        initialsFontDesignDisplayNames: [ProfileFontDesign: LocalizedStringKey] = ProfileImageEditorTexts.makeDefaultFontDesignDisplayNames(),
        initialsFontWeightLabel: LocalizedStringKey = "Weight",
        initialsFontWeightDisplayNames: [ProfileFontWeight: LocalizedStringKey] = ProfileImageEditorTexts.makeDefaultFontWeightDisplayNames(),
        initialsFontScaleLabel: LocalizedStringKey = "Size",
        initialsLetterSpacingLabel: LocalizedStringKey = "Tracking",
        initialsVerticalBiasLabel: LocalizedStringKey = "Vertical nudge",
        initialsShadowHeading: LocalizedStringKey = "Shadow",
        initialsShadowAddLabel: LocalizedStringKey = "Add shadow",
        initialsShadowRemoveLabel: LocalizedStringKey = "Remove shadow",
        initialsShadowOpacityLabel: LocalizedStringKey = "Opacity",
        initialsShadowRadiusLabel: LocalizedStringKey = "Blur",
        initialsShadowOffsetYLabel: LocalizedStringKey = "Y offset"
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
        self.initialsConfirmButton = initialsConfirmButton
        self.initialsGlyphLabel = initialsGlyphLabel
        self.initialsGlyphPlaceholder = initialsGlyphPlaceholder
        self.initialsGlyphFromNameLabel = initialsGlyphFromNameLabel
        self.initialsBackgroundHeading = initialsBackgroundHeading
        self.initialsBackgroundSolid = initialsBackgroundSolid
        self.initialsBackgroundLinear = initialsBackgroundLinear
        self.initialsBackgroundRadial = initialsBackgroundRadial
        self.initialsBackgroundAuto = initialsBackgroundAuto
        self.initialsGradientAngleLabel = initialsGradientAngleLabel
        self.initialsGradientAddStopLabel = initialsGradientAddStopLabel
        self.initialsGradientRemoveStopLabel = initialsGradientRemoveStopLabel
        self.initialsPaletteLabel = initialsPaletteLabel
        self.initialsPaletteDisplayNames = initialsPaletteDisplayNames
        self.initialsForegroundLabel = initialsForegroundLabel
        self.initialsTypographyHeading = initialsTypographyHeading
        self.initialsFontDesignLabel = initialsFontDesignLabel
        self.initialsFontDesignDisplayNames = initialsFontDesignDisplayNames
        self.initialsFontWeightLabel = initialsFontWeightLabel
        self.initialsFontWeightDisplayNames = initialsFontWeightDisplayNames
        self.initialsFontScaleLabel = initialsFontScaleLabel
        self.initialsLetterSpacingLabel = initialsLetterSpacingLabel
        self.initialsVerticalBiasLabel = initialsVerticalBiasLabel
        self.initialsShadowHeading = initialsShadowHeading
        self.initialsShadowAddLabel = initialsShadowAddLabel
        self.initialsShadowRemoveLabel = initialsShadowRemoveLabel
        self.initialsShadowOpacityLabel = initialsShadowOpacityLabel
        self.initialsShadowRadiusLabel = initialsShadowRadiusLabel
        self.initialsShadowOffsetYLabel = initialsShadowOffsetYLabel
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

    public static func makeDefaultPaletteDisplayNames() -> [ProfileAvatarPaletteName: LocalizedStringKey] {
        [
            .automatic: "Automatic",
            .mono:      "Mono",
            .warm:      "Warm",
            .cool:      "Cool",
            .vibrant:   "Vibrant",
            .pastel:    "Pastel",
        ]
    }

    public static func makeDefaultFontDesignDisplayNames() -> [ProfileFontDesign: LocalizedStringKey] {
        [
            .default:     "Default",
            .serif:       "Serif",
            .rounded:     "Rounded",
            .monospaced:  "Mono",
        ]
    }

    public static func makeDefaultFontWeightDisplayNames() -> [ProfileFontWeight: LocalizedStringKey] {
        [
            .ultraLight: "Ultra Light",
            .thin:       "Thin",
            .light:      "Light",
            .regular:    "Regular",
            .medium:     "Medium",
            .semibold:   "Semibold",
            .bold:       "Bold",
            .heavy:      "Heavy",
            .black:      "Black",
        ]
    }

    public static let `default` = Self()
}
