import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// Applies a `ProfileImageEffect` to a `CIImage`. Runs before the
/// color-controls pass so brightness / contrast / saturation tune the
/// post-effect output (intuitive: "noir, a bit brighter" reads the way
/// users expect).
///
/// Filter mappings follow Core Image's own presets where possible —
/// `CIPhotoEffect*` for the film looks, `CISepiaTone` / `CIComicEffect`
/// for the named presets. Every filter here ships with iOS / macOS; no
/// third-party deps, no vendored LUTs.
enum EffectsPipeline {
    /// Apply `effect` to `input` and return the resulting `CIImage`.
    /// No-op effects (identity cases on the enum) return `input`
    /// unchanged without constructing a filter.
    ///
    /// Intentionally non-throwing: every CIFilter constructor here is
    /// for a built-in filter that's guaranteed to exist on every
    /// supported platform, and every filter succeeds unconditionally
    /// when fed valid input. If a future case ever reaches for a
    /// platform-gated filter, we'll add a throws variant then.
    static func apply(_ effect: ProfileImageEffect, to input: CIImage) -> CIImage {
        if effect.isIdentity {
            return input
        }

        switch effect {
        case .none:
            return input

        case .mono:
            return photoEffect(name: "CIPhotoEffectMono", input: input)
        case .noir:
            return photoEffect(name: "CIPhotoEffectNoir", input: input)
        case .tonal:
            return photoEffect(name: "CIPhotoEffectTonal", input: input)
        case .chrome:
            return photoEffect(name: "CIPhotoEffectChrome", input: input)
        case .fade:
            return photoEffect(name: "CIPhotoEffectFade", input: input)
        case .instant:
            return photoEffect(name: "CIPhotoEffectInstant", input: input)
        case .process:
            return photoEffect(name: "CIPhotoEffectProcess", input: input)
        case .transfer:
            return photoEffect(name: "CIPhotoEffectTransfer", input: input)

        case .sepia(let intensity):
            let filter = CIFilter.sepiaTone()
            filter.inputImage = input
            // Clamp for safety. Intensity is stored as Double so callers
            // can freely assign slider values; CISepiaTone expects a
            // Float in 0…1.
            filter.intensity = Float(min(max(intensity, 0), 1))
            return filter.outputImage ?? input

        case .comic:
            // CIComicEffect's output extent can exceed the input extent
            // (it samples a 3x3 neighborhood). Crop back to the source
            // extent so downstream rect math — particularly the
            // renderer's context.draw(adjustedImage, in: drawRect) —
            // operates on the image we expect rather than a padded
            // version that shifts the visible content.
            let filter = CIFilter.comicEffect()
            filter.inputImage = input
            return filter.outputImage?.cropped(to: input.extent) ?? input
        }
    }

    /// Thin helper for the parameterless `CIPhotoEffect*` family —
    /// every one of them takes a single `inputImage` key and produces
    /// an output of the same extent. Falling back to `input` keeps the
    /// pipeline non-throwing if a filter ever fails to construct.
    private static func photoEffect(name: String, input: CIImage) -> CIImage {
        guard let filter = CIFilter(name: name) else { return input }
        filter.setValue(input, forKey: kCIInputImageKey)
        return filter.outputImage ?? input
    }
}
