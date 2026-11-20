import Foundation
import SwiftData

@Model
final class Journey {
    var startDate: Date
    var nickname: String
    var themeID: String
    var ownedThemeID: String
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var faceIDEnabled: Bool
    var bestStreakDays: Int
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(
        startDate: Date,
        nickname: String,
        themeID: String,
        ownedThemeID: String,
        remindersEnabled: Bool = false,
        reminderHour: Int = 21,
        reminderMinute: Int = 0,
        faceIDEnabled: Bool = false,
        bestStreakDays: Int = 1,
        hasCompletedOnboarding: Bool = true,
        createdAt: Date = .now
    ) {
        self.startDate = startDate
        self.nickname = nickname
        self.themeID = themeID
        self.ownedThemeID = ownedThemeID
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.faceIDEnabled = faceIDEnabled
        self.bestStreakDays = max(bestStreakDays, StreakMath.dayCount(from: startDate))
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }

    var personReference: String {
        Nickname.reference(from: nickname)
    }

    func effectiveTheme(isUnlocked: Bool) -> MoodTheme {
        MoodTheme.resolve(isUnlocked ? themeID : ownedThemeID)
    }
}

enum Nickname {
    static func clean(_ raw: String) -> String {
        let collapsed = raw
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(collapsed.prefix(24))
    }

    static func reference(from raw: String) -> String {
        let cleaned = clean(raw)
        return cleaned.isEmpty ? "them" : cleaned
    }
}
