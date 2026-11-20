import Foundation

/// Identifiers that must stay in step with Xcode, the App Group, and App Store Connect.
/// The README lists every file to touch if one of them changes.
enum AppIdentity {
    /// Shared by the app and the widget. Must match both entitlements files.
    static let appGroupID = "group.com.choosingmyself.shared"

    /// Non-consumable unlock. Must match Products.storekit and the App Store Connect product.
    /// The intended price is $4.99. The paywall shows the live StoreKit price, not this note.
    static let unlockProductID = "com.choosingmyself.unlock"

    static let handle = "choosing.myself"
    static let freeLetterLimit = 3
    static let milestones = [7, 30, 60, 90, 365]

    static func canSaveAnotherLetter(existingCount: Int, isUnlocked: Bool) -> Bool {
        isUnlocked || existingCount < freeLetterLimit
    }
}
