import AppKit
import CoreGraphics
import Foundation

/// Nudges the cursor by a few points and back so the system idle timer resets.
final class MouseJiggler {
    private static let buildTag = "motionTimer-v1"
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

        // #region agent log
        jjLog(
            hypothesisId: "H1",
            location: "MouseJiggler.swift:nudge:start",
            message: "nudge start",
            data: [
                "buildTag": Self.buildTag,
                "mode": jiggleMode.rawValue,
                "p": ["x": p.x, "y": p.y],
                "nudgePixels": Double(nudgePixels),
                "rDesired": Double(rDesiredBase),
                "frame": ["minX": clampFrame.minX, "minY": clampFrame.minY, "maxX": clampFrame.maxX, "maxY": clampFrame.maxY],
            ]
        )
        // #endregion

        switch jiggleMode {
        case .circle360:
            // Full circle around the point, then return.
            // Make 360° mode visibly "wide" without affecting Up/Down amplitude.
            let desired = max(12, rDesiredBase * 4)
            let r = circleRadius360(around: p, desired: desired, frame: clampFrame)
            // #region agent log
            jjLog(
                hypothesisId: "H2",
                location: "MouseJiggler.swift:nudge:circle360",
                message: "circle360 radius",
                data: ["r": Double(r), "desired": Double(desired)]
            )
            // #endregion
            startArcMotion(
                kind: .circle360,
                center: p,
                radius: r,
                frame: clampFrame
            )

        case .upDown:
            let up = CGPoint(x: p.x, y: p.y + rDesiredBase)
            // #region agent log
            jjLog(
                hypothesisId: "H4",
                location: "MouseJiggler.swift:nudge:upDown",
                message: "upDown",
                data: [
                    "up": ["x": up.x, "y": up.y],
                    "upClamped": ["x": clampToScreen(up, frame: clampFrame).x, "y": clampToScreen(up, frame: clampFrame).y],
                ]
            )
            // #endregion
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

    private func quartzPoint(fromAppKit p: CGPoint) -> CGPoint {
        // CGEvent cursor positions use a flipped global Y compared to NSEvent.mouseLocation on this app's setup.
        // Evidence: observed jumps where y -> frame.maxY - y (see debug log H8).
        let globalMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? 0
        let q = CGPoint(x: p.x, y: globalMaxY - p.y)
        // #region agent log
        jjLog(
            hypothesisId: "H9",
            location: "MouseJiggler.swift:quartzPoint",
            message: "convert appkit->quartz",
            data: [
                "globalMaxY": globalMaxY,
                "in": ["x": p.x, "y": p.y],
                "out": ["x": q.x, "y": q.y],
            ]
        )
        // #endregion
        return q
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
        guard !motionInFlight else {
            // #region agent log
            jjLog(
                hypothesisId: "H5",
                location: "MouseJiggler.swift:motion:skip",
                message: "motion already in flight",
                data: ["kind": kind.rawValue]
            )
            // #endregion
            return
        }
        motionInFlight = true
        motionTimer?.cancel()
        motionTimer = nil

        let startAngle: CGFloat = .pi / 4
        let steps: Int = (kind == .circle360) ? 45 : 17
        let totalAngle: CGFloat = (kind == .circle360) ? (.pi * 2) : .pi
        var i = 0

        // #region agent log
        jjLog(
            hypothesisId: "H6",
            location: "MouseJiggler.swift:motion:start",
            message: "start motion timer",
            data: [
                "buildTag": Self.buildTag,
                "kind": kind.rawValue,
                "steps": steps,
                "center": ["x": center.x, "y": center.y],
                "radius": Double(radius),
            ]
        )
        // #endregion

        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: .milliseconds(12), leeway: .milliseconds(2))
        source.setEventHandler { [weak self] in
            guard let self else { return }
            if i > steps {
                source.cancel()
                self.motionInFlight = false
                self.postMouseMoved(to: self.clampToScreen(center, frame: frame))
                // #region agent log
                self.jjLog(
                    hypothesisId: "H6",
                    location: "MouseJiggler.swift:motion:end",
                    message: "motion ended",
                    data: ["kind": kind.rawValue]
                )
                // #endregion
                return
            }
            let t = CGFloat(i) / CGFloat(steps)
            let a = startAngle + t * totalAngle
            let dx = cos(a) * radius
            let dy = sin(a) * radius
            let pt = CGPoint(x: center.x + dx, y: center.y + dy)
            let clamped = self.clampToScreen(pt, frame: frame)

            // #region agent log
            // Measure real cursor movement (what the user sees).
            if i == 0 || i == steps / 2 || i == steps {
                let before = NSEvent.mouseLocation
                self.jjLog(
                    hypothesisId: "H8",
                    location: "MouseJiggler.swift:motion:cursorBefore",
                    message: "cursor before post",
                    data: [
                        "kind": kind.rawValue,
                        "i": i,
                        "cursor": ["x": before.x, "y": before.y],
                        "center": ["x": center.x, "y": center.y],
                    ]
                )
            }
            // #endregion
            if i <= 3 || i == steps / 2 || i == steps {
                // #region agent log
                self.jjLog(
                    hypothesisId: "H7",
                    location: "MouseJiggler.swift:motion:pt",
                    message: "motion point",
                    data: [
                        "kind": kind.rawValue,
                        "i": i,
                        "pt": ["x": pt.x, "y": pt.y],
                        "clamped": ["x": clamped.x, "y": clamped.y],
                        "clampedChanged": (pt.x != clamped.x) || (pt.y != clamped.y),
                        "delta": ["dx": clamped.x - center.x, "dy": clamped.y - center.y],
                        "postedAtCenter": false,
                    ]
                )
                // #endregion
            }
            // Actually move the cursor along the arc so 180° vs 360° are visibly different.
            self.postMouseMoved(to: clamped)

            // #region agent log
            if i == 0 || i == steps / 2 || i == steps {
                let after = NSEvent.mouseLocation
                self.jjLog(
                    hypothesisId: "H8",
                    location: "MouseJiggler.swift:motion:cursorAfter",
                    message: "cursor after post",
                    data: [
                        "kind": kind.rawValue,
                        "i": i,
                        "cursor": ["x": after.x, "y": after.y],
                        "center": ["x": center.x, "y": center.y],
                        "moved": ["dx": after.x - center.x, "dy": after.y - center.y],
                    ]
                )
            }
            // #endregion
            i += 1
        }
        source.resume()
        motionTimer = source
    }

    // #region agent log
    private func jjLog(hypothesisId: String, location: String, message: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "sessionId": "717e91",
            "runId": "pre-fix",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        guard let line = (try? JSONSerialization.data(withJSONObject: payload)) else { return }
        let url = URL(fileURLWithPath: "/Users/tannerwuster/Documents/CodingProjects/JitterJuice/.cursor/debug-717e91.log")
        if let h = try? FileHandle(forWritingTo: url) {
            try? h.seekToEnd()
            try? h.write(contentsOf: line)
            try? h.write(contentsOf: Data([0x0A]))
            try? h.close()
        } else {
            // First log of the session creates the file.
            try? line.write(to: url, options: .atomic)
            try? FileHandle(forWritingTo: url).close()
            // Ensure newline for NDJSON readers.
            if let h2 = try? FileHandle(forWritingTo: url) {
                try? h2.seekToEnd()
                try? h2.write(contentsOf: Data([0x0A]))
                try? h2.close()
            }
        }
    }
    // #endregion

    deinit {
        timer?.cancel()
        motionTimer?.cancel()
    }
}
