import Foundation

public struct ProfileIdentity: Equatable, Sendable {
    public var displayName: String
    public var initialsOverride: String?
    public var fallbackSeed: String?

    public init(
        displayName: String,
        initialsOverride: String? = nil,
        fallbackSeed: String? = nil
    ) {
        self.displayName = displayName
        self.initialsOverride = initialsOverride
        self.fallbackSeed = fallbackSeed
    }

    public var initials: String {
        if let initialsOverride, !initialsOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return initialsOverride.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }

        return InitialsGenerator.initials(from: displayName)
    }

    public var resolvedSeed: String {
        let trimmedSeed = fallbackSeed?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedSeed, !trimmedSeed.isEmpty {
            return trimmedSeed
        }

        return displayName
    }
}
