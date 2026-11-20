import Foundation
import UserNotifications

@MainActor
enum NotificationScheduler {
    private static let prefix = "choosing.line."

    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let existing = await center.notificationSettings().authorizationStatus
        switch existing {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Schedules the next two weeks. Each day carries that day's line, so this
    /// is not one repeating notification.
    static func reschedule(startDate: Date, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        let lines = HealingCatalog.load()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            var parts = calendar.dateComponents([.year, .month, .day], from: day)
            parts.hour = hour
            parts.minute = minute
            guard let fireDate = calendar.date(from: parts), fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Day \(StreakMath.dayCount(from: startDate, to: day, calendar: calendar))"
            content.body = HealingCatalog.line(for: day, in: lines, calendar: calendar)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let stamp = dayStamp(day, calendar: calendar)
            let request = UNNotificationRequest(
                identifier: prefix + stamp,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private static func dayStamp(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
