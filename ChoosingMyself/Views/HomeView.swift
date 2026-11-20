import SwiftUI

struct HomeView: View {
    let journey: Journey
    @Environment(PurchaseManager.self) private var purchases
    @State private var showUrge = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            home(at: context.date)
        }
        .fullScreenCover(isPresented: $showUrge) {
            UrgeFlowView(journey: journey)
        }
    }

    private func home(at date: Date) -> some View {
        let days = StreakMath.dayCount(from: journey.startDate, to: date)
        let line = HealingCatalog.line(for: date)
        let showsBest = purchases.isUnlocked && journey.bestStreakDays > days
        return GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Text(AppIdentity.handle)
                        .font(AppFont.chrome(12, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.42))
                        .padding(.top, 18)

                    Spacer(minLength: 28)

                    VStack(spacing: 6) {
                        Text("\(days)")
                            .font(AppFont.display(104))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                        Text("\(AppFormat.unit(for: days)) of choosing yourself")
                            .font(AppFont.prose(18))
                            .foregroundStyle(.white.opacity(0.78))
                        Text(AppFormat.since(journey.startDate))
                            .font(AppFont.chrome(14))
                            .foregroundStyle(.white.opacity(0.48))
                        if showsBest {
                            Text("best \(journey.bestStreakDays)")
                                .font(AppFont.chrome(13))
                                .foregroundStyle(.white.opacity(0.42))
                                .padding(.top, 4)
                        }
                        if AppIdentity.milestones.contains(days) {
                            Text("Today marks \(days) \(AppFormat.unit(for: days)).")
                                .font(AppFont.prose(15))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityLabel(days: days))

                    Spacer(minLength: 32)

                    VStack(spacing: 12) {
                        Text("today")
                            .font(AppFont.chrome(12, weight: .medium))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.4))
                        Text(line)
                            .font(AppFont.prose(22))
                            .foregroundStyle(.white.opacity(0.94))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 440)
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 32)

                    VStack(spacing: 12) {
                        QuietButton(title: urgeTitle) {
                            showUrge = true
                        }
                        Text("The count stays. Nothing sends.")
                            .font(AppFont.chrome(12))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var urgeTitle: String {
        let name = journey.personReference
        if name.hasSuffix(".") {
            return "I want to text \(name)"
        }
        return "I want to text \(name)."
    }

    private func accessibilityLabel(days: Int) -> String {
        var label = "Day \(days) of choosing yourself. \(AppFormat.since(journey.startDate))."
        if AppIdentity.milestones.contains(days) {
            label += " Today marks \(days) \(AppFormat.unit(for: days))."
        }
        return label
    }
}
