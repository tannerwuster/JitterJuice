import AppKit
import SwiftUI

enum MenuBarIcon {
    /// Menu bar icon height in **points**. Slightly above typical SF Symbol sizing so pixel art stays legible next to system extras.
    static let pointSize: CGFloat = 32

    private struct CacheKey: Hashable {
        let height: CGFloat
        let appearance: MenuBarIconAppearance
        /// Packed sRGB 0x00RRGGBB; only used when `appearance == .matchTheme`.
        let themeMainPacked: UInt32
        let themeAccentPacked: UInt32
        /// Distinguishes bespoke match-theme art (juice box, overlays, etc.).
        let matchThemeId: String
    }

    private static var cache: [CacheKey: NSImage] = [:]

    static func nsImage(forHeight height: CGFloat, appearance: MenuBarIconAppearance, palette: ThemePalette? = nil) -> NSImage {
        let paletteForMatch = appearance == .matchTheme ? (palette ?? ThemePalette.builtinEightBit) : palette
        let mainP = packSRGBForCache(paletteForMatch?.backgroundDeep, use: appearance == .matchTheme)
        let accentP = packSRGBForCache(paletteForMatch?.accent, use: appearance == .matchTheme)
        let matchId = appearance == .matchTheme ? (paletteForMatch?.theme.rawValue ?? "") : ""
        let key = CacheKey(
            height: height,
            appearance: appearance,
            themeMainPacked: mainP,
            themeAccentPacked: accentP,
            matchThemeId: matchId
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

    /// Full-frame menu bar art in `Assets.xcassets/MenuBarIcons` (not the shared can template).
    private static func dedicatedMatchThemeAssetName(for theme: AppTheme) -> String? {
        switch theme {
        case .macOS: return "applejuiceicon"
        case .dracula: return "draculaicon"
        case .dark: return "deadlyjuice"
        case .light: return "moonjuiceicon"
        case .donny: return "donnyjuiceicon"
        case .treehugger: return "treehuggerjuiceicon"
        case .pride: return "pridejuiceicon"
        case .hailStorm: return "hailstormjuiceicon"
        case .bladeRunner: return "bladerunnericon"
        default: return nil
        }
    }

    private static func rasterizeMenuIcon(heightPoints: CGFloat, appearance: MenuBarIconAppearance, palette: ThemePalette?) -> NSImage {
        let canAsset = NSImage(named: "JitterJuiceMenuBar")
        let theme = palette?.theme

        let dedicatedImage: NSImage? = {
            guard appearance == .matchTheme, let theme else { return nil }
            guard let name = dedicatedMatchThemeAssetName(for: theme) else { return nil }
            return NSImage(named: name)
        }()

        let srcSize: NSSize
        let imageToRasterize: NSImage?
        if let dedicated = dedicatedImage {
            srcSize = dedicated.size
            imageToRasterize = dedicated
        } else if appearance == .matchTheme, theme == .macOS {
            guard let can = canAsset else {
                return NSImage(size: NSSize(width: heightPoints, height: heightPoints))
            }
            srcSize = can.size
            imageToRasterize = nil
        } else {
            guard let can = canAsset else {
                return NSImage(size: NSSize(width: heightPoints, height: heightPoints))
            }
            srcSize = can.size
            imageToRasterize = can
        }

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

        if let img = imageToRasterize {
            img.draw(
                in: destPx,
                from: src,
                operation: .copy,
                fraction: 1.0,
                respectFlipped: false,
                hints: [.interpolation: NSImageInterpolation.none]
            )
            if dedicatedImage != nil, !menuBarRasterImageReportsAlpha(img) {
                floodEraseOuterBackgroundMatchingCorners(rep: rep, width: pxW, height: pxH)
            }
        } else if appearance == .matchTheme, theme == .macOS, let palette {
            clearBitmap(rep: rep, width: pxW, height: pxH)
            drawAppleJuiceBox(rep: rep, width: pxW, height: pxH, palette: palette)
        }

        if appearance == .menuBarMonochrome {
            recolorWhiteCanBlackDetails(rep: rep, width: pxW, height: pxH)
        } else if appearance == .matchTheme, let palette, dedicatedImage == nil {
            if !palette.matchesOriginalMenuBarAsset {
                recolorThemeMatched(rep: rep, width: pxW, height: pxH, palette: palette)
            }
            switch palette.theme {
            case .eightBit, .macOS, .donny, .treehugger, .pride, .hailStorm, .bladeRunner, .custom:
                break
            case .dracula:
                drawDraculaFangs(rep: rep, width: pxW, height: pxH, palette: palette)
            case .dark:
                drawSkullEmblem(rep: rep, width: pxW, height: pxH, palette: palette)
            case .light:
                drawMoonEmblem(rep: rep, width: pxW, height: pxH, palette: palette)
            }
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

    // MARK: - Match-theme bespoke menu bar art

    /// `NSImage` from a flat RGB PNG reports `hasAlpha == false` even though the buffer is 32-bit; we only skip flood when the asset catalog image actually has an alpha channel.
    private static func menuBarRasterImageReportsAlpha(_ image: NSImage) -> Bool {
        for rep in image.representations {
            if let b = rep as? NSBitmapImageRep, b.hasAlpha { return true }
        }
        return false
    }

    /// Flood from the edges on pixels near the average corner color so “paper white” becomes transparent. Skipped when the source PNG already has alpha; 4-connected so interior whites (e.g. straw) stay if separated by non-white art.
    private static func floodEraseOuterBackgroundMatchingCorners(rep: NSBitmapImageRep, width: Int, height: Int) {
        guard width > 1, height > 1, let data = rep.bitmapData else { return }
        let bpr = rep.bytesPerRow
        let thresh = 14

        func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
            let o = y * bpr + x * 4
            return (Int(data[o]), Int(data[o + 1]), Int(data[o + 2]))
        }

        let corners = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
        var cr = 0, cg = 0, cb = 0
        for (x, y) in corners {
            let p = rgb(x, y)
            cr += p.0
            cg += p.1
            cb += p.2
        }
        cr /= 4
        cg /= 4
        cb /= 4

        func matchesBackground(_ x: Int, _ y: Int) -> Bool {
            let p = rgb(x, y)
            return abs(p.0 - cr) <= thresh && abs(p.1 - cg) <= thresh && abs(p.2 - cb) <= thresh
        }

        var visited = [Bool](repeating: false, count: width * height)
        var queue: [(Int, Int)] = []
        var head = 0
        func idx(_ x: Int, _ y: Int) -> Int { y * width + x }

        for x in 0..<width {
            for y in [0, height - 1] {
                let i = idx(x, y)
                if !visited[i], matchesBackground(x, y) {
                    visited[i] = true
                    queue.append((x, y))
                }
            }
        }
        for y in 0..<height {
            for x in [0, width - 1] {
                let i = idx(x, y)
                if !visited[i], matchesBackground(x, y) {
                    visited[i] = true
                    queue.append((x, y))
                }
            }
        }

        let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        while head < queue.count {
            let (x, y) = queue[head]
            head += 1
            let o = y * bpr + x * 4
            data[o + 3] = 0
            for (dx, dy) in dirs {
                let nx = x + dx
                let ny = y + dy
                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                let ni = idx(nx, ny)
                if visited[ni] { continue }
                if matchesBackground(nx, ny) {
                    visited[ni] = true
                    queue.append((nx, ny))
                }
            }
        }
    }

    private static func clearBitmap(rep: NSBitmapImageRep, width: Int, height: Int) {
        guard let data = rep.bitmapData else { return }
        let bpr = rep.bytesPerRow
        for y in 0..<height {
            for x in 0..<width {
                let o = y * bpr + x * 4
                data[o] = 0
                data[o + 1] = 0
                data[o + 2] = 0
                data[o + 3] = 0
            }
        }
    }

    private static func rgbaBytes(_ color: NSColor) -> (UInt8, UInt8, UInt8, UInt8) {
        guard let c = color.usingColorSpace(.deviceRGB) else {
            return (0, 0, 0, 255)
        }
        return (
            UInt8(clamping: Int(c.redComponent * 255)),
            UInt8(clamping: Int(c.greenComponent * 255)),
            UInt8(clamping: Int(c.blueComponent * 255)),
            UInt8(clamping: Int(c.alphaComponent * 255))
        )
    }

    private static func fillRect(
        rep: NSBitmapImageRep,
        x: Int, y: Int, w: Int, h: Int,
        r: UInt8, g: UInt8, b: UInt8, a: UInt8,
        width: Int, height: Int
    ) {
        guard let data = rep.bitmapData else { return }
        let bpr = rep.bytesPerRow
        for dy in 0..<h {
            let yy = y + dy
            guard yy >= 0, yy < height else { continue }
            for dx in 0..<w {
                let xx = x + dx
                guard xx >= 0, xx < width else { continue }
                let o = yy * bpr + xx * 4
                data[o] = r
                data[o + 1] = g
                data[o + 2] = b
                data[o + 3] = a
            }
        }
    }

    /// Apple Juice: carton + straw + Apple silhouette (pixel style).
    private static func drawAppleJuiceBox(rep: NSBitmapImageRep, width: Int, height: Int, palette: ThemePalette) {
        let u = max(1, min(width, height) / 22)
        let cream = rgbaBytes(NSColor(palette.backgroundPanel).blended(withFraction: 0.55, of: .white) ?? NSColor(white: 0.94, alpha: 1))
        let border = rgbaBytes(NSColor(palette.border))
        let straw = rgbaBytes(NSColor(palette.accent))
        let stem = rgbaBytes(NSColor(calibratedHue: 0.08, saturation: 0.5, brightness: 0.35, alpha: 1))
        let leaf = rgbaBytes(NSColor(palette.accentSecondary))
        let appleBlack: (UInt8, UInt8, UInt8, UInt8) = (18, 18, 22, 255)

        let bx = width * 18 / 100
        let by = height * 20 / 100
        let bw = width * 64 / 100
        let bh = height * 58 / 100

        fillRect(rep: rep, x: bx, y: by, w: bw, h: bh, r: cream.0, g: cream.1, b: cream.2, a: cream.3, width: width, height: height)
        let t = max(1, u)
        fillRect(rep: rep, x: bx - t, y: by, w: t, h: bh, r: border.0, g: border.1, b: border.2, a: border.3, width: width, height: height)
        fillRect(rep: rep, x: bx + bw, y: by, w: t, h: bh, r: border.0, g: border.1, b: border.2, a: border.3, width: width, height: height)
        fillRect(rep: rep, x: bx - t, y: by - t, w: bw + t * 2, h: t, r: border.0, g: border.1, b: border.2, a: border.3, width: width, height: height)
        fillRect(rep: rep, x: bx - t, y: by + bh, w: bw + t * 2, h: t, r: border.0, g: border.1, b: border.2, a: border.3, width: width, height: height)

        let cx = bx + bw / 2
        let strawW = max(2, u * 2)
        let strawTop = by - u * 5
        fillRect(rep: rep, x: cx - strawW / 2, y: strawTop, w: strawW, h: by - strawTop, r: straw.0, g: straw.1, b: straw.2, a: straw.3, width: width, height: height)

        let ox = bx + bw / 2 - u * 5
        let oy = by + bh / 2 - u * 5
        let appleCells: [(Int, Int)] = [
            (4, 0), (5, 0),
            (3, 1), (4, 1), (5, 1), (6, 1),
            (2, 2), (3, 2), (4, 2), (6, 2), (7, 2),
            (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3),
            (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
            (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
            (3, 6), (4, 6), (5, 6), (6, 6),
            (4, 7), (5, 7),
            (7, 0), (8, 0), (8, 1),
        ]
        for (dx, dy) in appleCells {
            fillRect(
                rep: rep, x: ox + dx * u, y: oy + dy * u, w: u, h: u,
                r: appleBlack.0, g: appleBlack.1, b: appleBlack.2, a: appleBlack.3,
                width: width, height: height
            )
        }
        fillRect(rep: rep, x: ox + 7 * u, y: oy + 1 * u, w: u, h: u, r: cream.0, g: cream.1, b: cream.2, a: cream.3, width: width, height: height)
        fillRect(rep: rep, x: ox + 8 * u, y: oy + 2 * u, w: u, h: u * 2, r: cream.0, g: cream.1, b: cream.2, a: cream.3, width: width, height: height)

        let lx = ox + 7 * u
        let ly = oy - u * 2
        fillRect(rep: rep, x: lx, y: ly, w: u * 2, h: u, r: leaf.0, g: leaf.1, b: leaf.2, a: leaf.3, width: width, height: height)
        fillRect(rep: rep, x: lx + u, y: ly - u, w: u * 2, h: u, r: leaf.0, g: leaf.1, b: leaf.2, a: leaf.3, width: width, height: height)
        fillRect(rep: rep, x: ox + 5 * u, y: oy - u * 2, w: u, h: u * 2, r: stem.0, g: stem.1, b: stem.2, a: stem.3, width: width, height: height)
    }

    /// Dracula Juice: white fangs under the mouth on the recolored can.
    private static func drawDraculaFangs(rep: NSBitmapImageRep, width: Int, height: Int, palette: ThemePalette) {
        let u = max(1, min(width, height) / 26)
        let cx = width / 2
        let mouthY = height * 58 / 100
        let fang = rgbaBytes(NSColor(white: 0.96, alpha: 1))
        let tip = rgbaBytes(NSColor(palette.border))
        fillRect(rep: rep, x: cx - 6 * u, y: mouthY, w: 2 * u, h: 3 * u, r: fang.0, g: fang.1, b: fang.2, a: fang.3, width: width, height: height)
        fillRect(rep: rep, x: cx + 3 * u, y: mouthY, w: 2 * u, h: 3 * u, r: fang.0, g: fang.1, b: fang.2, a: fang.3, width: width, height: height)
        fillRect(rep: rep, x: cx - 5 * u, y: mouthY + 3 * u, w: u, h: u, r: tip.0, g: tip.1, b: tip.2, a: tip.3, width: width, height: height)
        fillRect(rep: rep, x: cx + 4 * u, y: mouthY + 3 * u, w: u, h: u, r: tip.0, g: tip.1, b: tip.2, a: tip.3, width: width, height: height)
    }

    /// Deadly Juice: pixel skull over the bolt area.
    private static func drawSkullEmblem(rep: NSBitmapImageRep, width: Int, height: Int, palette: ThemePalette) {
        let u = max(1, min(width, height) / 26)
        let cx = width / 2
        let cy = height * 40 / 100
        let bone = rgbaBytes(NSColor(white: 0.9, alpha: 1))
        let shade = rgbaBytes(NSColor(white: 0.55, alpha: 1))
        let dark = rgbaBytes(NSColor(white: 0.12, alpha: 1))

        let skull: [(Int, Int, Int, Int)] = [
            (-4, -6, 9, 2),
            (-5, -4, 11, 2),
            (-6, -2, 13, 5),
            (-5, 3, 11, 2),
            (-4, 5, 9, 2),
        ]
        for (dx, dy, w, h) in skull {
            fillRect(
                rep: rep, x: cx + dx * u, y: cy + dy * u, w: w * u, h: h * u,
                r: bone.0, g: bone.1, b: bone.2, a: bone.3, width: width, height: height
            )
        }
        fillRect(rep: rep, x: cx - 2 * u, y: cy - 1 * u, w: u, h: u, r: dark.0, g: dark.1, b: dark.2, a: dark.3, width: width, height: height)
        fillRect(rep: rep, x: cx + 2 * u, y: cy - 1 * u, w: u, h: u, r: dark.0, g: dark.1, b: dark.2, a: dark.3, width: width, height: height)
        fillRect(rep: rep, x: cx - (u / 2), y: cy + 1 * u, w: u, h: u, r: dark.0, g: dark.1, b: dark.2, a: dark.3, width: width, height: height)
        fillRect(rep: rep, x: cx - 3 * u, y: cy + 3 * u, w: u, h: u, r: shade.0, g: shade.1, b: shade.2, a: shade.3, width: width, height: height)
        fillRect(rep: rep, x: cx - u, y: cy + 3 * u, w: u, h: u, r: shade.0, g: shade.1, b: shade.2, a: shade.3, width: width, height: height)
        fillRect(rep: rep, x: cx + u, y: cy + 3 * u, w: u, h: u, r: shade.0, g: shade.1, b: shade.2, a: shade.3, width: width, height: height)
        fillRect(rep: rep, x: cx + 3 * u, y: cy + 3 * u, w: u, h: u, r: shade.0, g: shade.1, b: shade.2, a: shade.3, width: width, height: height)
    }

    /// Moon Juice: crescent moon above the can.
    private static func drawMoonEmblem(rep: NSBitmapImageRep, width: Int, height: Int, palette: ThemePalette) {
        let moon = rgbaBytes(NSColor(palette.accentSecondary).blended(withFraction: 0.35, of: .white) ?? NSColor(palette.accentSecondary))
        let glowN = NSColor(palette.accent).usingColorSpace(.deviceRGB)?.withAlphaComponent(0.88) ?? NSColor.systemYellow.withAlphaComponent(0.88)
        let glow = rgbaBytes(glowN)
        let cx = Double(width) * 0.68
        let cy = Double(height) * 0.28
        let r0 = Double(min(width, height)) * 0.16
        let r1 = Double(min(width, height)) * 0.13
        let shift = Double(min(width, height)) * 0.07

        guard let data = rep.bitmapData else { return }
        let bpr = rep.bytesPerRow
        let x0 = max(0, Int(cx - r0 - 2))
        let x1 = min(width - 1, Int(cx + r0 + 2))
        let y0 = max(0, Int(cy - r0 - 2))
        let y1 = min(height - 1, Int(cy + r0 + 2))

        for y in y0...y1 {
            for x in x0...x1 {
                let dx = Double(x) - cx
                let dy = Double(y) - cy
                let d0 = dx * dx + dy * dy
                let dx1 = Double(x) - (cx + shift)
                let d1 = dx1 * dx1 + dy * dy
                if d0 <= r0 * r0 && d1 >= r1 * r1 {
                    let o = y * bpr + x * 4
                    let useGlow = d0 > (r0 - 2) * (r0 - 2)
                    let c = useGlow ? glow : moon
                    data[o] = c.0
                    data[o + 1] = c.1
                    data[o + 2] = c.2
                    data[o + 3] = 255
                }
            }
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
            let ns = MenuBarIcon.nsImage(forHeight: MenuBarIcon.pointSize, appearance: model.menuBarIconAppearance, palette: palette)
            let matchLift = model.menuBarIconAppearance == .matchTheme ? 0.055 : 0
            let activeLift = model.anyFeatureActive ? 0.12 : 0
            Image(nsImage: ns)
                .renderingMode(.original)
                .shadow(
                    color: model.menuBarIconAppearance == .menuBarMonochrome ? .clear : Color.black.opacity(0.42),
                    radius: 0,
                    x: 0,
                    y: 0.6
                )
                .brightness(matchLift + activeLift)
        }
        .menuBarExtraStyle(.window)
    }
}
