import Combine
import Foundation

// MARK: - Stay awake schedule (local time)

enum StayAwakeSchedule {
    /// `start`/`end` are minutes from midnight (0…1439). Awake in `[start, end)` when `start < end`, else overnight `[start, end)` wrapping midnight.
    static func isWithinActiveWindow(
        now: Date = Date(),
        startMinute: Int,
        endMinute: Int,
        calendar: Calendar = .current
    ) -> Bool {
        let start = clampMinutes(startMinute)
        let end = clampMinutes(endMinute)
        if start == end { return true }
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if start < end {
            return m >= start && m < end
        }
        return m >= start || m < end
    }

    private static func clampMinutes(_ v: Int) -> Int {
        min(1439, max(0, v))
    }

    /// Minutes from midnight for awake-window pickers.
    static func clampDayMinute(_ v: Int) -> Int {
        min(1439, max(0, v))
    }
}

enum MenuBarIconAppearance: String, CaseIterable, Identifiable {
    case original
    /// Single-color template icon (tinted like other menu bar extras — reads as white on the dark menu bar).
    case menuBarMonochrome
    /// Recolors the pixel can using the current theme’s main (body) and accent (lightning) colors.
    case matchTheme

    var id: String { rawValue }
}

final class AppModel: ObservableObject {
    static let defaultCustomMainHex = "24133F"
    static let defaultCustomAccentHex = "FFE938"

    private enum Keys {
        static let jiggle = "jiggleEnabled"
        static let power = "stayAwakeEnabled"
        static let interval = "jiggleIntervalSeconds"
        static let iconAppearance = "menuBarIconAppearance"
        static let idleOnly = "jiggleWhenIdleOnly"
        static let idleThreshold = "jiggleIdleThresholdSeconds"
        static let nudgePixels = "nudgePixels"
        static let appTheme = "appTheme"
        static let customMainHex = "customThemeMainHex"
        static let customAccentHex = "customThemeAccentHex"
        static let customInputUsesRGB = "customThemeInputUsesRGB"
        static let stayAwakeAutoStopMinutes = "stayAwakeAutoStopMinutes"
        static let stayAwakeTimerFire = "stayAwakeTimerFireInterval"
        static let stayAwakeScheduleEnabled = "stayAwakeScheduleEnabled"
        static let stayAwakeDailyStartMinute = "stayAwakeDailyStartMinute"
        static let stayAwakeDailyEndMinute = "stayAwakeDailyEndMinute"
    }

    private let jiggler = MouseJiggler()
    private let power = PowerAssertionHolder()
    private var powerTick: AnyCancellable?
    /// Skips timer arming / `syncStayAwakePower` while loading `UserDefaults` in `init`.
    private var isLoadingStayAwakeState = false

    @Published var jiggleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(jiggleEnabled, forKey: Keys.jiggle)
            syncJiggle()
        }
    }

    @Published var stayAwakeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(stayAwakeEnabled, forKey: Keys.power)
            if !isLoadingStayAwakeState {
                if stayAwakeEnabled {
                    armTimerIfNeeded()
                } else {
                    stayAwakeTimerFireDate = nil
                }
                syncStayAwakePower()
            }
        }
    }

    /// 0 = no auto-stop; otherwise stop after this many minutes (re-armed from each enable).
    @Published var stayAwakeAutoStopMinutes: Int {
        didSet {
            let c = min(24 * 60, max(0, stayAwakeAutoStopMinutes))
            guard c == stayAwakeAutoStopMinutes else {
                stayAwakeAutoStopMinutes = c
                return
            }
            UserDefaults.standard.set(c, forKey: Keys.stayAwakeAutoStopMinutes)
            if !isLoadingStayAwakeState {
                if stayAwakeEnabled {
                    armTimerIfNeeded()
                }
                syncStayAwakePower()
            }
        }
    }

    /// When set and `stayAwakeAutoStopMinutes > 0`, display sleep is prevented only until this time.
    @Published private(set) var stayAwakeTimerFireDate: Date? {
        didSet { persistTimerFireDate() }
    }

    /// When true, stay awake only during the daily window (`stayAwakeDailyStartMinute` … `stayAwakeDailyEndMinute`).
    @Published var stayAwakeScheduleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(stayAwakeScheduleEnabled, forKey: Keys.stayAwakeScheduleEnabled)
            if !isLoadingStayAwakeState {
                syncStayAwakePower()
            }
        }
    }

    /// Minutes from midnight when the daily awake window starts (default 6:00).
    @Published var stayAwakeDailyStartMinute: Int {
        didSet {
            let c = StayAwakeSchedule.clampDayMinute(stayAwakeDailyStartMinute)
            guard c == stayAwakeDailyStartMinute else {
                stayAwakeDailyStartMinute = c
                return
            }
            UserDefaults.standard.set(c, forKey: Keys.stayAwakeDailyStartMinute)
            if !isLoadingStayAwakeState {
                syncStayAwakePower()
            }
        }
    }

    /// Minutes from midnight when the daily awake window ends (default 17:00).
    @Published var stayAwakeDailyEndMinute: Int {
        didSet {
            let c = StayAwakeSchedule.clampDayMinute(stayAwakeDailyEndMinute)
            guard c == stayAwakeDailyEndMinute else {
                stayAwakeDailyEndMinute = c
                return
            }
            UserDefaults.standard.set(c, forKey: Keys.stayAwakeDailyEndMinute)
            if !isLoadingStayAwakeState {
                syncStayAwakePower()
            }
        }
    }

    /// True when the display assertion is actually held (respects timer, schedule, and toggle).
    @Published private(set) var stayAwakeEffectiveActive: Bool = false

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

    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: Keys.appTheme)
        }
    }

    /// Up to six hex digits (no `#`), used when `appTheme == .custom` for the main / background color.
    @Published var customThemeMainHex: String {
        didSet {
            UserDefaults.standard.set(customThemeMainHex, forKey: Keys.customMainHex)
        }
    }

    /// Up to six hex digits (no `#`), used when `appTheme == .custom` for borders, toggles, and accents.
    @Published var customThemeAccentHex: String {
        didSet {
            UserDefaults.standard.set(customThemeAccentHex, forKey: Keys.customAccentHex)
        }
    }

    /// When true, custom color fields edit as R / G / B (0…255); when false, as hex strings.
    @Published var customThemeInputUsesRGB: Bool {
        didSet {
            UserDefaults.standard.set(customThemeInputUsesRGB, forKey: Keys.customInputUsesRGB)
        }
    }

    /// First help-tooltip in a session uses a typewriter effect; after that, full text shows immediately.
    @Published private(set) var tooltipTypewriterPlayedThisSession = false

    func markTooltipTypewriterFinished() {
        tooltipTypewriterPlayedThisSession = true
    }

    var anyFeatureActive: Bool { jiggleEnabled || stayAwakeEffectiveActive }

    init() {
        let defaults = UserDefaults.standard
        jiggleEnabled = defaults.object(forKey: Keys.jiggle) as? Bool ?? false
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
        if let raw = defaults.string(forKey: Keys.appTheme),
           let t = AppTheme(rawValue: raw) {
            appTheme = t
        } else {
            appTheme = .eightBit
        }
        customThemeMainHex = Self.sanitizedHexDigits(
            defaults.string(forKey: Keys.customMainHex) ?? Self.defaultCustomMainHex
        )
        customThemeAccentHex = Self.sanitizedHexDigits(
            defaults.string(forKey: Keys.customAccentHex) ?? Self.defaultCustomAccentHex
        )
        customThemeInputUsesRGB = defaults.object(forKey: Keys.customInputUsesRGB) as? Bool ?? false

        isLoadingStayAwakeState = true
        stayAwakeAutoStopMinutes = min(24 * 60, max(0, defaults.object(forKey: Keys.stayAwakeAutoStopMinutes) as? Int ?? 0))
        stayAwakeScheduleEnabled = defaults.object(forKey: Keys.stayAwakeScheduleEnabled) as? Bool ?? false
        stayAwakeDailyStartMinute = StayAwakeSchedule.clampDayMinute(
            defaults.object(forKey: Keys.stayAwakeDailyStartMinute) as? Int ?? (6 * 60 + 0)
        )
        stayAwakeDailyEndMinute = StayAwakeSchedule.clampDayMinute(
            defaults.object(forKey: Keys.stayAwakeDailyEndMinute) as? Int ?? (17 * 60 + 0)
        )
        stayAwakeEnabled = defaults.object(forKey: Keys.power) as? Bool ?? false
        if stayAwakeAutoStopMinutes == 0 {
            stayAwakeTimerFireDate = nil
        } else if let ts = defaults.object(forKey: Keys.stayAwakeTimerFire) as? TimeInterval {
            let d = Date(timeIntervalSince1970: ts)
            stayAwakeTimerFireDate = (stayAwakeEnabled && d > Date()) ? d : nil
        } else {
            stayAwakeTimerFireDate = nil
        }
        isLoadingStayAwakeState = false
        if stayAwakeEnabled, stayAwakeAutoStopMinutes > 0, stayAwakeTimerFireDate == nil {
            armTimerIfNeeded()
        }
        if stayAwakeEnabled, stayAwakeAutoStopMinutes > 0, let end = stayAwakeTimerFireDate, end <= Date() {
            stayAwakeTimerFireDate = nil
            stayAwakeEnabled = false
        }

        syncStayAwakePower()
        syncJiggle()
        powerTick = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshStayAwakeTick()
            }
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

    func stayAwakeStatusLine(now: Date = Date()) -> String? {
        guard stayAwakeEnabled else { return nil }
        var parts: [String] = []
        if stayAwakeAutoStopMinutes > 0, let end = stayAwakeTimerFireDate {
            let s = max(0, Int(end.timeIntervalSince(now).rounded(.down)))
            if s > 0 {
                let h = s / 3600
                let m = (s % 3600) / 60
                let sec = s % 60
                if h > 0 {
                    parts.append("Timer \(h)h \(m)m")
                } else if m > 0 {
                    parts.append("Timer \(m)m \(sec)s")
                } else {
                    parts.append("Timer \(sec)s")
                }
            }
        }
        if stayAwakeScheduleEnabled {
            if StayAwakeSchedule.isWithinActiveWindow(
                now: now,
                startMinute: stayAwakeDailyStartMinute,
                endMinute: stayAwakeDailyEndMinute
            ) {
                parts.append("In daily window")
            } else {
                parts.append("Outside window — idle until \(Self.formatMinuteAsTime(stayAwakeDailyStartMinute))")
            }
        }
        if parts.isEmpty {
            parts.append("On until you turn off")
        }
        return parts.joined(separator: " · ")
    }

    private func refreshStayAwakeTick() {
        expireStayAwakeTimerIfNeeded()
        syncStayAwakePower()
    }

    private func expireStayAwakeTimerIfNeeded() {
        guard stayAwakeEnabled, let end = stayAwakeTimerFireDate, Date() >= end else { return }
        stayAwakeTimerFireDate = nil
        stayAwakeEnabled = false
    }

    private func armTimerIfNeeded() {
        guard stayAwakeEnabled, stayAwakeAutoStopMinutes > 0 else {
            stayAwakeTimerFireDate = nil
            return
        }
        stayAwakeTimerFireDate = Date().addingTimeInterval(TimeInterval(stayAwakeAutoStopMinutes * 60))
    }

    private func persistTimerFireDate() {
        if let d = stayAwakeTimerFireDate {
            UserDefaults.standard.set(d.timeIntervalSince1970, forKey: Keys.stayAwakeTimerFire)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.stayAwakeTimerFire)
        }
    }

    private func syncStayAwakePower() {
        expireStayAwakeTimerIfNeeded()
        let on = computeEffectiveStayAwakePower()
        power.setActive(on)
        if stayAwakeEffectiveActive != on {
            stayAwakeEffectiveActive = on
        }
    }

    private func computeEffectiveStayAwakePower() -> Bool {
        guard stayAwakeEnabled else { return false }
        if let end = stayAwakeTimerFireDate, Date() >= end {
            return false
        }
        if stayAwakeScheduleEnabled,
           !StayAwakeSchedule.isWithinActiveWindow(
            now: Date(),
            startMinute: stayAwakeDailyStartMinute,
            endMinute: stayAwakeDailyEndMinute
           ) {
            return false
        }
        return true
    }

    private static func formatMinuteAsTime(_ minute: Int) -> String {
        let m = min(1439, max(0, minute))
        let h24 = m / 60
        let mm = m % 60
        let cal = Calendar.current
        var comps = DateComponents()
        comps.hour = h24
        comps.minute = mm
        let date = cal.date(from: comps) ?? Date()
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
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

    private static func sanitizedHexDigits(_ raw: String) -> String {
        String(raw.uppercased().filter(\.isHexDigit).prefix(6))
    }

    func applyCustomMainHexInput(_ raw: String) {
        customThemeMainHex = Self.sanitizedHexDigits(raw)
    }

    func applyCustomAccentHexInput(_ raw: String) {
        customThemeAccentHex = Self.sanitizedHexDigits(raw)
    }
}
