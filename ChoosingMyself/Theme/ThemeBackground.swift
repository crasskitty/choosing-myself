import SwiftUI

struct ThemeBackground: View {
    var theme: MoodTheme
    var animated: Bool = true
    var extendsIntoSafeArea: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [theme.glow.opacity(0.20), .clear],
                center: glowCenter,
                startRadius: 10,
                endRadius: 460
            )
            if animated && !reduceMotion {
                ThemeMotion(theme: theme)
            } else {
                ThemeStill(theme: theme)
            }
            LinearGradient(
                colors: [.black.opacity(0.28), .clear, .black.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .modifier(SafeAreaFill(enabled: extendsIntoSafeArea))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(.easeInOut(duration: 0.55), value: theme)
    }

    private var glowCenter: UnitPoint {
        switch theme {
        case .rain:
            UnitPoint(x: 0.5, y: 0.08)
        case .nightDrive:
            UnitPoint(x: 0.82, y: 0.82)
        case .ocean:
            UnitPoint(x: 0.45, y: 0.78)
        }
    }
}

private struct SafeAreaFill: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.ignoresSafeArea()
        } else {
            content
        }
    }
}

private struct ThemeMotion: View {
    var theme: MoodTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                draw(theme, in: context, size: size, time: time)
            }
        }
    }
}

private struct ThemeStill: View {
    var theme: MoodTheme

    var body: some View {
        Canvas { context, size in
            draw(theme, in: context, size: size, time: 12)
        }
    }
}

private func draw(_ theme: MoodTheme, in context: GraphicsContext, size: CGSize, time: TimeInterval) {
    switch theme {
    case .rain:
        drawRain(in: context, size: size, time: time)
    case .nightDrive:
        drawDrive(in: context, size: size, time: time)
    case .ocean:
        drawOcean(in: context, size: size, time: time)
    }
}

private func drawRain(in context: GraphicsContext, size: CGSize, time: TimeInterval) {
    let width = Double(size.width)
    let height = Double(size.height)
    for index in 0..<42 {
        let n = Double(index)
        let x = FieldNoise.unit(n * 1.7) * width
        let length = 12 + FieldNoise.unit(n * 2.3) * 22
        let speed = 70 + FieldNoise.unit(n * 3.1) * 90
        let span = height + length
        let drift = (time * speed + n * 90).truncatingRemainder(dividingBy: span)
        let y = drift - length
        var path = Path()
        path.move(to: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        path.addLine(to: CGPoint(x: CGFloat(x + 0.6), y: CGFloat(y + length)))
        let alpha = 0.08 + FieldNoise.unit(n * 4.4) * 0.16
        context.stroke(path, with: .color(.white.opacity(alpha)), lineWidth: 1)
    }
}

private func drawDrive(in context: GraphicsContext, size: CGSize, time: TimeInterval) {
    let canvasWidth = Double(size.width)
    let canvasHeight = Double(size.height)
    for index in 0..<14 {
        let n = Double(index)
        let y = 40 + FieldNoise.unit(n * 2.2) * (canvasHeight - 80)
        let width = 40 + FieldNoise.unit(n * 5.5) * min(180, canvasWidth * 0.35)
        let speed = 24 + FieldNoise.unit(n * 1.3) * 40
        let travel = (time * speed + FieldNoise.unit(n * 8.2) * canvasWidth)
            .truncatingRemainder(dividingBy: canvasWidth + width)
        let x = travel - width
        let rect = CGRect(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: index.isMultiple(of: 3) ? 1.4 : 2.2
        )
        let color = index.isMultiple(of: 2)
            ? Color(hex: 0xE2B07A).opacity(0.18)
            : Color.white.opacity(0.08)
        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
    }
}

private func drawOcean(in context: GraphicsContext, size: CGSize, time: TimeInterval) {
    let canvasWidth = Double(size.width)
    let canvasHeight = Double(size.height)
    for wave in 0..<4 {
        var path = Path()
        let base = canvasHeight * (0.58 + Double(wave) * 0.09)
        let amplitude = 8 + Double(wave) * 4
        let step = max(8, canvasWidth / 48)
        var x = 0.0
        var started = false
        while x <= canvasWidth {
            let phase = (x / max(canvasWidth, 1)) * .pi * 2
            let y = base + sin(phase + time * 0.35 + Double(wave)) * amplitude
            let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
            x += step
        }
        context.stroke(
            path,
            with: .color(Color(hex: 0x9FDED6).opacity(0.10 + Double(wave) * 0.03)),
            lineWidth: 1.4
        )
    }
}

private enum FieldNoise {
    static func unit(_ n: Double) -> Double {
        let value = sin(n * 12.9898) * 43758.5453
        return value - floor(value)
    }
}
