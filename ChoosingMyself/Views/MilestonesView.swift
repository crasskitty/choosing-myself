import SwiftUI

struct MilestonesView: View {
    let journey: Journey

    @Environment(PurchaseManager.self) private var purchases
    @State private var share: MilestoneShare?
    @State private var showPaywall = false

    private var days: Int {
        StreakMath.dayCount(from: journey.startDate)
    }

    private var theme: MoodTheme {
        journey.effectiveTheme(isUnlocked: purchases.isUnlocked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(
                    eyebrow: "kept",
                    title: "Milestones",
                    subtitle: subtitle
                )
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(AppIdentity.milestones.enumerated()), id: \.element) { index, milestone in
                        row(
                            milestone,
                            isLast: index == AppIdentity.milestones.count - 1
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $share) { item in
            SharePreviewSheet(
                days: item.days,
                line: HealingCatalog.line(for: .now),
                theme: theme
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var subtitle: String {
        if let next = StreakMath.nextMilestone(after: days) {
            let remaining = next - days
            return "Day \(days). \(remaining) \(AppFormat.unit(for: remaining)) until \(next)."
        }
        return "Day \(days). A year, and the days after."
    }

    private func row(_ milestone: Int, isLast: Bool) -> some View {
        let earned = days >= milestone
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(earned ? Color.white.opacity(0.92) : Color.clear)
                    .overlay(Circle().stroke(Color.white.opacity(earned ? 0.92 : 0.28), lineWidth: 1.5))
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 1)
                        .frame(minHeight: 64)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("\(milestone) \(AppFormat.unit(for: milestone))")
                    .font(AppFont.prose(22))
                    .foregroundStyle(.white.opacity(earned ? 0.96 : 0.4))
                Text(caption(milestone))
                    .font(AppFont.chrome(14))
                    .foregroundStyle(.white.opacity(earned ? 0.62 : 0.32))
                    .fixedSize(horizontal: false, vertical: true)
                if earned {
                    Button(purchases.isUnlocked ? "Share card" : "Unlock to share") {
                        if purchases.isUnlocked {
                            share = MilestoneShare(days: milestone)
                        } else {
                            showPaywall = true
                        }
                    }
                    .font(AppFont.chrome(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.top, 4)
                } else {
                    Text("\(milestone - days) to go")
                        .font(AppFont.chrome(13))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.bottom, 22)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func caption(_ milestone: Int) -> String {
        switch milestone {
        case 7: "A week of keeping your word."
        case 30: "A month of choosing yourself."
        case 60: "Two months on your side of the quiet."
        case 90: "A season of not going back."
        case 365: "A year. You stayed."
        default: "A mark worth keeping."
        }
    }
}
