import Foundation

/// One healing line per calendar day, chosen from HealingLines.json.
/// The same date always returns the same line until the file itself changes.
enum HealingCatalog {
    static let fallback: [String] = [
        "you chose yourself. that still counts.",
        "the urge will crest. you do not have to follow it.",
        "silence is a promise you kept today.",
        "missing them is not an instruction."
    ]

    struct File: Decodable {
        let lines: [String]
    }

    static func decode(from data: Data) throws -> [String] {
        let file = try JSONDecoder().decode(File.self, from: data)
        return file.lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func load(bundle: Bundle = .main) -> [String] {
        guard let url = locate(in: bundle),
              let data = try? Data(contentsOf: url),
              let lines = try? decode(from: data),
              !lines.isEmpty
        else {
            #if DEBUG
            print("Choosing Myself: HealingLines.json did not load. Using fallback lines.")
            #endif
            return fallback
        }
        return lines
    }

    static func line(for date: Date, calendar: Calendar = .current) -> String {
        line(for: date, in: load(), calendar: calendar)
    }

    static func line(for date: Date, in lines: [String], calendar: Calendar = .current) -> String {
        let source = lines.isEmpty ? fallback : lines
        return source[index(for: date, count: source.count, calendar: calendar)]
    }

    /// Days since 2001-01-01 in `calendar`, wrapped across the list.
    /// Dates before the anchor still land on a stable index.
    static func index(for date: Date, count: Int, calendar: Calendar = .current) -> Int {
        let safeCount = max(count, 1)
        var parts = DateComponents()
        parts.year = 2001
        parts.month = 1
        parts.day = 1
        let anchor = calendar.date(from: parts) ?? date
        let start = calendar.startOfDay(for: anchor)
        let day = calendar.startOfDay(for: date)
        let delta = calendar.dateComponents([.day], from: start, to: day).day ?? 0
        let remainder = delta % safeCount
        return remainder >= 0 ? remainder : remainder + safeCount
    }

    private static func locate(in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: "HealingLines", withExtension: "json") {
            return url
        }
        if let url = bundle.url(forResource: "HealingLines", withExtension: "json", subdirectory: "Shared") {
            return url
        }
        guard let root = bundle.resourceURL else { return nil }
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else { return nil }
        for case let item as URL in enumerator where item.lastPathComponent == "HealingLines.json" {
            return item
        }
        return nil
    }
}
