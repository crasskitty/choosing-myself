import SwiftUI

struct LockView: View {
    var onUnlocked: () -> Void

    @State private var message: String?
    @State private var isAsking = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(AppIdentity.handle)
                .font(AppFont.chrome(13, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.45))
            Text("This phone is locked.")
                .font(AppFont.display(32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(AppFont.prose(16))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            QuietButton(title: "Unlock", enabled: !isAsking) {
                Task { await unlock() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x07090C).ignoresSafeArea())
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            await unlock()
        }
    }

    private func unlock() async {
        guard !isAsking else { return }
        if let unavailable = BiometricLock.availabilityMessage() {
            message = unavailable
            return
        }
        isAsking = true
        let ok = await BiometricLock.authenticate(reason: "Unlock your letters and your days.")
        isAsking = false
        if ok {
            onUnlocked()
        } else if message == nil {
            message = "Whenever you're ready."
        }
    }
}
