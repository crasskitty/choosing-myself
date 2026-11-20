import SwiftUI

enum MoodTheme: String, Codable, CaseIterable, Identifiable {
    case rain
    case nightDrive
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rain: "Rain"
        case .nightDrive: "Night Drive"
        case .ocean: "Ocean"
        }
    }

    var caption: String {
        switch self {
        case .rain: "Glass, weather, a still room."
        case .nightDrive: "Amber lights on a long road."
        case .ocean: "Dark water, a slow tide."
        }
    }

    var symbolName: String {
        switch self {
        case .rain: "cloud.rain"
        case .nightDrive: "car.fill"
        case .ocean: "water.waves"
        }
    }

    /// All stops stay dark enough for white text.
    var colors: [Color] {
        switch self {
        case .rain:
            [
                Color(hex: 0x070B10),
                Color(hex: 0x101820),
                Color(hex: 0x1A3144),
                Color(hex: 0x0C141C)
            ]
        case .nightDrive:
            [
                Color(hex: 0x070605),
                Color(hex: 0x120E0B),
                Color(hex: 0x1C140E),
                Color(hex: 0x0A0908)
            ]
        case .ocean:
            [
                Color(hex: 0x041016),
                Color(hex: 0x06242E),
                Color(hex: 0x0C3A44),
                Color(hex: 0x07161C)
            ]
        }
    }

    var glow: Color {
        switch self {
        case .rain: Color(hex: 0x8FB4D4)
        case .nightDrive: Color(hex: 0xE2B07A)
        case .ocean: Color(hex: 0x7FCFC8)
        }
    }

    static func resolve(_ raw: String?) -> MoodTheme {
        guard let raw, let theme = MoodTheme(rawValue: raw) else { return .rain }
        return theme
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
