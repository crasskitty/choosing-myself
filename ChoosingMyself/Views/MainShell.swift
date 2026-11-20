import SwiftUI

enum AppTab: Hashable {
    case home
    case letters
    case milestones
    case settings

    var title: String {
        switch self {
        case .home: "Home"
        case .letters: "Letters"
        case .milestones: "Milestones"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "moon.stars"
        case .letters: "envelope"
        case .milestones: "seal"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct MainShell: View {
    let journey: Journey
    @Environment(PurchaseManager.self) private var purchases
    @State private var tab: AppTab = .home

    private var theme: MoodTheme {
        journey.effectiveTheme(isUnlocked: purchases.isUnlocked)
    }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: true)
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .home:
                        HomeView(journey: journey)
                    case .letters:
                        LettersView()
                    case .milestones:
                        MilestonesView(journey: journey)
                    case .settings:
                        SettingsView(journey: journey)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
        }
        .animation(.easeInOut(duration: 0.45), value: theme)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach([AppTab.home, .letters, .milestones, .settings], id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 16, weight: tab == item ? .semibold : .regular))
                        Text(item.title)
                            .font(AppFont.chrome(10, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(tab == item ? 0.95 : 0.38))
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background {
            LinearGradient(
                colors: [.black.opacity(0.02), .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
        .sensoryFeedback(.selection, trigger: tab)
    }
}
