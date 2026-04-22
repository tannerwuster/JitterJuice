import AppKit
import SwiftUI

enum MenuBarIcon {
    /// Menu bar icon height in **points** (typical range ~18–28). Rebuild and relaunch after changing.
    static let pointSize: CGFloat = 28

    private struct CacheKey: Hashable {
        let height: CGFloat
        let appearance: MenuBarIconAppearance
        /// Packed sRGB 0x00RRGGBB; only used when `appearance == .matchTheme`.
        let themeMainPacked: UInt32
        let themeAccentPacked: UInt32
    }

    private static var cache: [CacheKey: NSImage] = [:]

    static func nsImage(forHeight height: CGFloat, appearance: MenuBarIconAppearance, palette: ThemePalette? = nil) -> NSImage {
        let paletteForMatch = appearance == .matchTheme ? (palette ?? ThemePalette.builtinEightBit) : palette
        let mainP = packSRGBForCache(paletteForMatch?.backgroundDeep, use: appearance == .matchTheme)
        let accentP = packSRGBForCache(paletteForMatch?.accent, use: appearance == .matchTheme)
        let key = CacheKey(
            height: height,
            appearance: appearance,
            themeMainPacked: mainP,
            themeAccentPacked: accentP
        )
        if let cached = cache[key] { return cached }
        let made = rasterizeMenuIcon(heightPoints: height, appearance: appearance, palette: paletteForMatch)
        cache[key] = made
        return made
    }

    private static func packSRGBForCache(_ color: Color?, use: Bool) -> UInt32 {
        guard use, let color, let c = NSColor(color).usingColorSpace(.deviceRGB) else { return 0 }
        let r = UInt32(max(0, min(255, Int(round(c.redComponent * 255)))))
        let g = UInt32(max(0, min(255, Int(round(c.greenComponent * 255)))))
        let b = UInt32(max(0, min(255, Int(round(c.blueComponent * 255)))))
        return (r << 16) | (g << 8) | b
    }

    private static func rasterizeMenuIcon(heightPoints: CGFloat, appearance: MenuBarIconAppearance, palette: ThemePalette?) -> NSImage {
        guard let source = NSImage(named: "JitterJuiceMenuBar") else {
            return NSImage(size: NSSize(width: heightPoints, height: heightPoints))
        }

        let srcSize = source.size
        let aspect = (srcSize.width > 0 && srcSize.height > 0) ? (srcSize.width / srcSize.height) : 1
        let widthPoints = heightPoints * aspect

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let pxW = max(1, Int(round(widthPoints * scale)))
        let pxH = max(1, Int(round(heightPoints * scale)))

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pxW,
            pixelsHigh: pxH,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return NSImage(size: NSSize(width: widthPoints, height: heightPoints))
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        defer { NSGraphicsContext.restoreGraphicsState() }

        NSGraphicsContext.current?.imageInterpolation = .none

        let destPx = NSRect(x: 0, y: 0, width: pxW, height: pxH)
        let src = NSRect(origin: .zero, size: srcSize)

        source.draw(
            in: destPx,
            from: src,
            operation: .copy,
            fraction: 1.0,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.none]
        )

        if appearance == .menuBarMonochrome {
            recolorWhiteCanBlackDetails(rep: rep, width: pxW, height: pxH)
        } else if appearance == .matchTheme, let palette, !palette.matchesOriginalMenuBarAsset {
            recolorThemeMatched(rep: rep, width: pxW, height: pxH, palette: palette)
        }

        let out = NSImage(size: NSSize(width: widthPoints, height: heightPoints))
        out.addRepresentation(rep)
        out.isTemplate = false
        return out
    }

    /// Maps the purple can to white, yellow lightning to black, and keeps facial details dark — tuned for the JitterJuice pixel asset.
    private static func recolorWhiteCanBlackDetails(rep: NSBitmapImageRep, width: Int, height: Int) {
        guard let data = rep.bitmapData else { return }
        let bytesPerRow = rep.bytesPerRow

        for y in 0..<height {
            for x in 0..<width {
                let o = y * bytesPerRow + x * 4
                let a = CGFloat(data[o + 3]) / 255
                if a < 0.02 { continue }

                let r = CGFloat(data[o]) / 255
                let g = CGFloat(data[o + 1]) / 255
                let b = CGFloat(data[o + 2]) / 255
                let (nr, ng, nb) = classifyMonochromePixel(r: r, g: g, b: b)
                data[o] = UInt8(clamping: Int(nr * 255))
                data[o + 1] = UInt8(clamping: Int(ng * 255))
                data[o + 2] = UInt8(clamping: Int(nb * 255))
            }
        }
    }

    private static func recolorThemeMatched(rep: NSBitmapImageRep, width: Int, height: Int, palette: ThemePalette) {
        // Can body in the source art reads closer to the UI panel purple than `backgroundDeep`.
        guard let bodyC = NSColor(palette.backgroundPanel).usingColorSpace(.deviceRGB),
              let accentC = NSColor(palette.accent).usingColorSpace(.deviceRGB) else { return }
        let mr = bodyC.redComponent
        let mg = bodyC.greenComponent
        let mb = bodyC.blueComponent
        let ar = accentC.redComponent
        let ag = accentC.greenComponent
        let ab = accentC.blueComponent

        func mix(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat { a * (1 - t) + b * t }

        guard let data = rep.bitmapData else { return }
        let bytesPerRow = rep.bytesPerRow

        for y in 0..<height {
            for x in 0..<width {
                let o = y * bytesPerRow + x * 4
                let alpha = CGFloat(data[o + 3]) / 255
                if alpha < 0.02 { continue }

                let r = CGFloat(data[o]) / 255
                let g = CGFloat(data[o + 1]) / 255
                let b = CGFloat(data[o + 2]) / 255

                let (nr, ng, nb): (CGFloat, CGFloat, CGFloat) = switch menuBarPixelKind(r: r, g: g, b: b) {
                case .yellowAccent:
                    (ar, ag, ab)
                case .darkDetail:
                    Self.themeMatchedFaceColor(
                        bodyR: mr, bodyG: mg, bodyB: mb,
                        accentR: ar, accentG: ag, accentB: ab,
                        mix: mix
                    )
                case .purpleBody, .midBody:
                    (mr, mg, mb)
                case .neutralHighlight:
                    (mix(0.42, mr, 1), mix(0.42, mg, 1), mix(0.42, mb, 1))
                case .purpleSparkle:
                    (mix(0.35, ar, 1), mix(0.35, ag, 1), mix(0.35, ab, 1))
                }

                data[o] = UInt8(clamping: Int(nr * 255))
                data[o + 1] = UInt8(clamping: Int(ng * 255))
                data[o + 2] = UInt8(clamping: Int(nb * 255))
            }
        }
    }

    /// Eyes / mouth / outlines — follows the source asset (dark features on a typical can), not generic WCAG label contrast.
    private static func themeMatchedFaceColor(
        bodyR: CGFloat, bodyG: CGFloat, bodyB: CGFloat,
        accentR: CGFloat, accentG: CGFloat, accentB: CGFloat,
        mix t: @escaping (CGFloat, CGFloat, CGFloat) -> CGFloat
    ) -> (CGFloat, CGFloat, CGFloat) {
        let body = Color(red: Double(bodyR), green: Double(bodyG), blue: Double(bodyB))
        let bodyLum = ThemeColorUtils.relativeLuminance(body)

        func tintedShadow() -> (CGFloat, CGFloat, CGFloat) {
            let k: CGFloat = 0.07
            return (
                t(0.18, k, accentR),
                t(0.18, k, accentG),
                t(0.18, k, accentB)
            )
        }

        // Very light / pastel can: use near-black features (like a dark print on a light label).
        if bodyLum > 0.58 {
            return tintedShadow()
        }

        // Typical colored or dark-purple can (JitterJuice-style): keep features dark like the PNG.
        if bodyLum > 0.14 {
            return tintedShadow()
        }

        // Extremely dark body: subtle lift so eyes/mouth don’t disappear into the fill.
        let lift = min(0.42, CGFloat(0.22 - bodyLum) * 1.8)
        let (sr, sg, sb) = tintedShadow()
        return (
            min(1, sr + lift),
            min(1, sg + lift),
            min(1, sb + lift)
        )
    }

    private enum MenuBarPixelKind {
        case yellowAccent
        case darkDetail
        case purpleBody
        case neutralHighlight
        case purpleSparkle
        case midBody
    }

    /// Shared classifier for the bundled menu-bar pixel asset (see `classifyMonochromePixel` / `recolorThemeMatched`).
    private static func menuBarPixelKind(r: CGFloat, g: CGFloat, b: CGFloat) -> MenuBarPixelKind {
        let maxv = max(r, g, b)
        let minv = min(r, g, b)
        let delta = maxv - minv
        let s = maxv > 0.001 ? delta / maxv : 0

        var h: CGFloat = 0
        if delta > 0.001 {
            if maxv == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxv == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h *= 60
            if h < 0 { h += 360 }
        }

        if h >= 35 && h <= 88 && s > 0.18 && maxv > 0.32 {
            return .yellowAccent
        }

        if maxv < 0.30 {
            return .darkDetail
        }

        let purpleHue = (h >= 240 && h <= 330) || (b > r + 0.08 && b > g + 0.05 && maxv > 0.18)
        if purpleHue && s > 0.12 {
            return .purpleBody
        }

        if s < 0.14 && maxv > 0.42 {
            return .neutralHighlight
        }

        if b > 0.45 && r > 0.25 && maxv > 0.55 {
            return .purpleSparkle
        }

        if maxv > 0.35 {
            return .midBody
        }

        return .darkDetail
    }

    private static func classifyMonochromePixel(r: CGFloat, g: CGFloat, b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        switch menuBarPixelKind(r: r, g: g, b: b) {
        case .yellowAccent, .darkDetail:
            return (0, 0, 0)
        case .purpleBody, .neutralHighlight, .purpleSparkle, .midBody:
            return (1, 1, 1)
        }
    }
}

@main
struct JitterJuiceApp: App {
    @StateObject private var model = AppModel()

    init() {
        PixelTheme.registerBundledFonts()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(model: model)
        } label: {
            let palette = ThemePalette.palette(for: model.appTheme, model: model)
            Image(nsImage: MenuBarIcon.nsImage(forHeight: MenuBarIcon.pointSize, appearance: model.menuBarIconAppearance, palette: palette))
                .renderingMode(.original)
                .brightness(model.anyFeatureActive ? 0.12 : 0)
        }
        .menuBarExtraStyle(.window)
    }
}
