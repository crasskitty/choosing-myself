import SwiftUI

enum AppFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .serif)
    }

    static func prose(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func chrome(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum AppFormat {
    static func unit(for days: Int) -> String {
        StreakMath.unit(for: days)
    }

    static func since(_ date: Date) -> String {
        let formatted = date.formatted(.dateTime.month(.wide).day().year())
        return "since \(formatted)"
    }
}

struct QuietButton: View {
    enum Kind {
        case solid
        case text
    }

    let title: String
    var kind: Kind = .solid
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(kind == .solid ? AppFont.prose(17) : AppFont.chrome(15))
                .foregroundStyle(kind == .solid ? Color(hex: 0x161412) : Color.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(minHeight: kind == .solid ? 56 : 44)
                .padding(.horizontal, 18)
                .background {
                    if kind == .solid {
                        Capsule().fill(Color.white.opacity(0.94))
                    }
                }
        }
        .buttonStyle(QuietPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
    }
}

struct SettingsBlock<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFont.chrome(12, weight: .medium))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.42))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(AppFont.chrome(12, weight: .medium))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.45))
            Text(title)
                .font(AppFont.display(36))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.prose(17))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct QuietPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.76 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
