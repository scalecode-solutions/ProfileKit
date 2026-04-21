#if canImport(PhotosUI)
import SwiftUI
import PhotosUI

/// Convenience workflow for turning a SwiftUI `PhotosPickerItem` directly
/// into a `ProfileImageDraft`. Split into its own file so the PhotosUI
/// import lives next to the only code that uses it — earlier in-file
/// compound `canImport` guards evaluated inconsistently in Xcode's
/// downstream SPM builds, leaving `PhotosPickerItem` out of scope even
/// though the guarded block activated.
public extension ProfileImageWorkflow {
    static func makeDraft(
        from item: PhotosPickerItem,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) async throws -> ProfileImageDraft {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw ProfileImageWorkflowError.missingTransferableData
        }

        return try makeDraft(from: .data(data), configuration: configuration)
    }
}
#endif
