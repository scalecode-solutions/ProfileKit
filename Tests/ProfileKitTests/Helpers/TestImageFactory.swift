import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum TestImageFactory {
    static func makeCGImage(width: Int = 16, height: Int = 12) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + (x * 4)
                data[index] = UInt8((x * 255) / max(width - 1, 1))
                data[index + 1] = UInt8((y * 255) / max(height - 1, 1))
                data[index + 2] = 180
                data[index + 3] = 255
            }
        }

        let provider = CGDataProvider(data: Data(data) as CFData)!
        return CGImage(
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
    }

    static func makePNGData(width: Int = 16, height: Int = 12) throws -> Data {
        let cgImage = makeCGImage(width: width, height: height)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw TestFailure.failedToCreateDestination
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw TestFailure.failedToEncodeImage
        }
        return data as Data
    }

    enum TestFailure: Error {
        case failedToCreateDestination
        case failedToEncodeImage
    }
}
