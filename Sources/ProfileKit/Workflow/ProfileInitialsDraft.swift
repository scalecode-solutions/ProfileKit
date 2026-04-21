import Foundation

/// Editable handle for a designed-initials avatar. The initials-path
/// analogue of `ProfileImageDraft` on the photo path: carries the
/// identity (for default-glyph derivation and deterministic-palette
/// seeding) plus the mutable style.
///
/// Mutable on `style` so the editor view mutates in place via a
/// `Binding`; immutable on `identity` because changing the identity
/// mid-edit would break the user's mental model (palette seed shifts,
/// default initials change). Hosts that want to swap identities
/// should build a fresh draft.
public struct ProfileInitialsDraft: Equatable, Hashable, Sendable, Codable {
    public let identity: ProfileIdentity
    public var style: ProfileInitialsStyle

    public init(
        identity: ProfileIdentity,
        style: ProfileInitialsStyle = .default
    ) {
        self.identity = identity
        self.style = style
    }
}
