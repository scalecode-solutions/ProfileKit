import CoreGraphics
import Foundation

enum ProfileKitDemoSamples {
    static func portraitSample() -> PKPlatformImage {
        makeGradientSample(width: 900, height: 1400)
    }

    static func landscapeSample() -> PKPlatformImage {
        makeGradientSample(width: 1400, height: 900)
    }

    private static func makeGradientSample(width: Int, height: Int) -> PKPlatformImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + (x * 4)
                let xRatio = CGFloat(x) / CGFloat(max(width - 1, 1))
                let yRatio = CGFloat(y) / CGFloat(max(height - 1, 1))

                bytes[index] = UInt8((0.18 + (0.62 * xRatio)) * 255)
                bytes[index + 1] = UInt8((0.24 + (0.46 * yRatio)) * 255)
                bytes[index + 2] = UInt8((0.48 + (0.30 * (1 - xRatio))) * 255)
                bytes[index + 3] = 255
            }
        }

        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!

        return PlatformImageBridge.makeImage(from: cgImage)
    }
}
