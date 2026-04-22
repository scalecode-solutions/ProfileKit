/// ProfileKit is a SwiftUI-first toolkit for rendering, editing, and
/// exporting profile images with avatar-specific defaults. Covers both
/// photo-source avatars (crop / rotate / flip / effects) and designed-
/// initials avatars (glyph / background / typography / shadow) through
/// a unified `ProfileImageEditResult` output contract.
public enum ProfileKit {
    /// Semantic version string. Bump when releasing. Exposed for
    /// diagnostics — host apps can include this in crash reports and
    /// telemetry to correlate issues against ProfileKit releases.
    public static let version = "0.8.1"
}
