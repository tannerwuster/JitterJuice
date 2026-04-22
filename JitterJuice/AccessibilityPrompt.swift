import AppKit
import ApplicationServices
import Foundation

enum AccessibilityPrompt {
    /// Returns whether this app may post synthetic events (requires user approval in System Settings).
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// If `prompt` is true, may show the system prompt once when not trusted.
    static func ensureTrusted(prompt: Bool = false) -> Bool {
        if isTrusted { return true }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
