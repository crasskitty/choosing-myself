import SwiftUI
import WidgetKit

struct ChoosingEntry: TimelineEntry {
    var date: Date
    var dayCount: Int
    var line: String
    var theme: MoodTheme
    var isUnlocked: Bool
    var hasJourney: Bool

    static var sample: ChoosingEntry {
        ChoosingEntry(
            date: .now,
            dayCount: 47,
            line: "the urge will crest. you do not have to follow it.",
            theme: .rain,
            isUnlocked: true,
            hasJourney: true
        )
    }
}

struct ChoosingProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChoosingEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (ChoosingEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        completion(entry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChoosingEntry>) -> Void) {
        let calendar = Calendar.current
        let start = Date()
        var entries: [ChoosingEntry] = [entry(for: start)]
        for offset in 1..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: start)) else {
                continue
            }
            entries.append(entry(for: day))
        }
        let refresh = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start))
            ?? start.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func entry(for date: Date) -> ChoosingEntry {
        let lines = HealingCatalog.load()
        guard let snapshot = SnapshotStore.read() else {
            return ChoosingEntry(
                date: date,
                dayCount: 0,
                line: "Open Choosing Myself",
                theme: .rain,
                isUnlocked: false,
                hasJourney: false
            )
        }
        return ChoosingEntry(
            date: date,
            dayCount: StreakMath.dayCount(from: snapshot.startDate, to: date),
            line: snapshot.isUnlocked ? HealingCatalog.line(for: date, in: lines) : "",
            theme: MoodTheme.resolve(snapshot.effectiveThemeID),
            isUnlocked: snapshot.isUnlocked,
            hasJourney: true
        )
    }
}

struct ChoosingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ChoosingEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                background
            }
    }

    @ViewBuilder
    private var content: some View {
        if entry.hasJourney && entry.isUnlocked {
            unlocked
        } else {
            locked
        }
    }

    @ViewBuilder
    private var locked: some View {
        switch family {
        case .accessoryInline:
            Text(entry.hasJourney ? "Choosing Myself" : "Open Choosing Myself")
        case .accessoryCircular:
            Image(systemName: "lock")
        default:
            placeholder(entry.hasJourney ? "Unlock to keep this here" : "Open Choosing Myself")
        }
    }

    @ViewBuilder
    private var unlocked: some View {
        switch family {
        case .accessoryInline:
            Text("Day \(entry.dayCount)")
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("\(entry.dayCount)")
                    .font(.system(.title3, design: .serif).weight(.light))
                    .widgetAccentable()
                Text(StreakMath.unit(for: entry.dayCount))
                    .font(.system(size: 9, design: .rounded))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(entry.dayCount)")
                    .font(.system(.headline, design: .serif))
                    .widgetAccentable()
                Text(entry.line)
                    .font(.system(.caption, design: .serif))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(entry.dayCount)")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .widgetAccentable()
                    Text(StreakMath.unit(for: entry.dayCount))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text(entry.line)
                    .font(.system(.subheadline, design: .serif))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("\(entry.dayCount)")
                    .font(.system(size: 40, weight: .light, design: .serif))
                    .widgetAccentable()
                Text(StreakMath.unit(for: entry.dayCount))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(entry.line)
                    .font(.system(.caption, design: .serif))
                    .lineLimit(4)
                Spacer(minLength: 0)
                Text(AppIdentity.handle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func placeholder(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "lock")
                .font(.system(size: family == .systemSmall ? 16 : 12, weight: .regular))
            Text(text)
                .font(.system(.caption, design: .serif))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .systemSmall, .systemMedium:
            LinearGradient(colors: entry.theme.colors, startPoint: .top, endPoint: .bottom)
        default:
            AccessoryWidgetBackground()
        }
    }
}

struct ChoosingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.choosingmyself.day", provider: ChoosingProvider()) { entry in
            ChoosingWidgetView(entry: entry)
        }
        .configurationDisplayName("Choosing Myself")
        .description("Your day count and today's line.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct ChoosingMyselfWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChoosingWidget()
    }
}
