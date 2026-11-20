import Foundation

enum OnboardingDraft {
    static let nickname = "onboarding.nickname"
    static let theme = "onboarding.theme"
    static let start = "onboarding.start"

    static func clear() {
        let defaults = UserDefaults.standard
        [nickname, theme, start].forEach { defaults.removeObject(forKey: $0) }
    }
}
