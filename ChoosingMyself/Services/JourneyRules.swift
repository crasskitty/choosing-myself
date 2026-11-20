import Foundation
import SwiftData
import WidgetKit

@MainActor
enum JourneyRules {
    /// Raises the stored best when the current run passes it. Never lowers it.
    /// A slip sets the new best itself, then calls sync.
    static func sync(journey: Journey, isUnlocked: Bool) {
        let current = StreakMath.dayCount(from: journey.startDate)
        if current > journey.bestStreakDays {
            journey.bestStreakDays = current
        }
        if !isUnlocked {
            journey.faceIDEnabled = false
        }
        try? journey.modelContext?.save()
        SnapshotStore.write(
            JourneySnapshot(
                startDate: journey.startDate,
                themeID: journey.themeID,
                ownedThemeID: journey.ownedThemeID,
                isUnlocked: isUnlocked
            )
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func slip(journey: Journey, keepsBest: Bool) {
        let calendar = Calendar.current
        let current = StreakMath.dayCount(from: journey.startDate, calendar: calendar)
        let recorded = journey.bestStreakDays
        journey.startDate = calendar.startOfDay(for: .now)
        let restarted = StreakMath.dayCount(from: journey.startDate, calendar: calendar)
        journey.bestStreakDays = StreakMath.bestAfterRestart(
            currentStreak: current,
            recordedBest: recorded,
            restartedDayCount: restarted,
            keepsBest: keepsBest
        )
    }

    static func erase(context: ModelContext) throws {
        let journeys = try context.fetch(FetchDescriptor<Journey>())
        let letters = try context.fetch(FetchDescriptor<UnsentLetter>())
        journeys.forEach(context.delete)
        letters.forEach(context.delete)
        try context.save()
        SnapshotStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationScheduler.cancel()
        OnboardingDraft.clear()
    }
}
