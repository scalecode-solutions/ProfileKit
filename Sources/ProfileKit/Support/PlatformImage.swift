import CoreGraphics
import CoreImage
import Foundation

#if canImport(UIKit)
import UIKit
public typealias PKPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PKPlatformImage = NSImage
#endif

enum PlatformImageBridge {
    static let ciContext = CIContext(options: nil)

    static func makeImage(from cgImage: CGImage) -> PKPlatformImage {
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #else
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

    static func cgImage(from image: PKPlatformImage) -> CGImage? {
        #if canImport(UIKit)
        if let cgImage = image.cgImage {
            return cgImage
        }

        if let ciImage = image.ciImage {
            let rect = ciImage.extent.integral
            return ciContext.createCGImage(ciImage, from: rect)
        }

        return nil
        #else
        var proposedRect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
        #endif
    }

    static func pixelSize(for image: PKPlatformImage) -> CGSize {
        #if canImport(UIKit)
        let scale = max(image.scale, 1)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
        #else
        return image.size
        #endif
    }
}
