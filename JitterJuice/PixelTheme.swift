import AppKit
import CoreText
import SwiftUI

enum PixelTheme {
    /// PostScript name from the bundled TTF (see font metadata).
    static let fontName = "PressStart2P-Regular"

    static let backgroundDeep = Color(red: 0.14, green: 0.07, blue: 0.26)
    static let backgroundPanel = Color(red: 0.22, green: 0.11, blue: 0.40)
    static let accentYellow = Color(red: 1.0, green: 0.92, blue: 0.22)
    static let accentGold = Color(red: 0.96, green: 0.78, blue: 0.18)
    static let textMuted = Color(red: 0.82, green: 0.70, blue: 0.35)

    static func registerBundledFonts() {
        let candidates = ["PressStart2P-Regular", "PressStart2P"]
        for base in candidates {
            if let url = Bundle.main.url(forResource: base, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                return
            }
        }
    }

    static func font(size: CGFloat) -> Font {
        .custom(fontName, size: size)
    }

    static func nsFont(size: CGFloat) -> NSFont {
        NSFont(name: fontName, size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
    }

    /// Tiny “?” badge for help (NSButton); glyph centered in the box.
    static func helpBadgeNSImage(side: CGFloat, palette: ThemePalette) -> NSImage {
        let img = NSImage(size: NSSize(width: side, height: side))
        img.lockFocus()
        defer { img.unlockFocus() }

        let fill = NSColor(palette.helpBadgeFill)
        let strokeCol = NSColor(palette.helpBadgeStroke)
        let glyphCol = NSColor(palette.helpGlyph)

        let inset: CGFloat = 1
        let r = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
        fill.setFill()
        NSBezierPath(rect: r).fill()
        strokeCol.setStroke()
        let border = NSBezierPath(rect: r)
        border.lineWidth = 2
        border.stroke()

        let str = "?" as NSString
        let font: NSFont = palette.usePixelFont
            ? nsFont(size: max(6, side * 0.38))
            : .systemFont(ofSize: max(9, side * 0.45), weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: glyphCol,
        ]
        let opts: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let pad = str.boundingRect(with: NSSize(width: side - 6, height: side - 6), options: opts, attributes: attrs)
        let inner = NSRect(x: 0, y: 0, width: side, height: side).insetBy(dx: 3, dy: 3)
        let drawRect = NSRect(
            x: inner.midX - pad.width / 2,
            y: inner.midY - pad.height / 2,
            width: pad.width,
            height: pad.height
        )
        str.draw(with: drawRect, options: opts, attributes: attrs, context: nil)
        return img
    }
}

// MARK: - Lightning toggle + sparkle burst (pixel stars, side-biased)

/// Chunky plus made of square “pixels” (retro sprite style).
private struct PixelPlusStar: View {
    var color: Color
    private let cell: CGFloat = 2

    var body: some View {
        Canvas { context, _ in
            let cells: [(Int, Int)] = [
                (2, 0), (2, 1),
                (0, 2), (1, 2), (2, 2), (3, 2), (4, 2),
                (2, 3), (2, 4),
            ]
            for (x, y) in cells {
                let r = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                context.fill(Path(r), with: .color(color))
            }
        }
        .frame(width: 5 * cell, height: 5 * cell)
    }
}

private struct PixelDiamondStar: View {
    var color: Color
    private let cell: CGFloat = 2

    var body: some View {
        Canvas { context, _ in
            let cells: [(Int, Int)] = [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]
            for (x, y) in cells {
                let r = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                context.fill(Path(r), with: .color(color))
            }
        }
        .frame(width: 3 * cell, height: 3 * cell)
    }
}

struct SparkleParticle: View {
    @Environment(\.jjTheme) private var palette

    let index: Int
    let count: Int
    let phase: CGFloat

    /// Mostly shoots **left** and **right** from the knob (with a little vertical spread).
    private var angle: Double {
        let half = count / 2
        if index < half {
            let denom = max(1, half - 1)
            let t = Double(index) / Double(denom)
            return (148 + t * 64) * Double.pi / 180
        } else {
            let j = index - half
            let denom = max(1, count - half - 1)
            let t = Double(j) / Double(denom)
            return (-32 + t * 64) * Double.pi / 180
        }
    }

    private var distance: CGFloat {
        22 + CGFloat(index % 5) * 5 + CGFloat((index / 3) % 2) * 4
    }

    /// Stepped motion so it reads like a low-FPS sprite cycle.
    private var staccato: CGFloat {
        let steps: CGFloat = 10
        return floor(phase * steps + 0.0001) / steps
    }

    private var twinkle: CGFloat {
        1 + 0.28 * sin(Double(phase) * .pi * 6 + Double(index) * 0.7)
    }

    private var starColor: Color {
        index % 3 == 0 ? palette.accent : palette.accentSecondary
    }

    var body: some View {
        let fade = Double(staccato)
        Group {
            if index % 2 == 0 {
                PixelPlusStar(color: starColor)
            } else {
                PixelDiamondStar(color: starColor)
            }
        }
        .scaleEffect(twinkle * (1 - 0.5 * staccato))
        .offset(
            x: cos(angle) * distance * staccato,
            y: sin(angle) * distance * staccato
        )
        .opacity(1 - fade)
    }
}

struct SparkleBurstView: View {
    var burstKey: Int
    private let count = 12

    /// `1` = burst finished; stars are fully faded. Using `0` here draws every sprite on top of the bolt until the first animation runs (bad after the popover is recreated).
    @State private var phase: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                SparkleParticle(index: i, count: count, phase: phase)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: burstKey) { _ in
            var reset = Transaction()
            reset.animation = nil
            withTransaction(reset) {
                phase = 0
            }
            DispatchQueue.main.async {
                withAnimation(.timingCurve(0.12, 0.82, 0.2, 1, duration: 0.56)) {
                    phase = 1
                }
            }
        }
    }
}

private struct PixelLightningToggleKnob: View {
    @Environment(\.jjTheme) private var palette

    @Binding var isOn: Bool
    @State private var burstKey = 0

    private let box: CGFloat = 22

    var body: some View {
        Button {
            isOn.toggle()
            burstKey &+= 1
        } label: {
            ZStack {
                Rectangle()
                    .fill(isOn ? palette.toggleOnFill : palette.toggleOffFill)
                    .frame(width: box, height: box)
                Rectangle()
                    .strokeBorder(palette.border, lineWidth: 2)
                    .frame(width: box, height: box)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isOn ? palette.buttonLabelOnAccent : palette.accent)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "On" : "Off")
        .overlay {
            if palette.useSparkles {
                SparkleBurstView(burstKey: burstKey)
                    .frame(width: 100, height: 72)
            }
        }
    }
}

// MARK: - Settings row bursts (sparkles; macOS theme shoots pixel apples)

enum RetroSettingsRowBurstKind: Equatable {
    case sparkles
    case macApples
}

/// Tiny 8-bit apple (red body, green leaf, brown stem) for “macOS” row celebrations.
private struct PixelAppleMini: View {
    @Environment(\.jjTheme) private var palette
    private let cell: CGFloat = 2

    var body: some View {
        Canvas { context, _ in
            let red = Color(red: 0.92, green: 0.16, blue: 0.22)
            let green = Color(red: 0.2, green: 0.72, blue: 0.32)
            let brown = Color(red: 0.38, green: 0.24, blue: 0.12)
            let highlight = palette.accentSecondary

            func fill(_ x: Int, _ y: Int, _ c: Color) {
                let r = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                context.fill(Path(r), with: .color(c))
            }

            fill(2, 0, brown)
            fill(4, 0, green)
            fill(3, 1, green)
            for (x, y) in [(1, 2), (2, 2), (3, 2), (4, 2)] {
                fill(x, y, red)
            }
            for (x, y) in [(0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3)] {
                fill(x, y, red)
            }
            for (x, y) in [(1, 4), (2, 4), (3, 4), (4, 4)] {
                fill(x, y, red)
            }
            fill(2, 5, red)
            fill(3, 5, red)
            fill(2, 3, highlight)
            fill(3, 3, highlight.opacity(0.85))
        }
        .frame(width: 6 * cell, height: 6 * cell)
    }
}

private struct AppleBurstParticle: View {
    let index: Int
    let count: Int
    let phase: CGFloat

    private var angle: Double {
        let half = count / 2
        if index < half {
            let denom = max(1, half - 1)
            let t = Double(index) / Double(denom)
            return (140 + t * 70) * Double.pi / 180
        } else {
            let j = index - half
            let denom = max(1, count - half - 1)
            let t = Double(j) / Double(denom)
            return (-40 + t * 70) * Double.pi / 180
        }
    }

    private var distance: CGFloat {
        24 + CGFloat(index % 6) * 4 + CGFloat((index / 4) % 2) * 5
    }

    private var staccato: CGFloat {
        let steps: CGFloat = 10
        return floor(phase * steps + 0.0001) / steps
    }

    private var twirl: CGFloat {
        1 + 0.2 * sin(Double(phase) * .pi * 5 + Double(index) * 0.9)
    }

    var body: some View {
        let fade = Double(staccato)
        PixelAppleMini()
            .scaleEffect(twirl * (1 - 0.45 * staccato))
            .rotationEffect(.degrees(Double(phase) * 40 * (index % 2 == 0 ? 1 : -1)))
            .offset(
                x: cos(angle) * distance * staccato,
                y: sin(angle) * distance * staccato
            )
            .opacity(1 - fade)
    }
}

private struct AppleBurstView: View {
    var burstKey: Int
    private let count = 10

    @State private var phase: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                AppleBurstParticle(index: i, count: count, phase: phase)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: burstKey) { _ in
            var reset = Transaction()
            reset.animation = nil
            withTransaction(reset) {
                phase = 0
            }
            DispatchQueue.main.async {
                withAnimation(.timingCurve(0.12, 0.82, 0.2, 1, duration: 0.58)) {
                    phase = 1
                }
            }
        }
    }
}

/// Overlay for retro list rows: sparkles, or flying apples for the macOS theme row.
struct RetroSettingsRowBurstOverlay: View {
    @Environment(\.jjTheme) private var palette

    var burstKey: Int
    var kind: RetroSettingsRowBurstKind

    var body: some View {
        Group {
            if palette.useSparkles {
                switch kind {
                case .sparkles:
                    SparkleBurstView(burstKey: burstKey)
                case .macApples:
                    AppleBurstView(burstKey: burstKey)
                }
            }
        }
        .frame(width: 130, height: 76)
        .allowsHitTesting(false)
    }
}

struct PixelLightningToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 10) {
            PixelLightningToggleKnob(isOn: configuration.$isOn)
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PixelBorder: ViewModifier {
    var lineWidth: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(PixelTheme.accentYellow, lineWidth: lineWidth)
            )
    }
}

struct PixelOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelTheme.font(size: 9))
            .foregroundStyle(PixelTheme.accentYellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Rectangle().fill(PixelTheme.backgroundDeep.opacity(0.55)))
            .overlay(Rectangle().strokeBorder(PixelTheme.accentYellow, lineWidth: 2))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct PixelPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelTheme.font(size: 9))
            .foregroundStyle(PixelTheme.backgroundDeep)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? PixelTheme.accentGold : PixelTheme.accentYellow)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(PixelTheme.backgroundDeep.opacity(0.35), lineWidth: 2)
            )
    }
}
