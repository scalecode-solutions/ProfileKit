# ProfileKit

SwiftUI-first profile image tooling for `iOS 26+`.

`ProfileKit` is built around a specific job: help apps load profile-photo inputs, give users a good avatar editing experience, export a clean square avatar image, and render profile surfaces with a polished initials fallback when no image is available.

It is not trying to be a generic Photoshop-style editor. The package is intentionally focused on profile images and avatars.

## Goals

- SwiftUI-first API
- `iOS 26` target with Swift 6 / SwiftUI 6
- Accept common platform-supported image formats
- Provide a profile-photo editing workflow
- Export avatar-ready square or circular image data
- Render profile images with a deterministic initials fallback
- Keep networking and account persistence outside the package

## Current Scope

Implemented today:

- Image decoding from:
  - `Data`
  - file URLs
  - `CGImage`
  - platform images (`UIImage` / `NSImage`)
- Orientation normalization during decode
- Avatar-focused editor state
- SwiftUI crop/edit surface with:
  - drag to reposition
  - pinch to zoom
  - double-tap zoom
  - **90° rotate left / rotate right buttons**
  - **horizontal flip**
  - optional fine rotation (slider)
  - brightness / contrast / saturation
  - **rule-of-thirds grid overlay during cropping**
  - **Liquid Glass controls (iOS 26 native)**
- Avatar export pipeline
  - **Background-thread rendering via async API**
  - **Optional circular PNG export with transparent corners**
- Initials fallback avatar rendering
  - **Configurable font weight**
  - **Configurable fallback seed for deterministic colors**
- Higher-level draft/workflow helpers
- Package demo view
- **Fully localizable editor strings**
- **Appearance modes (system / forceDark / forceLight)**

Not included:

- Networking / upload logic
- backend-specific `photoRef` handling
- storage/persistence for editor state
- camera capture UI
- full image library UI

## Platform + Tooling

`ProfileKit` currently declares:

- `iOS 26`
- `macOS 26`
- Swift tools `6.3`
- Swift language mode `6`

The package is designed primarily for iOS app usage. The macOS target exists so local package development and tests can run cleanly in this environment.

## Package Structure

Main folders:

- [Sources/ProfileKit/Models](Sources/ProfileKit/Models)
- [Sources/ProfileKit/Rendering](Sources/ProfileKit/Rendering)
- [Sources/ProfileKit/Views](Sources/ProfileKit/Views)
- [Sources/ProfileKit/Workflow](Sources/ProfileKit/Workflow)
- [Sources/ProfileKit/Support](Sources/ProfileKit/Support)
- [Sources/ProfileKit/Utilities](Sources/ProfileKit/Utilities)
- [Sources/ProfileKit/Examples](Sources/ProfileKit/Examples)

## Core Types

### Workflow

- [ProfileImageWorkflow](Sources/ProfileKit/Workflow/ProfileImageWorkflow.swift)
- [ProfileImageDraft](Sources/ProfileKit/Workflow/ProfileImageDraft.swift)

These are the easiest starting points for host apps.

### Editor

- [ProfileImageEditorScreen](Sources/ProfileKit/Views/ProfileImageEditorScreen.swift)
- [ProfileImageEditorView](Sources/ProfileKit/Views/ProfileImageEditorView.swift)
- [ProfileImageEditorState](Sources/ProfileKit/Models/ProfileImageEditorState.swift)
- [ProfileImageEditorConfiguration](Sources/ProfileKit/Models/ProfileImageEditorConfiguration.swift)
- [ProfileImageEditorTexts](Sources/ProfileKit/Models/ProfileImageEditorTexts.swift) — customizable / localizable button labels
- [ProfileImageEditorAppearance](Sources/ProfileKit/Models/ProfileImageEditorAppearance.swift) — system / forceDark / forceLight

### Rendering

- [ProfileImageDecoder](Sources/ProfileKit/Rendering/ProfileImageDecoder.swift)
- [ProfileImageRenderer](Sources/ProfileKit/Rendering/ProfileImageRenderer.swift) — sync + `async` entry points
- [ProfileImageRenderConfiguration](Sources/ProfileKit/Models/ProfileImageRenderConfiguration.swift)
- [ProfileImageEditResult](Sources/ProfileKit/Models/ProfileImageEditResult.swift)

### Avatar Display

- [ProfileAvatarView](Sources/ProfileKit/Views/ProfileAvatarView.swift)
- [InitialsAvatarView](Sources/ProfileKit/Views/InitialsAvatarView.swift)
- [ProfileIdentity](Sources/ProfileKit/Models/ProfileIdentity.swift)
- [ProfileAvatarConfiguration](Sources/ProfileKit/Models/ProfileAvatarConfiguration.swift)

## Supported Input Formats

`ProfileKit` relies on platform image decoding through `CGImageSource` and related APIs. In practice, that means it is set up to handle common Apple-platform-supported image formats such as:

- JPEG
- PNG
- HEIC / HEIF
- GIF
- WebP
- other formats supported by the current OS image stack

Important note:

- animated formats are treated as image inputs, not as animated avatar outputs
- the export path is currently intended for static avatar images

## Recommended Host-App Flow

The intended host flow is:

1. Pick an image in your app
2. Build a `ProfileImageDraft`
3. Present `ProfileImageEditorScreen`
4. Receive a `ProfileImageEditResult`
5. Upload `result.data`
6. Persist the returned remote reference in your own app model

## Basic Usage

### 1. Create a draft from image data

```swift
import ProfileKit

let draft = try ProfileImageWorkflow.makeDraft(
    from: .data(imageData),
    identity: ProfileIdentity(displayName: "Taylor Example")
)
```

### 2. Present the editor

```swift
import SwiftUI
import ProfileKit

struct EditAvatarScreen: View {
    let draft: ProfileImageDraft
    @State private var exportedResult: ProfileImageEditResult?
    @State private var exportError: String?

    var body: some View {
        ProfileImageEditorScreen(
            draft: draft,
            onCancel: {
                // dismiss your screen
            },
            onCommit: { result in
                switch result {
                case .success(let value):
                    exportedResult = value
                case .failure(let error):
                    exportError = error.localizedDescription
                }
            }
        )
    }
}
```

The editor ships with:

- **90° rotate left / rotate right** buttons under the crop canvas
- **Horizontal flip** button — glass toggle, becomes prominent white when engaged
- **Rule-of-thirds grid overlay** during editing (never rendered into the export)
- **Pinch to zoom**, drag to reposition, double-tap to zoom
- **Fine rotation, brightness, contrast, saturation** sliders (toggleable)
- **Liquid Glass chrome** on iOS 26 — native material controls, no bordered buttons
- **Async rendering** — the "Use Photo" button shows a progress indicator while the render runs on a detached task, so large source images don't stall the UI

### 3. Upload the exported avatar

```swift
switch result {
case .success(let output):
    let dataToUpload = output.data
    let contentType = output.contentType
    let renderedImage = output.image
    // your app uploads dataToUpload and persists the returned remote id/ref
case .failure(let error):
    print(error)
}
```

### 4. Render an avatar in your app

```swift
ProfileAvatarView(
    image: localOrDownloadedPlatformImage,
    identity: ProfileIdentity(displayName: "Taylor Example"),
    configuration: .init(
        size: 72,
        shape: .circle,
        borderWidth: 2,
        borderColor: .white.opacity(0.4)
    )
)
```

### 5. Render an initials fallback directly

```swift
InitialsAvatarView(
    identity: ProfileIdentity(displayName: "Taylor Example"),
    configuration: .init(
        size: 72,
        shape: .circle,
        fontWeight: .bold  // .regular / .medium / .semibold / .bold / .heavy
    )
)
```

The initials renderer picks a deterministic HSL gradient from the `fallbackSeed` (or `displayName`, if no seed is supplied), so the same person always gets the same colors across the app.

## Using `PhotosPicker`

On iOS, the package includes a convenience workflow helper for `PhotosPickerItem` where the API is available.

```swift
import PhotosUI
import ProfileKit

@State private var selectedItem: PhotosPickerItem?

func loadDraft() async throws -> ProfileImageDraft {
    guard let selectedItem else {
        throw CancellationError()
    }

    return try await ProfileImageWorkflow.makeDraft(
        from: selectedItem,
        identity: ProfileIdentity(displayName: "Taylor Example")
    )
}
```

Your app still owns:

- picker presentation
- view dismissal
- upload
- persistence

## Configuration

### `ProfileImageEditorConfiguration`

The main editor tuning surface is [ProfileImageEditorConfiguration.swift](Sources/ProfileKit/Models/ProfileImageEditorConfiguration.swift).

Key knobs:

| Property | Default | Description |
|---|---|---|
| `cropShape` | `.circle` | `.circle` or `.roundedRect(cornerRadius:)` |
| `minimumZoom` | `1` | Lower bound on pinch zoom |
| `maximumZoom` | `4` | Upper bound on pinch zoom |
| `cropPadding` | `24` | Inset of crop canvas inside the editor frame |
| `initialZoom` | `1.05` | Starting zoom when the editor opens |
| `initialVerticalBias` | `-0.08` | Upward framing offset for portraits (face-bias) |
| `allowsRotation` | `true` | Show the fine rotation slider (90° buttons always work) |
| `doubleTapZoomFactor` | `2` | Target zoom when the user double-taps the canvas |
| `showsLivePreview` | `true` | Render the small preview chip next to the canvas |
| `showsAdjustmentControls` | `true` | Show the brightness/contrast/saturation/rotation sliders |
| `showsGridOverlay` | `true` | Rule-of-thirds grid during cropping |
| `renderConfiguration` | `.profilePhoto` | See below |
| `texts` | `.default` | All user-visible strings (see ProfileImageEditorTexts) |
| `appearance` | `.system` | `.system` / `.forceLight` / `.forceDark` |

### `ProfileImageEditorTexts`

Every string the editor renders is customizable via [ProfileImageEditorTexts.swift](Sources/ProfileKit/Models/ProfileImageEditorTexts.swift). Defaults ship in English; pass in `LocalizedStringKey` values backed by your own `.strings` tables to localize.

```swift
let texts = ProfileImageEditorTexts(
    cancelButton: "Back",
    confirmButton: "Set as avatar",
    interactionInstructions: "Drag, pinch, and rotate to frame"
)

let config = ProfileImageEditorConfiguration(texts: texts)
```

### `ProfileImageEditorAppearance`

Pin the editor chrome to a specific color scheme regardless of system setting — useful for apps with their own theming:

```swift
let config = ProfileImageEditorConfiguration(appearance: .forceDark)
```

- `.system` — follow OS setting (default)
- `.forceLight` — always light, regardless of OS
- `.forceDark` — always dark, regardless of OS

### `ProfileImageRenderConfiguration`

Export tuning lives in [ProfileImageRenderConfiguration.swift](Sources/ProfileKit/Models/ProfileImageRenderConfiguration.swift).

Key knobs:

| Property | Default | Description |
|---|---|---|
| `exportDimension` | `1024` | Side length of the exported square image, in pixels |
| `compressionQuality` | `0.9` | JPEG quality (0–1) |
| `outputType` | `.jpeg` | `.jpeg` or `.png` |
| `cropImageCircular` | `false` | When true with a circle crop, exports a PNG with transparent corners (forces `outputType` to `.png`) |

### `ProfileAvatarConfiguration`

Avatar rendering surface:

| Property | Default | Description |
|---|---|---|
| `size` | `80` | Diameter in points |
| `shape` | `.circle` | `.circle` or `.roundedRect(cornerRadius:)` |
| `borderWidth` | `0` | Stroke width |
| `borderColor` | `.clear` | Stroke color |
| `foregroundColor` | `.white` | Initials glyph color (only used when `useDefaultForegroundColor` is `false`) |
| `useDefaultForegroundColor` | `true` | Force initials glyph to white for legibility against the deterministic gradient |
| `fontWeight` | `.semibold` | Font weight for the initials glyph |

## Async Rendering

The editor's "Use Photo" button uses `ProfileImageRenderer.renderEditResultAsync` — the heavy work (CGContext draw + CoreImage filter + image encoding) runs on `Task.detached(priority: .userInitiated)` so the main thread stays responsive for multi-megapixel source images.

Call it directly if you need to export a draft without the editor UI:

```swift
let result = try await ProfileImageRenderer.renderEditResultAsync(
    from: .image(someUIImage),
    editorState: draft.editorState,
    editorConfiguration: .profilePhoto,
    configuration: .profilePhoto
)
```

The synchronous `renderEditResult` remains for callers that are already on a background thread or want direct control over dispatch.

## Demo

There is a package-level demo view:

- [ProfileKitDemoView.swift](Sources/ProfileKit/Examples/ProfileKitDemoView.swift)

It uses generated sample images so the package can be exercised without external assets. Includes live toggles for the editor options (grid, appearance mode, circular export, font weight) so you can see each feature's effect immediately.

## Design Notes

The package currently follows a practical avatar-first architecture:

- decode source image
- normalize orientation
- compute an avatar-focused initial framing
- let the user edit crop/zoom/rotate/flip/adjustments
- export a square (or circular, transparent-corners) avatar-ready image

This keeps host apps simple because they can upload a final avatar artifact rather than teaching every avatar view how to interpret crop metadata.

Longer-term, the package could grow into a richer transformation/persistence story, but the current shape is intentionally focused.

## Testing

Tests live in:

- [Tests/ProfileKitTests](Tests/ProfileKitTests)

Current tests cover:

- initials generation
- PNG decode
- avatar export sizing
- recommended portrait framing bias
- workflow draft creation
- workflow export

Run:

```bash
swift test
```

## Current Status

`0.1.0` is the first tagged release. The API and editor UX will likely keep evolving as it gets integrated into real app surfaces.

## License

MIT. See [LICENSE](LICENSE).
