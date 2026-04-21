import SwiftUI

public struct InitialsAvatarView: View {
    public let identity: ProfileIdentity
    public let configuration: ProfileAvatarConfiguration

    public init(
        identity: ProfileIdentity,
        configuration: ProfileAvatarConfiguration = .init()
    ) {
        self.identity = identity
        self.configuration = configuration
    }

    public var body: some View {
        let colors = ProfileAvatarPalette.colors(for: identity.resolvedSeed)

        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(identity.initials)
                .font(.system(
                    size: configuration.size * 0.38,
                    weight: configuration.fontWeight.fontWeight,
                    design: configuration.fontDesign.fontDesign
                ))
                .foregroundStyle(configuration.resolvedForegroundColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: configuration.size, height: configuration.size)
        .clipShape(ProfileAvatarClipShape(shape: configuration.shape))
        .overlay(
            ProfileAvatarClipShape(shape: configuration.shape)
                .inset(by: configuration.borderWidth / 2)
                .stroke(configuration.borderColor.color, lineWidth: configuration.borderWidth)
        )
        .accessibilityLabel(identity.displayName.isEmpty ? identity.initials : identity.displayName)
    }
}
