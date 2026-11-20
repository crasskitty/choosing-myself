import SwiftData
import SwiftUI

@main
struct ChoosingMyselfApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Journey.self, UnsentLetter.self])
    }
}
