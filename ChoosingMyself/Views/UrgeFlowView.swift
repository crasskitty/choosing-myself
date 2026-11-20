import SwiftData
import SwiftUI

/// The urge flow never resets the streak. Breathing, leaving, and locking a letter all keep the count.
struct UrgeFlowView: View {
    let journey: Journey

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: [SortDescriptor(\UnsentLetter.createdAt, order: .reverse)]) private var letters: [UnsentLetter]

    @State private var stage: Stage = .breathe
    @State private var draft = ""
    @State private var showPaywall = false
    @State private var confirmLeave = false
    @State private var savedToken = 0
    @State private var didSave = false

    private enum Stage {
        case breathe
        case write
    }

    private var theme: MoodTheme {
        journey.effectiveTheme(isUnlocked: purchases.isUnlocked)
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var atLetterLimit: Bool {
        !AppIdentity.canSaveAnotherLetter(
            existingCount: letters.count,
            isUnlocked: purchases.isUnlocked
        )
    }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: stage == .breathe)
            Group {
                switch stage {
                case .breathe:
                    BreathingView { stage = .write }
                case .write:
                    composer
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                requestClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.top, 12)
            .accessibilityLabel("Close")
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: savedToken)
        .sheet(isPresented: $showPaywall, onDismiss: {
            if purchases.isUnlocked {
                saveDraft()
            }
        }) {
            PaywallView()
        }
        .confirmationDialog(
            "Leave this unsent?",
            isPresented: $confirmLeave,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Keep writing", role: .cancel) {}
        } message: {
            Text("It won't be saved, and your count stays.")
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("unsent")
                    .font(AppFont.chrome(12, weight: .medium))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.45))
                Text("Say it here.")
                    .font(AppFont.display(34))
                    .foregroundStyle(.white)
                Text(limitCopy)
                    .font(AppFont.prose(16))
                    .foregroundStyle(.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 64)

            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("Write what you would have sent.")
                        .font(AppFont.prose(20))
                        .foregroundStyle(.white.opacity(0.32))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draft)
                    .font(AppFont.prose(20))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Unsent letter")
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            VStack(spacing: 4) {
                QuietButton(
                    title: atLetterLimit ? "Unlock to lock this away" : "Lock it away",
                    enabled: !trimmedDraft.isEmpty
                ) {
                    lockAway()
                }
                QuietButton(title: "Let it go", kind: .text) {
                    requestClose()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .onChange(of: draft) { _, newValue in
            if newValue.count > 12_000 {
                draft = String(newValue.prefix(12_000))
            }
        }
    }

    private var limitCopy: String {
        if purchases.isUnlocked {
            return "It stays on this phone. Nothing sends."
        }
        return "It stays on this phone. Nothing sends. \(letters.count) of \(AppIdentity.freeLetterLimit) letters kept."
    }

    private func lockAway() {
        guard !trimmedDraft.isEmpty else { return }
        if atLetterLimit {
            showPaywall = true
            return
        }
        saveDraft()
    }

    private func saveDraft() {
        let text = trimmedDraft
        guard !didSave, !text.isEmpty else { return }
        guard AppIdentity.canSaveAnotherLetter(
            existingCount: letters.count,
            isUnlocked: purchases.isUnlocked
        ) else { return }
        didSave = true
        modelContext.insert(UnsentLetter(text: text))
        try? modelContext.save()
        draft = ""
        savedToken += 1
        dismiss()
    }

    private func requestClose() {
        if stage == .write, !trimmedDraft.isEmpty {
            confirmLeave = true
        } else {
            dismiss()
        }
    }
}

private struct BreathingView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false
    @State private var phaseIndex = 0

    private let duration: TimeInterval = 60

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1.0 / 30.0, paused: finished)) { context in
            let elapsed = min(duration, max(0, context.date.timeIntervalSince(start)))
            content(elapsed: elapsed)
                .onChange(of: Int(elapsed) / 4) { _, newValue in
                    phaseIndex = newValue
                }
                .onChange(of: elapsed >= duration) { _, done in
                    complete(done)
                }
        }
        .task {
            try? await Task.sleep(for: .seconds(duration))
            complete(true)
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: phaseIndex)
    }

    private func content(elapsed: TimeInterval) -> some View {
        let cycle = elapsed.truncatingRemainder(dividingBy: 12)
        let phase = breathPhase(cycle)
        let scale = breathScale(cycle)
        let remaining = max(0, Int(ceil(duration - elapsed)))

        return VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 10) {
                Text("Stay with this.")
                    .font(AppFont.display(32))
                    .foregroundStyle(.white)
                Text("One minute. Then you can write it.")
                    .font(AppFont.prose(16))
                    .foregroundStyle(.white.opacity(0.62))
            }
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 2)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: elapsed / duration)
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 148, height: 148)
                    .scaleEffect(reduceMotion ? 1 : scale)
                Text(phase)
                    .font(AppFont.prose(22))
                    .italic()
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Breathing guide")
            .accessibilityValue("\(phase). \(remaining) seconds left.")
            Text("\(remaining)")
                .font(AppFont.chrome(14))
                .foregroundStyle(.white.opacity(0.5))
                .monospacedDigit()
            Spacer()
            Button("I need to write now") {
                complete(true)
            }
            .font(AppFont.chrome(14))
            .foregroundStyle(.white.opacity(0.46))
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    private func breathPhase(_ cycle: TimeInterval) -> String {
        if cycle < 4 { return "inhale" }
        if cycle < 8 { return "hold" }
        return "exhale"
    }

    private func breathScale(_ cycle: TimeInterval) -> CGFloat {
        if cycle < 4 {
            return 0.72 + CGFloat(cycle / 4) * 0.28
        }
        if cycle < 8 {
            return 1
        }
        return 1 - CGFloat((cycle - 8) / 4) * 0.28
    }

    private func complete(_ done: Bool) {
        guard done, !finished else { return }
        finished = true
        onFinished()
    }
}
