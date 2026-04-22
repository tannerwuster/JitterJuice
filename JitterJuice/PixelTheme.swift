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
        if palette.theme == .pride {
            ThemePalette.prideRainbowStripeColors[index % ThemePalette.prideRainbowStripeColors.count]
        } else {
            index % 3 == 0 ? palette.accent : palette.accentSecondary
        }
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
                    .fill(isOn ? palette.chromeAccentFill(isPressed: false) : AnyShapeStyle(palette.toggleOffFill))
                    .frame(width: box, height: box)
                Rectangle()
                    .strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                    .frame(width: box, height: box)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isOn ? AnyShapeStyle(palette.buttonLabelOnAccent) : palette.chromeForegroundAccent())
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

/// Chunky diagonal “rain” behind the retro menu (Hail Storm Juice).
/// Sky rain is masked inside occluders; impacts get pixel “splashes”; a shallow puddle gathers at the bottom then drains at the corners (edge trickles unchanged).
struct PixelMenuRainOverlay: View {
    @Environment(\.jjTheme) private var palette
    var occluders: [CGRect] = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 20.0)) { timeline in
            Canvas { cx, size in
                let w = max(size.width, 1)
                let h = max(size.height, 1)
                let t = timeline.date.timeIntervalSinceReferenceDate
                let cell: CGFloat = 2
                let zones = Self.sortedRainZones(from: occluders)

                Self.drawSkyRain(cx: cx, palette: palette, zones: zones, w: w, h: h, t: t, cell: cell)

                Self.drawPuddle(cx: cx, palette: palette, w: w, h: h, t: t)
                Self.drawBottomDrain(cx: cx, palette: palette, w: w, h: h, t: t, cell: cell)

                guard !occluders.isEmpty else { return }
                for rect in occluders {
                    let sides: [CGFloat] = [rect.minX - 3, rect.maxX + 1]
                    let strips = max(2, Int(rect.height / 9))
                    for (sideIndex, baseX) in sides.enumerated() {
                        for i in 0..<strips {
                            let phase = Double(i) * 2.4 + Double(sideIndex) * 1.7 + Double(rect.minY + rect.minX) * 0.015
                            var dripY = (t * 52 + phase * 29).truncatingRemainder(dividingBy: Double(rect.height + 24))
                            dripY += Double(rect.minY) - 4
                            let iy = floor(CGFloat(dripY))
                            if iy < rect.minY - 6 || iy > rect.maxY + 6 { continue }
                            let dripBright = i % 3 == 0
                            let dripColor = palette.accent.opacity(dripBright ? 0.42 : 0.24)
                            let drop = CGRect(x: floor(baseX), y: iy, width: cell, height: cell + 1)
                            cx.fill(Path(drop), with: .color(dripColor))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
    }

    private typealias RainZone = (orig: CGRect, block: CGRect)

    private static func sortedRainZones(from occluders: [CGRect]) -> [RainZone] {
        occluders
            .map { r in (r, r.insetBy(dx: -2, dy: -2)) }
            .sorted {
                let a = $0.orig.width * $0.orig.height
                let b = $1.orig.width * $1.orig.height
                return a < b
            }
    }

    private static func drawSkyRain(
        cx: GraphicsContext,
        palette: ThemePalette,
        zones: [RainZone],
        w: CGFloat,
        h: CGFloat,
        t: TimeInterval,
        cell: CGFloat
    ) {
        let phi = 0.618_033_988_749_894_9
        let dropCount = max(44, Int(Double(w) / 4.2))

        for i in 0..<dropCount {
            let u1 = unitScalar(i, 1)
            let u2 = unitScalar(i, 2)
            let u3 = unitScalar(i, 3)
            let u4 = unitScalar(i, 4)
            let u5 = unitScalar(i, 5)
            let u6 = unitScalar(i, 6)

            let spaced = (Double(i) * phi + u3 * 0.37).truncatingRemainder(dividingBy: 1)
            let baseX = CGFloat(spaced) * w * 1.12 - w * CGFloat(0.06)
                + CGFloat(u4 - 0.5) * CGFloat(18 + u6 * 12)

            let speed = 34 + u1 * 58
            let phase = u2 * 320 + u5 * 140
                + sin(t * (0.14 + u6 * 0.11) + Double(i) * 2.31) * 16
                + sin(t * 0.73 + Double(i) * 0.89) * 7
            let y = (t * speed + phase).truncatingRemainder(dividingBy: Double(h + 62)) - 34

            let windFreq = 0.72 + u5 * 0.62
            let windAmp = CGFloat(2.5 + u3 * 5.5)
            let wind = sin(t * windFreq + u4 * 13.7) * windAmp
                + sin(t * 0.41 + Double(i) * 0.53) * CGFloat(1.4 + u1 * 2.3)
            let xWobble = sin(Double(i) * 1.09 + t * 0.63) * CGFloat(2.1)
                + sin(t * 1.17 + Double(i) * 0.27) * CGFloat(1.2)
            let x = baseX + wind + xWobble

            let stripCount = 3 + Int(unitScalar(i, 7) * 3)
            let bright = unitScalar(i, 8) > 0.55
            let dropColor = bright ? palette.accent : palette.accentSecondary
            let c = dropColor.opacity(0.15 + unitScalar(i, 9) * 0.13)

            var accDx: CGFloat = 0
            var accDy: CGFloat = 0
            var prevStreakMid: CGPoint?

            for strip in 0..<stripCount {
                let rawDx = cell * CGFloat(0.32 + unitScalar(i, 10 + strip) * 0.88)
                let rawDy = cell * CGFloat(1.15 + unitScalar(i, 25 + strip) * 1.15)
                let rot = CGFloat((unitScalar(i, 40 + strip) - 0.5) * 0.95)
                let cr = cos(rot)
                let sr = sin(rot)
                let dxc = rawDx * cr - rawDy * sr
                let dys = rawDx * sr + rawDy * cr

                let prevAccDx = accDx
                let prevAccDy = accDy
                accDx += dxc
                accDy += dys

                let mxJ = CGFloat(unitScalar(i, 60 + strip) - 0.5) * CGFloat(3.5)
                let myJ = CGFloat(unitScalar(i, 75 + strip) - 0.5) * CGFloat(3.5)

                let r = CGRect(
                    x: floor(x + accDx + mxJ),
                    y: floor(CGFloat(y) + accDy + myJ),
                    width: cell,
                    height: cell * 2
                )
                let mid = CGPoint(x: r.midX, y: r.midY)

                let prevMid: CGPoint
                if let p = prevStreakMid {
                    prevMid = p
                } else {
                    prevMid = CGPoint(
                        x: x + prevAccDx - dxc * CGFloat(0.72) - wind * CGFloat(0.07),
                        y: CGFloat(y) + prevAccDy - dys * CGFloat(0.72) - cell * CGFloat(0.85)
                    )
                }

                if let hit = zones.first(where: { $0.block.contains(mid) }) {
                    if !hit.block.contains(prevMid) {
                        let gate = sin(t * 11 + phase * 0.02 + Double(strip) * 1.11 + Double(i) * 0.09)
                        if gate > 0.06 {
                            drawSplash(
                                cx: cx,
                                palette: palette,
                                at: CGPoint(x: mid.x, y: hit.orig.minY - 1),
                                t: t,
                                seed: i &* 31 &+ strip &* 17
                            )
                        }
                    }
                    prevStreakMid = mid
                    continue
                }

                let puddleTop = puddleSurfaceY(h: h, t: t)
                if mid.y >= puddleTop - 2 {
                    prevStreakMid = mid
                    continue
                }

                cx.fill(Path(r), with: .color(c))
                prevStreakMid = mid
            }
        }
    }

    /// Deterministic 0…1 scalar — strong mixing so nearby `i` and salts decorrelate.
    private static func unitScalar(_ i: Int, _ salt: Int) -> Double {
        var x = UInt64(bitPattern: Int64(i)) &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        x ^= UInt64(bitPattern: Int64(salt)) &+ (x >> 32)
        x &*= 0xbf58_476d_1ce4_e5b9
        x ^= x >> 31
        x &*= 0x94d0_49bb_1331_11eb
        x ^= x >> 28
        return Double(x % 1_000_003) / 1_000_003
    }

    private static func puddleSurfaceY(h: CGFloat, t: TimeInterval) -> CGFloat {
        let fillDepth = 4.0 + sin(t * 0.9) * 2.2 + sin(t * 1.45) * 1.4
        return CGFloat(Double(h) - 4 - fillDepth)
    }

    private static func drawSplash(cx: GraphicsContext, palette: ThemePalette, at origin: CGPoint, t: TimeInterval, seed: Int) {
        let ox = origin.x
        let oy = origin.y
        let dots: [(CGFloat, CGFloat)] = [
            (-3, -2), (-1, -4), (1, -5), (3, -3), (4, -1),
            (-2, 0), (0, -2), (2, -1), (5, -2), (-4, -3), (2, -4),
        ]
        for (i, d) in dots.enumerated() {
            let flicker = sin(t * 17 + Double(seed &+ i) * 0.55) * 0.5 + 0.5
            guard flicker > 0.22 else { continue }
            let op = (0.2 + Double(i % 4) * 0.05) * flicker
            let px = floor(ox + d.0)
            let py = floor(oy + d.1)
            cx.fill(Path(CGRect(x: px, y: py, width: 2, height: 2)), with: .color(palette.accent.opacity(op)))
        }
    }

    private static func drawPuddle(cx: GraphicsContext, palette: ThemePalette, w: CGFloat, h: CGFloat, t: TimeInterval) {
        let surface0 = Double(puddleSurfaceY(h: h, t: t))
        for xi in stride(from: 4, to: Int(w - 4), by: 3) {
            let xf = CGFloat(xi)
            let surf = surface0 + sin(Double(xi) * 0.1 + t * 2.2) * 1.6 + sin(Double(xi) * 0.04 - t * 0.9) * 0.7
            let surfY = CGFloat(surf)
            let sOp = 0.11 + sin(t * 4 + Double(xi) * 0.14) * 0.08
            cx.fill(
                Path(CGRect(x: xf, y: floor(surfY), width: 2, height: 2)),
                with: .color(palette.accent.opacity(sOp))
            )
            for layer in 1...5 {
                let dy = CGFloat(layer * 3 + xi % 2)
                let yy = surfY + dy
                if yy >= h - 0.5 { break }
                let depthFade = 1 - Double(layer) / 6
                let op = (0.05 + sin(Double(xi &+ layer * 9) * 0.4 + t * 1.3) * 0.035) * depthFade
                cx.fill(
                    Path(CGRect(x: xf, y: floor(yy), width: 2, height: 2)),
                    with: .color(palette.accentSecondary.opacity(min(0.18, op)))
                )
            }
        }

        let lipBase = h - 1
        for xi in stride(from: 0, to: Int(w), by: 2) {
            let lip = sin(t * 1.85 + Double(xi) * 0.07) * 0.5 + 0.5
            let yy = lipBase - CGFloat(xi % 2)
            cx.fill(
                Path(CGRect(x: CGFloat(xi), y: yy, width: 2, height: 2)),
                with: .color(palette.accent.opacity(0.07 + lip * 0.09))
            )
        }
    }

    private static func drawBottomDrain(cx: GraphicsContext, palette: ThemePalette, w: CGFloat, h: CGFloat, t: TimeInterval, cell: CGFloat) {
        for edge in 0..<2 {
            let xBase: CGFloat = edge == 0 ? 0 : (w - 4)
            for i in 0..<7 {
                let phase = Double(i) * 1.25 + Double(edge) * 2.4
                let yy = (t * 48 + phase * 31).truncatingRemainder(dividingBy: 20) + Double(h) - 18
                let iy = floor(CGFloat(yy))
                let op = 0.18 + Double(i % 3) * 0.07
                let x = xBase + CGFloat(i % 2) * 2
                cx.fill(Path(CGRect(x: x, y: iy, width: cell, height: cell + 1)), with: .color(palette.accent.opacity(op)))
            }
        }
    }
}
