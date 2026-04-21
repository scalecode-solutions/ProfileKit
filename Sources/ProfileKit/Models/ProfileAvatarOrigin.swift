import Foundation

/// Captures which source produced a `ProfileImageEditResult` — the
/// photo editing path or the designed-initials path — along with the
/// full state needed to re-open the result for further editing.
///
/// Stored on the result itself (as `ProfileImageEditResult.origin`)
/// so host apps that persist only the result can later drive
/// `ProfileImageWorkflow.reopen(result:)` and land back in the right
/// editor with the right state restored.
public enum ProfileAvatarOrigin: Sendable, Codable, Hashable {
    case photo(ProfileImageEditorState)
    case initials(identity: ProfileIdentity, style: ProfileInitialsStyle)

    /// Convenience accessor for the photo editor state — returns nil
    /// for initials-origin results. Callers that know they're working
    /// with a photo-origin result use this to pull the state for a
    /// re-edit without pattern-matching the enum.
    public var photoState: ProfileImageEditorState? {
        if case .photo(let state) = self { return state }
        return nil
    }

    /// Convenience accessor for the initials style — nil for photo
    /// origins. Same rationale as `photoState`.
    public var initialsStyle: ProfileInitialsStyle? {
        if case .initials(_, let style) = self { return style }
        return nil
    }

    /// Convenience accessor for the identity on an initials origin —
    /// nil on photo. Hosts that drove a photo edit already have the
    /// identity elsewhere in their app state.
    public var initialsIdentity: ProfileIdentity? {
        if case .initials(let identity, _) = self { return identity }
        return nil
    }
}

