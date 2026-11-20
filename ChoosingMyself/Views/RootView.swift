import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\Journey.createdAt, order: .forward)]) private var journeys: [Journey]
    @State private var purchases = PurchaseManager()
    @State private var locked = false
    @State private var didApplyInitialLock = false

    private var journey: Journey? {
        journeys.first { $0.hasCompletedOnboarding } ?? journeys.first
    }

    var body: some View {
        ZStack {
            Color(hex: 0x07090C).ignoresSafeArea()
            if let journey, journey.hasCompletedOnboarding {
                if locked {
                    LockView { locked = false }
                } else {
                    MainShell(journey: journey)
                }
            } else {
                OnboardingView()
            }
        }
        .environment(purchases)
        .tint(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            applyInitialLockIfNeeded()
            syncIfPossible()
            refreshNotifications()
        }
        .onChange(of: scenePhase) { _, phase in
            guard let journey, journey.hasCompletedOnboarding else { return }
            if phase == .background, journey.faceIDEnabled, purchases.isUnlocked {
                locked = true
            }
            if phase == .active {
                syncIfPossible()
                refreshNotifications()
            }
        }
        .onChange(of: purchases.isUnlocked) { _, unlocked in
            guard let journey, journey.hasCompletedOnboarding else { return }
            JourneyRules.sync(journey: journey, isUnlocked: unlocked)
            if !unlocked {
                locked = false
            }
        }
    }

    private func applyInitialLockIfNeeded() {
        guard !didApplyInitialLock else { return }
        didApplyInitialLock = true
        guard let journey, journey.hasCompletedOnboarding else { return }
        if journey.faceIDEnabled, purchases.isUnlocked {
            locked = true
        }
    }

    private func syncIfPossible() {
        guard let journey, journey.hasCompletedOnboarding else { return }
        JourneyRules.sync(journey: journey, isUnlocked: purchases.isUnlocked)
    }

    private func refreshNotifications() {
        guard let journey, journey.hasCompletedOnboarding, journey.remindersEnabled else { return }
        Task {
            await NotificationScheduler.reschedule(
                startDate: journey.startDate,
                hour: journey.reminderHour,
                minute: journey.reminderMinute
            )
        }
    }
}
