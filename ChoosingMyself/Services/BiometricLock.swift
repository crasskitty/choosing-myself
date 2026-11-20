import Foundation
import LocalAuthentication

enum BiometricLock {
    static func availabilityMessage() -> String? {
        var error: NSError?
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return nil
        }
        return "Set a passcode on this phone to use the lock."
    }

    static var lockTitle: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID lock"
        case .touchID:
            return "Touch ID lock"
        default:
            return "Passcode lock"
        }
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Not now"
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
