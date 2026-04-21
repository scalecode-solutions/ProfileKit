# ProfileKit

SwiftUI-first profile image tooling for `iOS 26+`.

`ProfileKit` is built around a specific job: help apps load profile-photo inputs, give users a good avatar editing experience, export a clean square avatar image, and render profile surfaces with a polished initials fallback when no image is available.

It is not trying to be a generic Photoshop-style editor. The package is intentionally focused on profile images and avatars.

## Goals

- SwiftUI-first API
- `iOS 26` target with Swift 6 / SwiftUI 6
- Accept common platform-supported image formats
- Provide a profile-photo editing workflow
- Export avatar-ready square image data
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
  - optional rotation
  - brightness / contrast / saturation
- Avatar export pipeline
- Initials fallback avatar rendering
- Higher-level draft/workflow helpers
- Package demo view

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

- [Sources/ProfileKit/Models](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models)
- [Sources/ProfileKit/Rendering](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Rendering)
- [Sources/ProfileKit/Views](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Views)
- [Sources/ProfileKit/Workflow](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Workflow)
- [Sources/ProfileKit/Examples](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Examples)

Reference repos cloned locally for design inspiration:

- [docs/SwiftyCrop](/Users/travis/GitHub/ProfileKit/docs/SwiftyCrop)
- [docs/Mantis](/Users/travis/GitHub/ProfileKit/docs/Mantis)
- [docs/InitialsUI](/Users/travis/GitHub/ProfileKit/docs/InitialsUI)

## Core Types

### Workflow

- [ProfileImageWorkflow](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Workflow/ProfileImageWorkflow.swift)
- [ProfileImageDraft](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Workflow/ProfileImageDraft.swift)

These are the easiest starting points for host apps.

### Editor

- [ProfileImageEditorScreen](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Views/ProfileImageEditorScreen.swift)
- [ProfileImageEditorView](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Views/ProfileImageEditorView.swift)
- [ProfileImageEditorState](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileImageEditorState.swift)
- [ProfileImageEditorConfiguration](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileImageEditorConfiguration.swift)

### Rendering

- [ProfileImageDecoder](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Rendering/ProfileImageDecoder.swift)
- [ProfileImageRenderer](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Rendering/ProfileImageRenderer.swift)
- [ProfileImageEditResult](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileImageEditResult.swift)

### Avatar Display

- [ProfileAvatarView](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Views/ProfileAvatarView.swift)
- [InitialsAvatarView](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Views/InitialsAvatarView.swift)
- [ProfileIdentity](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileIdentity.swift)
- [ProfileAvatarConfiguration](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileAvatarConfiguration.swift)

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
    configuration: .init(size: 72, shape: .circle)
)
```

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

The main editor tuning surface is [ProfileImageEditorConfiguration.swift](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileImageEditorConfiguration.swift).

Key knobs:

- `cropShape`
- `minimumZoom`
- `maximumZoom`
- `cropPadding`
- `initialZoom`
- `initialVerticalBias`
- `allowsRotation`
- `doubleTapZoomFactor`
- `showsLivePreview`
- `showsAdjustmentControls`
- `renderConfiguration`

Export tuning lives in [ProfileImageRenderConfiguration.swift](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Models/ProfileImageRenderConfiguration.swift).

Key knobs:

- `exportDimension`
- `compressionQuality`
- `outputType`

## Demo

There is a package-level demo view:

- [ProfileKitDemoView.swift](/Users/travis/GitHub/ProfileKit/Sources/ProfileKit/Examples/ProfileKitDemoView.swift)

It uses generated sample images so the package can be exercised without external assets.

## Design Notes

The package currently follows a practical avatar-first architecture:

- decode source image
- normalize orientation
- compute an avatar-focused initial framing
- let the user edit crop/zoom/adjustments
- export a square avatar-ready image

This keeps host apps simple because they can upload a final avatar artifact rather than teaching every avatar view how to interpret crop metadata.

Longer-term, the package could grow into a richer transformation/persistence story, but the current shape is intentionally focused.

## Testing

Tests live in:

- [Tests/ProfileKitTests](/Users/travis/GitHub/ProfileKit/Tests/ProfileKitTests)

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

This package is under active development. The fundamentals are in place, but the API and editor UX will likely keep evolving as it gets integrated into a real app surface.
