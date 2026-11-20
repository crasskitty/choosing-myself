import Foundation

/// What the widget is allowed to know.
/// Unsent letters are never stored here.
struct JourneySnapshot: Codable, Equatable {
    var startDate: Date
    var themeID: String
    var ownedThemeID: String
    var isUnlocked: Bool

    static let storageKey = "journey.snapshot.v1"

    var effectiveThemeID: String {
        isUnlocked ? themeID : ownedThemeID
    }
}
