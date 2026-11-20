import Foundation

/// Day counting for no contact.
/// The start date is day 1. The next local midnight makes it day 2.
enum StreakMath {
    static func unit(for days: Int) -> String {
        days == 1 ? "day" : "days"
    }

    static func dayCount(
        from startDate: Date,
        to date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days + 1)
    }

    /// What the stored best becomes after "I slipped".
    /// Paid keeps the longer of the old record and the run that just ended.
    /// Free keeps only the new run.
    static func bestAfterRestart(
        currentStreak: Int,
        recordedBest: Int,
        restartedDayCount: Int,
        keepsBest: Bool
    ) -> Int {
        if keepsBest {
            return max(recordedBest, currentStreak, restartedDayCount)
        }
        return max(1, restartedDayCount)
    }

    static func latestMilestone(
        for dayCount: Int,
        milestones: [Int] = AppIdentity.milestones
    ) -> Int? {
        milestones.last { dayCount >= $0 }
    }

    static func nextMilestone(
        after dayCount: Int,
        milestones: [Int] = AppIdentity.milestones
    ) -> Int? {
        milestones.first { dayCount < $0 }
    }
}
