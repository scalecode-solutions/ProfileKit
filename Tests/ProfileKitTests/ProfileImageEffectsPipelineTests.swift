import CoreImage
import CoreGraphics
import Testing
@testable import ProfileKit

struct ProfileImageEffectsPipelineTests {
    @Test func noEffectReturnsInputUnchanged() {
        let input = CIImage(cgImage: TestImageFactory.makeCGImage(width: 16, height: 16))
        let output = EffectsPipeline.apply(.none, to: input)

        // Same object reference — the pipeline short-circuits without
        // constructing a filter.
        #expect(output === input)
    }

    @Test func zeroIntensitySepiaIsNoOp() {
        let input = CIImage(cgImage: TestImageFactory.makeCGImage(width: 16, height: 16))
        let output = EffectsPipeline.apply(.sepia(intensity: 0), to: input)

        // isIdentity short-circuit: sepia at zero intensity returns the
        // input unchanged.
        #expect(output === input)
    }

    @Test func noirProducesDifferentPixels() throws {
        // Use a colored test image so a B&W conversion is visible.
        let cgImage = TestImageFactory.makeCGImage(width: 16, height: 12)
        let input = CIImage(cgImage: cgImage)
        let output = EffectsPipeline.apply(.noir, to: input)

        let context = CIContext()
        guard
            let inputRendered = context.createCGImage(input, from: input.extent),
            let outputRendered = context.createCGImage(output, from: output.extent)
        else {
            Issue.record("CIContext failed to render test images")
            return
        }

        let inputBytes = try cgImageBytes(inputRendered)
        let outputBytes = try cgImageBytes(outputRendered)
        #expect(inputBytes != outputBytes)
    }

    @Test func comicEffectOutputKeepsSourceExtent() {
        // CIComicEffect naturally pads the output extent; the pipeline
        // crops back so downstream rect math doesn't shift.
        let cgImage = TestImageFactory.makeCGImage(width: 32, height: 24)
        let input = CIImage(cgImage: cgImage)
        let output = EffectsPipeline.apply(.comic, to: input)

        #expect(output.extent == input.extent)
    }

    @Test func everyCatalogEntryProducesOutput() throws {
        // Smoke test: every preset in the default catalog produces a
        // CIImage that a CIContext can successfully render. Catches
        // typos in filter names.
        let cgImage = TestImageFactory.makeCGImage(width: 16, height: 16)
        let input = CIImage(cgImage: cgImage)
        let context = CIContext()

        for effect in ProfileImageEffect.defaultCatalog {
            let output = EffectsPipeline.apply(effect, to: input)
            #expect(context.createCGImage(output, from: output.extent) != nil,
                    "\(effect.identifier) produced no renderable output")
        }
    }

    private func cgImageBytes(_ cgImage: CGImage) throws -> Data {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var bytes = Data(count: bytesPerRow * height)

        try bytes.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw CocoaError(.fileReadUnknown)
            }
            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw CocoaError(.fileReadUnknown)
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return bytes
    }
}
