import AppKit
import SwiftUI

enum MenuBarIcon {
    /// Menu bar icon height in **points** (typical range ~18–28). Rebuild and relaunch after changing.
    static let pointSize: CGFloat = 28

    private struct CacheKey: Hashable {
        let height: CGFloat
        let appearance: MenuBarIconAppearance
    }

    private static var cache: [CacheKey: NSImage] = [:]

    static func nsImage(forHeight height: CGFloat, appearance: MenuBarIconAppearance) -> NSImage {
        let key = CacheKey(height: height, appearance: appearance)
        if let cached = cache[key] { return cached }
        let made = rasterizeMenuIcon(heightPoints: height, appearance: appearance)
        cache[key] = made
        return made
    }

    private static func rasterizeMenuIcon(heightPoints: CGFloat, appearance: MenuBarIconAppearance) -> NSImage {
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

    private static func classifyMonochromePixel(r: CGFloat, g: CGFloat, b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
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

        // Yellow / gold lightning (and bright yellow sparkles)
        if h >= 35 && h <= 88 && s > 0.18 && maxv > 0.32 {
            return (0, 0, 0)
        }

        // Near-black: eyes, mouth, dark outlines
        if maxv < 0.30 {
            return (0, 0, 0)
        }

        // Purple / magenta can body & blush that leans purple
        let purpleHue = (h >= 240 && h <= 330) || (b > r + 0.08 && b > g + 0.05 && maxv > 0.18)
        if purpleHue && s > 0.12 {
            return (1, 1, 1)
        }

        // Silver rims & very light neutrals
        if s < 0.14 && maxv > 0.42 {
            return (1, 1, 1)
        }

        // Purple-tinted sparkles (high B, medium R)
        if b > 0.45 && r > 0.25 && maxv > 0.55 {
            return (1, 1, 1)
        }

        // Default mid-tones on the can → white
        if maxv > 0.35 {
            return (1, 1, 1)
        }

        return (0, 0, 0)
    }
}

@main
struct JitterJuiceApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(model: model)
        } label: {
            Image(nsImage: MenuBarIcon.nsImage(forHeight: MenuBarIcon.pointSize, appearance: model.menuBarIconAppearance))
                .renderingMode(.original)
                .brightness(model.anyFeatureActive ? 0.12 : 0)
        }
        .menuBarExtraStyle(.window)
    }
}
