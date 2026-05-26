import AppKit
import CoreGraphics
import Foundation

/// Nudges the cursor by a few points and back so the system idle timer resets.
final class MouseJiggler {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.jitterjuice.mousejiggler", qos: .utility)
    private var motionTimer: DispatchSourceTimer?
    private var motionInFlight = false

    private var nudgePixels: CGFloat = 1
    private var jiggleMode: JiggleMode = .circle360
    private var jiggleWhenIdleOnly = false
    private var idleThresholdSeconds: TimeInterval = 60

    func setEnabled(
        _ enabled: Bool,
        intervalSeconds: TimeInterval,
        nudgePixels: CGFloat,
        jiggleMode: JiggleMode,
        jiggleWhenIdleOnly: Bool,
        idleThresholdSeconds: TimeInterval
    ) {
        timer?.cancel()
        timer = nil
        motionTimer?.cancel()
        motionTimer = nil
        motionInFlight = false
        guard enabled, intervalSeconds > 0 else { return }

        self.nudgePixels = max(1, nudgePixels)
        self.jiggleMode = jiggleMode
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
        // Very small radii can get quantized/coalesced and look like a straight line.
        let rDesiredBase = max(4, nudgePixels)
        let clampFrame = clampFrameForPoint(p)

        switch jiggleMode {
        case .circle360:
            // Full circle around the point, then return.
            // Make 360° mode visibly "wide" without affecting Up/Down amplitude.
            let desired = max(12, rDesiredBase * 4)
            let r = circleRadius360(around: p, desired: desired, frame: clampFrame)
            startArcMotion(
                kind: .circle360,
                center: p,
                radius: r,
                frame: clampFrame
            )

        case .upDown:
            let up = CGPoint(x: p.x, y: p.y + rDesiredBase)
            postMouseMoved(to: clampToScreen(up, frame: clampFrame))
            postMouseMoved(to: clampToScreen(p, frame: clampFrame))
        }
    }

    private func postMouseMoved(to point: CGPoint) {
        let q = quartzPoint(fromAppKit: point)
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: q,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }

    private func postMouseMoved(at point: CGPoint, deltaX: CGFloat, deltaY: CGFloat) {
        let q = quartzPoint(fromAppKit: point)
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: q,
            mouseButton: .left
        ) else { return }
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX.rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY.rounded()))
        event.post(tap: .cghidEventTap)
    }

    /// `NSEvent.mouseLocation` is AppKit global space (origin bottom-left, y up). `CGEvent` positions use
    /// Quartz global space per display (origin top-left of each display in pixel space). Mapping via
    /// `max(NSScreen.frame.maxY) - y` is wrong on Retina / multi-display and skews motion (often vertical).
    private func quartzPoint(fromAppKit p: CGPoint) -> CGPoint {
        let screens = NSScreen.screens
        guard let screen = screens.first(where: { $0.frame.contains(p) }) ?? NSScreen.main,
              let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return quartzPointLegacyFlip(p)
        }
        let displayID = CGDirectDisplayID(truncating: num)
        let bounds = CGDisplayBounds(displayID)
        let frame = screen.frame
        guard frame.width > 0, frame.height > 0, bounds.width > 0, bounds.height > 0 else {
            return quartzPointLegacyFlip(p)
        }
        let relX = p.x - frame.minX
        let relY = p.y - frame.minY
        let px = (relX / frame.width) * bounds.width
        let pyFromBottom = (relY / frame.height) * bounds.height
        return CGPoint(
            x: bounds.origin.x + px,
            y: bounds.origin.y + (bounds.height - pyFromBottom)
        )
    }

    private func quartzPointLegacyFlip(_ p: CGPoint) -> CGPoint {
        let globalMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? 0
        return CGPoint(x: p.x, y: globalMaxY - p.y)
    }
    
    private func clampFrameForPoint(_ point: CGPoint) -> CGRect {
        let screens = NSScreen.screens
        let screen = screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
        // Use full screen frame (not visibleFrame) so we don't "snap" when near menu bar / dock edges.
        return (screen?.frame).map { $0 } ?? CGRect(x: 0, y: 0, width: 10_000, height: 10_000)
    }
    
    private func clampToScreen(_ point: CGPoint, frame f: CGRect) -> CGPoint {
        // Keep 1pt inside bounds so the cursor move is valid.
        let x = min(f.maxX - 1, max(f.minX + 1, point.x))
        let y = min(f.maxY - 1, max(f.minY + 1, point.y))
        return CGPoint(x: x, y: y)
    }
    
    /// Pick a radius that keeps a full circle centered on `point` inside `frame`.
    /// This avoids "pre-nudging" the cursor by shifting the circle center.
    private func circleRadius360(around point: CGPoint, desired r: CGFloat, frame f: CGRect) -> CGFloat {
        let inset: CGFloat = 1
        let left = point.x - (f.minX + inset)
        let right = (f.maxX - inset) - point.x
        let down = point.y - (f.minY + inset)
        let up = (f.maxY - inset) - point.y
        let limit = max(0, min(left, right, down, up))
        return max(1, min(r, limit))
    }

    private enum ArcMotionKind: String {
        case circle360
    }

    private func startArcMotion(kind: ArcMotionKind, center: CGPoint, radius: CGFloat, frame: CGRect) {
        // If a motion is already running, skip starting another (prevents stacking).
        guard !motionInFlight else { return }
        motionInFlight = true
        motionTimer?.cancel()
        motionTimer = nil

        // Start on +X from center so motion doesn’t read as a vertical “nudge” before the loop.
        let startAngle: CGFloat = 0
        let steps: Int = (kind == .circle360) ? 45 : 17
        let totalAngle: CGFloat = (kind == .circle360) ? (.pi * 2) : .pi
        var i = 0

        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: .milliseconds(12), leeway: .milliseconds(2))
        source.setEventHandler { [weak self] in
            guard let self else { return }
            if i > steps {
                source.cancel()
                self.motionInFlight = false
                self.postMouseMoved(to: self.clampToScreen(center, frame: frame))
                return
            }
            let t = CGFloat(i) / CGFloat(steps)
            let a = startAngle + t * totalAngle
            let dx = cos(a) * radius
            let dy = sin(a) * radius
            let pt = CGPoint(x: center.x + dx, y: center.y + dy)
            let clamped = self.clampToScreen(pt, frame: frame)
            self.postMouseMoved(to: clamped)
            i += 1
        }
        source.resume()
        motionTimer = source
    }

    deinit {
        timer?.cancel()
        motionTimer?.cancel()
    }
}
