import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchases

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x10141A), Color(hex: 0x07090C)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(AppIdentity.handle)
                        .font(AppFont.chrome(12, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.42))
                    Text(purchases.isUnlocked ? "This phone is unlocked." : "The rest of the room")
                        .font(AppFont.display(36))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The day counter and today's line stay free. This is everything else, once.")
                        .font(AppFont.prose(17))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        feature("Every mood. Rain, night drive, ocean.")
                        feature("Letters without a limit of three.")
                        feature("A lock on the door. Face ID, or your passcode.")
                        feature("Milestone cards for Stories.")
                        feature("A widget for the Home Screen and the Lock Screen.")
                        feature("If you slip, your best streak stays.")
                    }
                    .padding(.top, 4)

                    if purchases.isUnlocked {
                        QuietButton(title: "Done") { dismiss() }
                            .padding(.top, 8)
                    } else {
                        QuietButton(title: buttonTitle, enabled: !purchases.isLoading) {
                            Task { await buy() }
                        }
                        .padding(.top, 8)
                        QuietButton(title: "Restore purchases", kind: .text) {
                            Task { await purchases.restore() }
                        }
                        QuietButton(title: "Not now", kind: .text) {
                            dismiss()
                        }
                    }

                    if let message = purchases.lastMessage {
                        Text(message)
                            .font(AppFont.chrome(13))
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("One payment through Apple. No subscription.")
                        .font(AppFont.chrome(12))
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(.top, 4)
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x07090C))
        .task {
            purchases.clearMessage()
            await purchases.reload()
        }
    }

    private var buttonTitle: String {
        if purchases.isLoading { return "Loading…" }
        if let price = purchases.product?.displayPrice {
            return "Unlock · \(price)"
        }
        return "Unlock"
    }

    private func feature(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("·")
                .font(AppFont.prose(18))
                .foregroundStyle(.white.opacity(0.45))
            Text(text)
                .font(AppFont.prose(17))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func buy() async {
        if purchases.product == nil {
            await purchases.reload()
        }
        guard purchases.product != nil else { return }
        await purchases.purchase()
        if purchases.isUnlocked {
            dismiss()
        }
    }
}
