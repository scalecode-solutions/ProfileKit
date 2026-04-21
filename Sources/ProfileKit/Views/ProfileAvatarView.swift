import SwiftUI

public struct ProfileAvatarView: View {
    public let image: PKPlatformImage?
    public let identity: ProfileIdentity
    public let configuration: ProfileAvatarConfiguration

    public init(
        image: PKPlatformImage? = nil,
        identity: ProfileIdentity,
        configuration: ProfileAvatarConfiguration = .init()
    ) {
        self.image = image
        self.identity = identity
        self.configuration = configuration
    }

    public var body: some View {
        Group {
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: configuration.size, height: configuration.size)
                    .clipShape(ProfileAvatarClipShape(shape: configuration.shape))
                    .overlay(
                        ProfileAvatarClipShape(shape: configuration.shape)
                            .inset(by: configuration.borderWidth / 2)
                            .stroke(configuration.borderColor.color, lineWidth: configuration.borderWidth)
                    )
                    .accessibilityLabel(identity.displayName.isEmpty ? identity.initials : identity.displayName)
            } else {
                InitialsAvatarView(identity: identity, configuration: configuration)
            }
        }
    }
}
