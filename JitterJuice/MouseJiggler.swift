import AppKit
import CoreGraphics
import Foundation

/// Nudges the cursor by a few points and back so the system idle timer resets.
final class MouseJiggler {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.jitterjuice.mousejiggler", qos: .utility)

    private var nudgePixels: CGFloat = 1
    private var jiggleWhenIdleOnly = false
    private var idleThresholdSeconds: TimeInterval = 60

    func setEnabled(
        _ enabled: Bool,
        intervalSeconds: TimeInterval,
        nudgePixels: CGFloat,
        jiggleWhenIdleOnly: Bool,
        idleThresholdSeconds: TimeInterval
    ) {
        timer?.cancel()
        timer = nil
        guard enabled, intervalSeconds > 0 else { return }

        self.nudgePixels = max(1, nudgePixels)
        self.jiggleWhenIdleOnly = jiggleWhenIdleOnly
        self.idleThresholdSeconds = max(0, idleThresholdSeconds)

        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now() + intervalSeconds, repeating: intervalSeconds, leeway: .seconds(1))
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        timer = source
    }

    private func tick() {
        if jiggleWhenIdleOnly {
            let idle = Self.systemWideIdleSeconds()
            guard idle >= idleThresholdSeconds else { return }
        }
        nudge()
    }

    /// Shortest “time since last activity” across common HID event types (keyboard, mouse, scroll).
    private static func systemWideIdleSeconds() -> TimeInterval {
        let types: [CGEventType] = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel,
            .mouseMoved,
        ]
        var shortest = TimeInterval.greatestFiniteMagnitude
        for type in types {
            let t = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: type)
            if t.isFinite, t >= 0 {
                shortest = min(shortest, t)
            }
        }
        return shortest == .greatestFiniteMagnitude ? 0 : shortest
    }

    private func nudge() {
        let p = NSEvent.mouseLocation
        let delta = nudgePixels
        let shifted = CGPoint(x: p.x + delta, y: p.y)
        postMouseMoved(to: shifted)
        postMouseMoved(to: p)
    }

    private func postMouseMoved(to point: CGPoint) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }

    deinit {
        timer?.cancel()
    }
}
