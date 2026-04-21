import SwiftUI

struct ProfileAvatarClipShape: InsettableShape {
    let shape: ProfileAvatarShape
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        switch shape {
        case .circle:
            return Circle().path(in: insetRect)
        case .roundedRect(let cornerRadius):
            return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: insetRect)
        }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
