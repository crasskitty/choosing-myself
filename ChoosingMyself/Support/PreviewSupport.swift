#if DEBUG
import SwiftData
import SwiftUI

enum PreviewSupport {
    static func container() -> ModelContainer {
        do {
            return try ModelContainer(
                for: Journey.self,
                UnsentLetter.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Preview store failed: \(error)")
        }
    }
}

extension View {
    func previewSurface(unlocked: Bool = false) -> some View {
        self
            .environment(PurchaseManager(previewUnlocked: unlocked))
            .modelContainer(PreviewSupport.container())
            .preferredColorScheme(.dark)
    }
}
#endif
