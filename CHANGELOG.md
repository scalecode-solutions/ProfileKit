# Changelog

## 0.8.1

Patch release: fix for the effect preset not appearing in the editor
canvas or preview row while editing (effects were still correctly
baked into the committed export).

### Fixed

- **Live canvas + preview row now show the selected effect.** The
  editor's `editableImage(cropSize:)` applied `.brightness`,
  `.contrast`, `.saturation` as SwiftUI modifiers but had no
  equivalent for Core Image effects, so picking a preset from the
  film strip left the live canvas unfiltered. The committed render
  has always been correct (runs the full `EffectsPipeline`); only the
  previews were missing the filter. Fixed by caching a
  Core-Image-filtered `PKPlatformImage` keyed by `(source, effect)`
  and consulting it from the display path. Brightness / contrast /
  saturation sliders still layer on top, matching the renderer's
  effect-then-color-controls ordering.

## 0.8.0

Initials as a first-class avatar source, photo effects gallery, and a
unified editor surface. Major feature release with a curated set of
breaking changes; all API surgery below is documented with before/after
migrations.

### Added

- **Designed initials are now a first-class avatar source.** New
  `ProfileInitialsStyle`, `ProfileInitialsBackground`,
  `ProfileInitialsShadow`, and `ProfileInitialsDraft` model types fully
  `Equatable` / `Hashable` / `Sendable` / `Codable`. Host apps can
  design a monogram (glyph, solid / gradient / radial / deterministic-
  palette background, foreground color, typography, optional drop
  shadow), commit for a real `ProfileImageEditResult` (same shape as a
  cropped photo), and persist the style for later re-editing.
- **Initials renderer** (`ProfileInitialsRenderer`) that rasterizes a
  style to a `ProfileImageEditResult` via Core Text + Core Graphics —
  no SwiftUI in the pipeline, pixel-accurate output matching the live
  `InitialsAvatarView` preview.
- **Initials editor views**: `ProfileInitialsEditorContent` (chromeless
  primitive), `ProfileInitialsEditorView` (modal-ready wrapper), and
  `ProfileInitialsEditorScreen` (fully-wired screen). Parallels the
  `ProfileImageEditor*` trio one-for-one.
- **Photo effects gallery**: 11-preset catalog
  (`None, Mono, Noir, Tonal, Sepia, Chrome, Fade, Instant, Process,
  Transfer, Comic`) exposed via `ProfileImageEffect` and a
  `ProfileImageEffectsStrip` UI rendered inside the photo editor.
  Parameterized `.sepia(intensity:)` is the only tunable case; others
  are fully-tuned Core Image presets. Effects flow through
  `ProfileImageAdjustmentState.effect` and are baked into committed
  renders automatically.
- **Unified editor** (`ProfileAvatarEditor`) — segmented control
  between Photo and Initials tabs, each owning its own state, a single
  `onCommit` callback regardless of source.
- **Palette catalog expansion**: `ProfileAvatarPaletteName` with six
  variants (`automatic`, `mono`, `warm`, `cool`, `vibrant`, `pastel`).
  New `ProfileAvatarPalette.colors(for:palette:)` sibling returns
  `[ProfileColor]`.
- **Persistable tokens**: `ProfileColor`, `ProfileFontWeight`,
  `ProfileFontDesign` — codable wrappers around the SwiftUI types that
  aren't formally `Codable`.
- **Round-trip re-editing**: `ProfileAvatarOrigin` on
  `ProfileImageEditResult` captures full state for either editor path.
  `ProfileImageWorkflow.reopen(result:)` reconstructs the appropriate
  draft from a persisted result.
- **Initials workflow helpers**:
  `ProfileImageWorkflow.makeInitialsDraft(identity:style:)`,
  `export(initialsDraft:configuration:)`,
  `exportAsync(initialsDraft:configuration:)`.
- `ProfileKit.version` diagnostic string.

### Breaking changes

Migrate per the before/after pairs below. The package is on Swift 6
strict concurrency and several of these changes additionally enable
`Codable` / `Sendable` on previously-non-conforming types, so host
apps that archived state to disk will need a one-time migration pass.

#### 1. `ProfileAvatarView(image:identity:configuration:)` → `ProfileAvatarView(content:configuration:)`

The `image ?? fallback-to-initials` branch now lives in the type
system via a new `ProfileAvatarContent` enum.

```swift
// Before
ProfileAvatarView(image: image, identity: identity, configuration: config)

// After
ProfileAvatarView(content: .image(image), configuration: config)

// Before (image-optional fallback pattern)
ProfileAvatarView(image: maybeImage, identity: identity, configuration: config)

// After
ProfileAvatarView(
    content: maybeImage.map(ProfileAvatarContent.image) ?? .initials(identity),
    configuration: config
)
```

#### 2. `ProfileAvatarConfiguration` uses codable tokens

Three SwiftUI types (`Color`, `Font.Weight`) replaced with codable
siblings. A new `fontDesign` field rounds out the typography surface.

```swift
// Before
ProfileAvatarConfiguration(
    borderColor: Color.white.opacity(0.5),
    foregroundColor: Color.white,
    fontWeight: .semibold
)

// After
ProfileAvatarConfiguration(
    borderColor: ProfileColor.white.opacity(0.5),
    foregroundColor: .white,
    fontWeight: .semibold,
    fontDesign: .rounded        // new, defaults to .rounded
)
```

The struct now conforms to `Equatable, Hashable, Sendable, Codable`.

#### 3. `ProfileImageEditResult.editorState` → `ProfileImageEditResult.origin`

Origin captures both the source kind (photo vs. initials) and the
state needed to re-open the result.

```swift
// Before
let state: ProfileImageEditorState = result.editorState

// After
let state: ProfileImageEditorState? = result.origin.photoState
// For initials results:
let style: ProfileInitialsStyle? = result.origin.initialsStyle
let identity: ProfileIdentity? = result.origin.initialsIdentity
```

Side effects of supporting `Codable` origin:
`ProfileImageAdjustmentState` and `ProfileImageEditorState` both gain
`Hashable` + `Codable` conformance. `ProfileImageEditResult`'s
initializer signature changed accordingly.

#### 4. `ProfileImageDraft.identity` removed

Identity on the photo draft was dead weight after initials promoted
themselves to their own draft type.

```swift
// Before
let draft = try ProfileImageWorkflow.makeDraft(
    from: source,
    identity: ProfileIdentity(displayName: "Jamie")
)

// After
let photoDraft = try ProfileImageWorkflow.makeDraft(from: source)
let initialsDraft = ProfileImageWorkflow.makeInitialsDraft(
    identity: ProfileIdentity(displayName: "Jamie")
)
// Present either, or both via ProfileAvatarEditor.
```

Same signature change applies to
`ProfileImageWorkflow.makeDraft(from: PhotosPickerItem, ...)`.

#### 5. `ProfileImageAdjustmentState` gains `effect: ProfileImageEffect = .none`

Source-compatible via the default parameter, but archived `Codable`
encodings from prior versions (if host apps were rolling their own)
will need a one-time migration that supplies `.none` for absent
`effect` fields.

### Internal refactors (no API changes)

- Shared encoding helpers (`ProfileImageEncoding.encodedData(...)`,
  `effectiveRenderConfiguration(_:cropShape:)`) extracted from
  `ProfileImageRenderer` so the initials renderer can reuse the
  JPEG → PNG upgrade rule without duplication. Photo renders are
  byte-for-byte identical.
- `ProfileImageRenderer.adjustedCGImage` rewired so the effect pass
  precedes the color-controls pass, with a short-circuit that skips
  the entire `CIImage` round-trip when both are neutral.

### Test coverage

60 tests across 12 suites: color round-trips, font-token round-trips,
effect pipeline (identity / filter-name / extent preservation / every
catalog entry renders), initials renderer (size, format-forcing,
background divergence, glyph override), initials workflow, palette
catalog (determinism + chromaticity), avatar origin round-trip, and
workflow reopen for both variants.
