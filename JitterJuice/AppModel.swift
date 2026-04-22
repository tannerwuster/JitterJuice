import Combine
import Foundation

enum MenuBarIconAppearance: String, CaseIterable, Identifiable {
    case original
    /// Single-color template icon (tinted like other menu bar extras — reads as white on the dark menu bar).
    case menuBarMonochrome

    var id: String { rawValue }
}

final class AppModel: ObservableObject {
    private enum Keys {
        static let jiggle = "jiggleEnabled"
        static let power = "stayAwakeEnabled"
        static let interval = "jiggleIntervalSeconds"
        static let iconAppearance = "menuBarIconAppearance"
        static let idleOnly = "jiggleWhenIdleOnly"
        static let idleThreshold = "jiggleIdleThresholdSeconds"
        static let nudgePixels = "nudgePixels"
    }

    private let jiggler = MouseJiggler()
    private let power = PowerAssertionHolder()

    @Published var jiggleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(jiggleEnabled, forKey: Keys.jiggle)
            syncJiggle()
        }
    }

    @Published var stayAwakeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(stayAwakeEnabled, forKey: Keys.power)
            power.setActive(stayAwakeEnabled)
        }
    }

    /// Seconds between nudge attempts; clamped to 15...300 when written.
    @Published var jiggleIntervalSeconds: Int {
        didSet {
            let clamped = min(300, max(15, jiggleIntervalSeconds))
            guard clamped == jiggleIntervalSeconds else {
                jiggleIntervalSeconds = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Keys.interval)
            syncJiggle()
        }
    }

    /// Only nudge after the system reports at least this much keyboard/mouse idle time.
    @Published var jiggleWhenIdleOnly: Bool {
        didSet {
            UserDefaults.standard.set(jiggleWhenIdleOnly, forKey: Keys.idleOnly)
            syncJiggle()
        }
    }

    /// Required idle duration before a nudge can fire (when `jiggleWhenIdleOnly` is on).
    @Published var jiggleIdleThresholdSeconds: Int {
        didSet {
            let clamped = min(600, max(5, jiggleIdleThresholdSeconds))
            guard clamped == jiggleIdleThresholdSeconds else {
                jiggleIdleThresholdSeconds = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Keys.idleThreshold)
            syncJiggle()
        }
    }

    /// Cursor offset for each nudge (pixels right, then back).
    @Published var nudgePixels: Int {
        didSet {
            let clamped = min(25, max(1, nudgePixels))
            guard clamped == nudgePixels else {
                nudgePixels = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Keys.nudgePixels)
            syncJiggle()
        }
    }

    @Published var showAccessibilityHint = false

    @Published var menuBarIconAppearance: MenuBarIconAppearance {
        didSet {
            UserDefaults.standard.set(menuBarIconAppearance.rawValue, forKey: Keys.iconAppearance)
        }
    }

    var anyFeatureActive: Bool { jiggleEnabled || stayAwakeEnabled }

    init() {
        let defaults = UserDefaults.standard
        jiggleEnabled = defaults.object(forKey: Keys.jiggle) as? Bool ?? false
        stayAwakeEnabled = defaults.object(forKey: Keys.power) as? Bool ?? false
        let storedInterval = defaults.object(forKey: Keys.interval) as? Int ?? 45
        jiggleIntervalSeconds = min(300, max(15, storedInterval))
        jiggleWhenIdleOnly = defaults.object(forKey: Keys.idleOnly) as? Bool ?? false
        let storedIdle = defaults.object(forKey: Keys.idleThreshold) as? Int ?? 60
        jiggleIdleThresholdSeconds = min(600, max(5, storedIdle))
        let storedNudge = defaults.object(forKey: Keys.nudgePixels) as? Int ?? 1
        nudgePixels = min(25, max(1, storedNudge))
        if let raw = defaults.string(forKey: Keys.iconAppearance),
           let mode = MenuBarIconAppearance(rawValue: raw) {
            menuBarIconAppearance = mode
        } else {
            menuBarIconAppearance = .original
        }
        power.setActive(stayAwakeEnabled)
        syncJiggle()
    }

    /// Call when enabling jiggle from UI; returns whether jiggle stayed/was enabled.
    func requestJiggle(_ enabled: Bool) -> Bool {
        if enabled {
            if !AccessibilityPrompt.isTrusted {
                _ = AccessibilityPrompt.ensureTrusted(prompt: true)
            }
            guard AccessibilityPrompt.isTrusted else {
                showAccessibilityHint = true
                return false
            }
        }
        jiggleEnabled = enabled
        return true
    }

    func applyIntervalFromStepper(_ value: Int) {
        jiggleIntervalSeconds = min(300, max(15, value))
    }

    func applyIdleThresholdFromStepper(_ value: Int) {
        jiggleIdleThresholdSeconds = min(600, max(5, value))
    }

    func applyNudgePixelsFromStepper(_ value: Int) {
        nudgePixels = min(25, max(1, value))
    }

    private func syncJiggle() {
        jiggler.setEnabled(
            jiggleEnabled,
            intervalSeconds: TimeInterval(jiggleIntervalSeconds),
            nudgePixels: CGFloat(nudgePixels),
            jiggleWhenIdleOnly: jiggleWhenIdleOnly,
            idleThresholdSeconds: TimeInterval(jiggleIdleThresholdSeconds)
        )
    }
}
