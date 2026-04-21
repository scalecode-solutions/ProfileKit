import SwiftUI

/// Avatar source passed to `ProfileAvatarView`. Makes the photo-or-
/// initials choice a first-class part of the type system rather than
/// an `image ?? fallback` branch at every call-site.
///
/// - `.image` renders the provided platform image clipped to the
///   configured shape with the configured border.
/// - `.initials` renders via `InitialsAvatarView`; the paired
///   `ProfileInitialsStyle` drives the look, with `.default` matching
///   the pre-V1 fallback visual.
public enum ProfileAvatarContent {
    case image(PKPlatformImage)
    case initials(ProfileIdentity, style: ProfileInitialsStyle = .default)
}

public struct ProfileAvatarView: View {
    public let content: ProfileAvatarContent
    public let configuration: ProfileAvatarConfiguration

    public init(
        content: ProfileAvatarContent,
        configuration: ProfileAvatarConfiguration = .init()
    ) {
        self.content = content
        self.configuration = configuration
    }

    public var body: some View {
        switch content {
        case .image(let image):
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
                // The previous non-enum API labeled avatars with the
                // paired identity's display name. `ProfileAvatarContent.image`
                // doesn't carry an identity, so fall back to a generic
                // label. Hosts wanting a per-user label can wrap the view
                // in their own `.accessibilityLabel(...)`.
                .accessibilityLabel(Text("Profile photo"))

        case .initials(let identity, let style):
            InitialsAvatarView(
                identity: identity,
                style: style,
                configuration: configuration
            )
        }
    }
}
