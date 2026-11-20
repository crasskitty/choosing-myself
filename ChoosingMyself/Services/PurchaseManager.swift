import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    private(set) var isUnlocked = false
    private(set) var product: Product?
    private(set) var isLoading = false
    private(set) var lastMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private let observesTransactions: Bool

    private static let cacheKey = "choosing.purchase.unlocked"

    init(previewUnlocked: Bool? = nil) {
        if let previewUnlocked {
            isUnlocked = previewUnlocked
            observesTransactions = false
            return
        }
        isUnlocked = UserDefaults.standard.bool(forKey: Self.cacheKey)
        observesTransactions = true
        updatesTask = Task { await self.observeTransactions() }
        Task { await self.reload() }
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [AppIdentity.unlockProductID])
            product = products.first
            if product == nil {
                lastMessage = "The unlock isn't available from the App Store yet."
            }
        } catch {
            product = nil
            lastMessage = "The App Store didn't respond. Try again in a moment."
        }
        await refreshEntitlement()
    }

    func purchase() async {
        lastMessage = nil
        guard let product else {
            await reload()
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlement()
            case .userCancelled:
                break
            case .pending:
                lastMessage = "This is waiting for approval."
            @unknown default:
                break
            }
        } catch {
            lastMessage = "That didn't go through. Try again."
        }
    }

    func restore() async {
        lastMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            lastMessage = isUnlocked
                ? "Restored on this phone."
                : "No unlock is tied to this Apple ID yet."
        } catch {
            lastMessage = "Restore didn't finish. Try again."
        }
    }

    func clearMessage() {
        lastMessage = nil
    }

    private func refreshEntitlement() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == AppIdentity.unlockProductID else { continue }
            guard transaction.revocationDate == nil else { continue }
            unlocked = true
        }
        setUnlocked(unlocked)
    }

    private func observeTransactions() async {
        guard observesTransactions else { return }
        for await update in Transaction.updates {
            guard let transaction = try? checkVerified(update) else { continue }
            await transaction.finish()
            await refreshEntitlement()
        }
    }

    private func setUnlocked(_ unlocked: Bool) {
        UserDefaults.standard.set(unlocked, forKey: Self.cacheKey)
        guard isUnlocked != unlocked else { return }
        isUnlocked = unlocked
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
