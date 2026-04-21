import SwiftUI

/// Four-line rule-of-thirds grid rendered edge-to-edge over its
/// parent frame. Intended as a clipped overlay on top of the crop
/// canvas — NOT a stored transform on the image.
///
/// Kept minimal on purpose: two thin horizontal and two thin vertical
/// lines, subtle white with light alpha so the grid reads over most
/// photo subjects without fighting them.
struct GridOfThirdsOverlay: View {
    var lineColor: Color = .white.opacity(0.35)
    var lineWidth: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let thirdX = size.width / 3
            let thirdY = size.height / 3

            Path { path in
                // Vertical lines at 1/3 and 2/3.
                path.move(to: CGPoint(x: thirdX, y: 0))
                path.addLine(to: CGPoint(x: thirdX, y: size.height))
                path.move(to: CGPoint(x: thirdX * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdX * 2, y: size.height))

                // Horizontal lines at 1/3 and 2/3.
                path.move(to: CGPoint(x: 0, y: thirdY))
                path.addLine(to: CGPoint(x: size.width, y: thirdY))
                path.move(to: CGPoint(x: 0, y: thirdY * 2))
                path.addLine(to: CGPoint(x: size.width, y: thirdY * 2))
            }
            .stroke(lineColor, lineWidth: lineWidth)
        }
    }
}
