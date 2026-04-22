import AppKit
import SwiftUI

enum ThemeColorUtils {
    /// Returns normalized 6-char uppercase hex, or nil.
    static func normalizeHex(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
        guard s.count == 6, s.allSatisfy({ $0.isHexDigit }) else { return nil }
        return s
    }

    static func color(fromHex6 hex: String) -> Color? {
        guard let n = normalizeHex(hex), let v = UInt32(n, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }

    static func rgbFromHex(_ hex: String) -> (r: Int, g: Int, b: Int) {
        guard let n = normalizeHex(hex), let v = UInt32(n, radix: 16) else { return (0, 0, 0) }
        return (Int((v >> 16) & 0xFF), Int((v >> 8) & 0xFF), Int(v & 0xFF))
    }

    static func hexFromRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        let rr = min(255, max(0, r))
        let gg = min(255, max(0, g))
        let bb = min(255, max(0, b))
        return String(format: "%02X%02X%02X", rr, gg, bb)
    }

    /// WCAG relative luminance in sRGB, ~0…1.
    static func relativeLuminance(_ color: Color) -> CGFloat {
        guard let c = NSColor(color).usingColorSpace(.deviceRGB) else { return 0.5 }
        func lin(_ u: CGFloat) -> CGFloat {
            u <= 0.03928 ? u / 12.92 : pow((u + 0.055) / 1.055, 2.4)
        }
        let r = lin(c.redComponent)
        let g = lin(c.greenComponent)
        let b = lin(c.blueComponent)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Mix `a` toward `b` by `t` (0 = all a, 1 = all b).
    static func mix(_ a: Color, _ b: Color, t: CGFloat) -> Color {
        guard let ca = NSColor(a).usingColorSpace(.deviceRGB),
              let cb = NSColor(b).usingColorSpace(.deviceRGB) else { return a }
        let u = max(0, min(1, t))
        let r = ca.redComponent * (1 - u) + cb.redComponent * u
        let g = ca.greenComponent * (1 - u) + cb.greenComponent * u
        let bl = ca.blueComponent * (1 - u) + cb.blueComponent * u
        return Color(red: Double(r), green: Double(g), blue: Double(bl))
    }
}
