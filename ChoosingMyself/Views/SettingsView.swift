import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    let journey: Journey

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(PurchaseManager.self) private var purchases

    @State private var showPaywall = false
    @State private var confirmSlip = false
    @State private var confirmErase = false
    @State private var faceIDMessage: String?
    @State private var notifyStatus: UNAuthorizationStatus = .notDetermined
    @State private var nicknameDraft = ""

    private var theme: MoodTheme {
        journey.effectiveTheme(isUnlocked: purchases.isUnlocked)
    }

    private var currentDays: Int {
        StreakMath.dayCount(from: journey.startDate)
    }

    private var shownBest: Int {
        max(journey.bestStreakDays, currentDays)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ScreenHeader(eyebrow: "this phone", title: "Settings", subtitle: "Nothing here is an account.")

                if !purchases.isUnlocked {
                    Button {
                        showPaywall = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The rest of the room")
                                .font(AppFont.display(24))
                                .foregroundStyle(.white)
                            Text("All moods, unlimited letters, the lock, share cards, and the widget.")
                                .font(AppFont.prose(15))
                                .foregroundStyle(.white.opacity(0.68))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("One-time unlock")
                                .font(AppFont.chrome(13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                SettingsBlock(title: "Mood") {
                    VStack(spacing: 8) {
                        ForEach(MoodTheme.allCases) { item in
                            themeRow(item)
                        }
                    }
                    Text("The mood you picked at the start stays free.")
                        .font(AppFont.chrome(13))
                        .foregroundStyle(.white.opacity(0.42))
                }

                SettingsBlock(title: "Daily line") {
                    Toggle(
                        "Reminder",
                        isOn: Binding(
                            get: { journey.remindersEnabled },
                            set: { enabled in
                                Task { await setReminders(enabled) }
                            }
                        )
                    )
                    .font(AppFont.chrome(16))
                    .tint(.white)
                    if journey.remindersEnabled {
                        DatePicker(
                            "Time",
                            selection: reminderBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .font(AppFont.chrome(16))
                    }
                    if journey.remindersEnabled, notifyStatus == .denied {
                        Button("Notifications are off. Open Settings.") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .font(AppFont.chrome(14))
                        .foregroundStyle(.white.opacity(0.75))
                    }
                    Text("The reminder is today's line, not your letters. It can show on the Lock Screen.")
                        .font(AppFont.chrome(13))
                        .foregroundStyle(.white.opacity(0.42))
                        .fixedSize(horizontal: false, vertical: true)
                }

                SettingsBlock(title: "Privacy") {
                    if purchases.isUnlocked {
                        Toggle(
                            BiometricLock.lockTitle,
                            isOn: Binding(
                                get: { journey.faceIDEnabled },
                                set: { enabled in
                                    Task { await setFaceID(enabled) }
                                }
                            )
                        )
                        .font(AppFont.chrome(16))
                        .tint(.white)
                        Text("Letters stay behind the lock. The widget still shows your day count and today's line.")
                            .font(AppFont.chrome(13))
                            .foregroundStyle(.white.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text(BiometricLock.lockTitle)
                                    .font(AppFont.chrome(16))
                                Spacer()
                                Image(systemName: "lock")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                    if let faceIDMessage {
                        Text(faceIDMessage)
                            .font(AppFont.chrome(13))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Button("Erase everything on this phone", role: .destructive) {
                        confirmErase = true
                    }
                    .font(AppFont.chrome(15))
                    .foregroundStyle(Color(hex: 0xE7B8A8))
                }

                SettingsBlock(title: "The count") {
                    labeled("Now", "Day \(currentDays)")
                    labeled("Best", "\(shownBest) \(AppFormat.unit(for: shownBest))")
                    TextField("What you call them", text: $nicknameDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(AppFont.prose(18))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: nicknameDraft) { _, newValue in
                            let cleaned = Nickname.clean(newValue)
                            if cleaned != newValue {
                                nicknameDraft = cleaned
                            }
                            journey.nickname = cleaned
                            JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
                        }
                    Text(purchases.isUnlocked
                         ? "If you slip, your best stays."
                         : "If you slip, this record starts over. Unlock to keep the best.")
                        .font(AppFont.chrome(13))
                        .foregroundStyle(.white.opacity(0.42))
                        .fixedSize(horizontal: false, vertical: true)
                    Button("I slipped") {
                        confirmSlip = true
                    }
                    .font(AppFont.chrome(16, weight: .medium))
                    .foregroundStyle(Color(hex: 0xE7B8A8))
                }

                SettingsBlock(title: "Purchase") {
                    if purchases.isUnlocked {
                        labeled("Status", "Unlocked")
                    } else {
                        Button("Unlock the rest") {
                            showPaywall = true
                        }
                        .font(AppFont.chrome(16))
                        .foregroundStyle(.white)
                    }
                    Button("Restore purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(AppFont.chrome(16))
                    .foregroundStyle(.white.opacity(0.86))
                    if let message = purchases.lastMessage {
                        Text(message)
                            .font(AppFont.chrome(13))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                SettingsBlock(title: "About") {
                    Text("Choosing Myself is a private counter for no contact. It is not medical care.")
                        .font(AppFont.prose(15))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(AppIdentity.handle)
                        .font(AppFont.chrome(14))
                        .foregroundStyle(.white.opacity(0.5))
                    Button("If you need more than quiet, find local help") {
                        if let url = URL(string: "https://www.iasp.info/suicidalthoughts/") {
                            openURL(url)
                        }
                    }
                    .font(AppFont.chrome(14))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            nicknameDraft = journey.nickname
        }
        .task {
            notifyStatus = await NotificationScheduler.status()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .confirmationDialog("Start today over?", isPresented: $confirmSlip, titleVisibility: .visible) {
            Button("I slipped", role: .destructive) { slip() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(slipMessage)
        }
        .confirmationDialog("Erase everything on this phone?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Erase", role: .destructive) { erase() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your days and letters on this phone will be deleted. An unlock stays with your Apple ID.")
        }
    }

    private var slipMessage: String {
        if purchases.isUnlocked {
            return "Today becomes day 1. Your letters stay. Your best of \(shownBest) \(AppFormat.unit(for: shownBest)) stays."
        }
        return "Today becomes day 1. Your letters stay. The record of this run does not."
    }

    private var reminderBinding: Binding<Date> {
        Binding(
            get: {
                var parts = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                parts.hour = journey.reminderHour
                parts.minute = journey.reminderMinute
                return Calendar.current.date(from: parts) ?? .now
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                journey.reminderHour = parts.hour ?? 21
                journey.reminderMinute = parts.minute ?? 0
                Task { await refreshReminderSchedule() }
            }
        )
    }

    private func themeRow(_ item: MoodTheme) -> some View {
        let selected = theme == item
        let locked = !purchases.isUnlocked && item.rawValue != journey.ownedThemeID
        return Button {
            select(item)
        } label: {
            HStack {
                Image(systemName: item.symbolName)
                    .frame(width: 22)
                Text(item.title)
                    .font(AppFont.chrome(16))
                Spacer()
                if locked {
                    Image(systemName: "lock")
                        .font(.system(size: 12, weight: .semibold))
                } else if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(.white.opacity(locked ? 0.45 : 0.92))
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.chrome(16))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Text(value)
                .font(AppFont.chrome(16))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private func select(_ item: MoodTheme) {
        if purchases.isUnlocked || item.rawValue == journey.ownedThemeID {
            journey.themeID = item.rawValue
            JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
        } else {
            showPaywall = true
        }
    }

    private func setReminders(_ enabled: Bool) async {
        if !enabled {
            journey.remindersEnabled = false
            try? modelContext.save()
            NotificationScheduler.cancel()
            return
        }
        let allowed = await NotificationScheduler.requestAuthorization()
        notifyStatus = await NotificationScheduler.status()
        guard allowed else {
            journey.remindersEnabled = false
            try? modelContext.save()
            return
        }
        journey.remindersEnabled = true
        try? modelContext.save()
        await refreshReminderSchedule()
    }

    private func refreshReminderSchedule() async {
        guard journey.remindersEnabled else { return }
        await NotificationScheduler.reschedule(
            startDate: journey.startDate,
            hour: journey.reminderHour,
            minute: journey.reminderMinute
        )
    }

    private func setFaceID(_ enabled: Bool) async {
        faceIDMessage = nil
        guard purchases.isUnlocked else {
            showPaywall = true
            return
        }
        if let unavailable = BiometricLock.availabilityMessage() {
            faceIDMessage = unavailable
            return
        }
        let reason = enabled ? "Turn on the lock for your letters." : "Turn off the lock."
        let ok = await BiometricLock.authenticate(reason: reason)
        guard ok else { return }
        journey.faceIDEnabled = enabled
        JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
    }

    private func slip() {
        JourneyRules.slip(journey: journey, keepsBest: purchases.isUnlocked)
        JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
        Task { await refreshReminderSchedule() }
    }

    private func erase() {
        try? JourneyRules.erase(context: modelContext)
    }
}
