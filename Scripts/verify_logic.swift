import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// Compiled with the shared Foundation files:
//   swiftc -o /tmp/choosing-verify Shared/AppIdentity.swift Shared/StreakMath.swift Shared/HealingCatalog.swift Scripts/verify_logic.swift
//   /tmp/choosing-verify

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct VerifyLogic {
    static func main() {
        run()
    }
}

func run() {
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!

func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var parts = DateComponents()
    parts.year = year
    parts.month = month
    parts.day = day
    parts.hour = 15
    return calendar.date(from: parts)!
}

let jan1 = date(2026, 1, 1)
expect(StreakMath.dayCount(from: jan1, to: jan1, calendar: calendar) == 1, "start date is day 1")
expect(StreakMath.dayCount(from: jan1, to: date(2026, 1, 2), calendar: calendar) == 2, "next day is day 2")
expect(StreakMath.dayCount(from: jan1, to: date(2026, 2, 1), calendar: calendar) == 32, "Jan 1 through Feb 1 is 32 days")
expect(StreakMath.dayCount(from: date(2026, 3, 4), to: date(2026, 1, 1), calendar: calendar) == 1, "a future start clamps to day 1")

expect(
    StreakMath.bestAfterRestart(currentStreak: 47, recordedBest: 47, restartedDayCount: 1, keepsBest: true) == 47,
    "paid slip keeps 47"
)
expect(
    StreakMath.bestAfterRestart(currentStreak: 47, recordedBest: 47, restartedDayCount: 1, keepsBest: false) == 1,
    "free slip starts over"
)
expect(
    StreakMath.bestAfterRestart(currentStreak: 50, recordedBest: 40, restartedDayCount: 1, keepsBest: true) == 50,
    "paid slip keeps the longer run"
)
expect(StreakMath.unit(for: 1) == "day", "singular")
expect(StreakMath.unit(for: 2) == "days", "plural")
expect(StreakMath.latestMilestone(for: 6) == nil, "before the first badge")
expect(StreakMath.latestMilestone(for: 7) == 7, "week badge")
expect(StreakMath.latestMilestone(for: 47) == 30, "between 30 and 60")
expect(StreakMath.nextMilestone(after: 47) == 60, "next is 60")
expect(StreakMath.nextMilestone(after: 365) == nil, "nothing after a year")
expect(!AppIdentity.canSaveAnotherLetter(existingCount: 3, isUnlocked: false), "free stops at 3")
expect(AppIdentity.canSaveAnotherLetter(existingCount: 3, isUnlocked: true), "unlock removes the cap")
expect(AppIdentity.canSaveAnotherLetter(existingCount: 2, isUnlocked: false), "the third letter is free")

let anchor = date(2001, 1, 1)
expect(HealingCatalog.index(for: anchor, count: 60, calendar: calendar) == 0, "anchor index")
expect(HealingCatalog.index(for: date(2001, 1, 2), count: 60, calendar: calendar) == 1, "next index")
expect(HealingCatalog.index(for: date(2000, 12, 31), count: 60, calendar: calendar) == 59, "before the anchor wraps")
let first = HealingCatalog.index(for: date(2026, 11, 20), count: 60, calendar: calendar)
let again = HealingCatalog.index(for: date(2026, 11, 20), count: 60, calendar: calendar)
expect(first == again && (0..<60).contains(first), "the index is stable and in range")

let linesURL = URL(fileURLWithPath: "Shared/HealingLines.json")
let lines: [String]
do {
    let data = try Data(contentsOf: linesURL)
    lines = try HealingCatalog.decode(from: data)
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
expect(lines.count == 60, "expected 60 lines, found \(lines.count)")
expect(Set(lines).count == 60, "lines should be unique")
for (index, line) in lines.enumerated() {
    expect(line == line.lowercased(), "line \(index + 1) should stay lowercase")
    expect(line.count <= 90, "line \(index + 1) is too long")
    expect(!line.contains("\""), "line \(index + 1) should not contain quotes")
}
let picked = HealingCatalog.line(for: date(2026, 11, 20), in: lines, calendar: calendar)
expect(lines.contains(picked), "today's line comes from the file")

print("ok \(lines.count) lines, day math, slip rules, and the daily index")
}
