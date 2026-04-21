import CoreGraphics
import Foundation

public enum ProfileImageSource {
    case data(Data)
    case fileURL(URL)
    case cgImage(CGImage)
    case image(PKPlatformImage)
}
