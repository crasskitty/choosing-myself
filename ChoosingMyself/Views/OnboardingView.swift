import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchases

    @State private var page = 0
    @AppStorage(OnboardingDraft.nickname) private var nickname = ""
    @AppStorage(OnboardingDraft.theme) private var themeID = MoodTheme.rain.rawValue
    @AppStorage(OnboardingDraft.start) private var startStamp: Double = 0
    @State private var didFinish = false

    private var theme: MoodTheme {
        MoodTheme.resolve(themeID)
    }

    private var startDate: Date {
        startStamp > 0 ? Date(timeIntervalSince1970: startStamp) : Date()
    }

    private var dateRange: ClosedRange<Date> {
        let earliest = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
        return earliest...Date()
    }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: true)
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    quietStart.tag(1)
                    mood.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                QuietButton(title: page < 2 ? "Continue" : "Begin") {
                    advance()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            if startStamp == 0 {
                startStamp = Date().timeIntervalSince1970
            }
        }
        .sensoryFeedback(.selection, trigger: page)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text(AppIdentity.handle)
                .font(AppFont.chrome(13, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.5))
            Text("You chose yourself.")
                .font(AppFont.display(46))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("A private count of the days. A place for the message you don't send. Nothing here leaves this phone.")
                .font(AppFont.prose(20))
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    private var quietStart: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("When did the quiet start?")
                    .font(AppFont.display(34))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                DatePicker(
                    "No contact started",
                    selection: startBinding,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.white)
                Text("What do you call them?")
                    .font(AppFont.chrome(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                TextField("him", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .font(AppFont.prose(20))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .onChange(of: nickname) { _, newValue in
                        let cleaned = Nickname.clean(newValue)
                        if cleaned != newValue {
                            nickname = cleaned
                        }
                    }
                Text("Optional. Only so the button can say “I want to text him.” It stays on this phone.")
                    .font(AppFont.prose(15))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var mood: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where should this feel like?")
                .font(AppFont.display(34))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)
            Text("You can keep this one. The others wait with the unlock.")
                .font(AppFont.prose(16))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
            ForEach(MoodTheme.allCases) { item in
                Button {
                    themeID = item.rawValue
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: item.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                            .overlay(
                                Image(systemName: item.symbolName)
                                    .foregroundStyle(.white.opacity(0.85))
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(AppFont.prose(18))
                                .foregroundStyle(.white)
                            Text(item.caption)
                                .font(AppFont.chrome(13))
                                .foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        if theme == item {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(theme == item ? 0.08 : 0.03), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(theme == item ? 0.7 : 0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(theme == item ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .sensoryFeedback(.selection, trigger: themeID)
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { min(startDate, Date()) },
            set: { newValue in
                startStamp = min(newValue, Date()).timeIntervalSince1970
            }
        )
    }

    private func advance() {
        if page < 2 {
            page += 1
            return
        }
        finish()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        let chosen = theme.rawValue
        let journey = Journey(
            startDate: Calendar.current.startOfDay(for: min(startDate, Date())),
            nickname: Nickname.clean(nickname),
            themeID: chosen,
            ownedThemeID: chosen
        )
        modelContext.insert(journey)
        try? modelContext.save()
        JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
        OnboardingDraft.clear()
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .previewSurface()
}
#endif
