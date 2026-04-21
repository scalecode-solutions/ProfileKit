import Foundation

/// Photo effect applied before the brightness / contrast / saturation
/// adjustments at render time. One effect at a time — the UX model is
/// "pick a look from the film strip," not "stack filters." Parameterized
/// cases carry tuning values directly on the enum so round-tripping
/// through `Codable` captures the full effect configuration.
///
/// The default catalog (`.defaultCatalog`) is ordered for the editor's
/// horizontal preview strip: B&W flavors first, sepia as the warm-bridge,
/// color film looks grouped, then Comic as the stylized outlier. Host
/// apps override via `ProfileImageEditorConfiguration.effectsCatalog`.
public enum ProfileImageEffect: Equatable, Hashable, Sendable, Codable {
    case none

    // Three flavors of B&W — Apple Photos exposes the same trio.
    case mono
    case noir
    case tonal

    /// Classic sepia tone. Intensity 0…1 — 0 is pass-through, 1 is full
    /// warm tint. Default catalog ships with 0.8 for a believable
    /// vintage look without crushing the highlights.
    case sepia(intensity: Double)

    // Film-look presets from the CIPhotoEffect* family. Parameterless —
    // Core Image ships them as fully-tuned LUTs.
    case chrome
    case fade
    case instant
    case process
    case transfer

    /// Stylized line-art / halftone look from CIComicEffect. Not a
    /// neural cartoonifier; user-facing label is "Comic" to set
    /// expectations.
    case comic

    /// Canonical ordering for the editor's effect strip. B&W trio up
    /// front (most common reach), sepia as the bridge to warm looks,
    /// color films grouped, Comic at the end as the oddball. Host apps
    /// wanting a different order or subset override the catalog on
    /// the editor configuration.
    public static let defaultCatalog: [ProfileImageEffect] = [
        .none,
        .mono, .noir, .tonal,
        .sepia(intensity: 0.8),
        .chrome, .fade, .instant, .process, .transfer,
        .comic,
    ]

    /// Stable identifier for cache keys, analytics, and equality-by-kind
    /// checks that ignore parameter values. Two `.sepia` cases with
    /// different intensities share the same identifier because they're
    /// the same effect — callers that care about exact parameters
    /// compare the full case.
    public var identifier: String {
        switch self {
        case .none:     return "none"
        case .mono:     return "mono"
        case .noir:     return "noir"
        case .tonal:    return "tonal"
        case .sepia:    return "sepia"
        case .chrome:   return "chrome"
        case .fade:     return "fade"
        case .instant:  return "instant"
        case .process:  return "process"
        case .transfer: return "transfer"
        case .comic:    return "comic"
        }
    }

    /// True when applying this effect is a no-op. Lets the renderer
    /// short-circuit the CIImage pipeline when the adjustment state is
    /// otherwise neutral.
    public var isIdentity: Bool {
        if case .none = self { return true }
        if case .sepia(let intensity) = self, intensity <= 0 { return true }
        return false
    }
}
