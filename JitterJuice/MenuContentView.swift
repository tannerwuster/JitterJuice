import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var model: AppModel
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if showSettings {
                    settingsPanel
                } else {
                    mainPanel
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .padding(.trailing, showSettings ? 0 : 12)

            if !showSettings {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
                .padding(.trailing, 10)
                .padding(.bottom, 14)
            }
        }
        .frame(minWidth: 320)
    }

    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("JitterJuice")
                .font(.headline)

            Toggle(isOn: jiggleBinding) {
                toggleLabelWithTooltip(
                    title: "Jiggle Mouse",
                    tip: """
                    Moves the cursor during a time interval you choose—thrilling, I know. Turn it on to set the interval right below. Open Settings for idle-only mode and nudge distance. Requires Accessibility, because apparently moving pixels is a privileged operation.
                    """
                )
            }

            if model.jiggleEnabled {
                Stepper(value: Binding(
                    get: { model.jiggleIntervalSeconds },
                    set: { model.applyIntervalFromStepper($0) }
                ), in: 15...300, step: 5) {
                    Text("Every \(model.jiggleIntervalSeconds) seconds")
                }
                .padding(.leading, 22)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Toggle(isOn: $model.stayAwakeEnabled) {
                toggleLabelWithTooltip(
                    title: "Wakey Wakey",
                    tip: """
                    Politely bullies the display into staying awake. MacOS may still yawn and sleep if it’s feeling stubborn. Not your fault. Probably.
                    """
                )
            }

            if model.showAccessibilityHint {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable Accessibility for this app so it can nudge the cursor.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Accessibility Settings…") {
                        AccessibilityPrompt.openAccessibilitySettings()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(10)
                .background(.quaternary.opacity(0.35))
                .cornerRadius(8)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .animation(.easeInOut(duration: 0.2), value: model.jiggleEnabled)
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.headline)

                    settingsSectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionTitle("Jiggle")

                        VStack(alignment: .leading, spacing: 0) {
                            Toggle("Jiggle only when idle", isOn: $model.jiggleWhenIdleOnly)
                                .padding(.vertical, 4)

                            settingsRowDivider

                            Stepper(value: Binding(
                                get: { model.jiggleIdleThresholdSeconds },
                                set: { model.applyIdleThresholdFromStepper($0) }
                            ), in: 5...600, step: 5) {
                                Text("Idle at least \(model.jiggleIdleThresholdSeconds) seconds")
                            }
                            .disabled(!model.jiggleWhenIdleOnly)
                            .opacity(model.jiggleWhenIdleOnly ? 1 : 0.45)
                            .padding(.vertical, 4)

                            settingsRowDivider

                            Stepper(value: Binding(
                                get: { model.nudgePixels },
                                set: { model.applyNudgePixelsFromStepper($0) }
                            ), in: 1...25, step: 1) {
                                Text("Nudge \(model.nudgePixels) px")
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.quaternary.opacity(0.22))
                        )
                    }

                    settingsSectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionTitle("Menu bar icon")

                        VStack(alignment: .leading, spacing: 0) {
                            iconChoiceRow(title: "Color", appearance: .original)
                            settingsRowDivider
                            iconChoiceRow(title: "White", appearance: .menuBarMonochrome)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(minHeight: 520, maxHeight: 1040)

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    showSettings = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 10)
            .padding(.bottom, 2)
        }
    }

    private func toggleLabelWithTooltip(title: String, tip: String) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(title)
            HelpTooltipMark(tooltip: tip, accessibilityTitle: title)
                .frame(width: 18, height: 18)
        }
    }

    private var settingsSectionDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }

    private var settingsRowDivider: some View {
        Divider()
            .padding(.vertical, 6)
    }

    private func settingsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func iconChoiceRow(title: String, appearance: MenuBarIconAppearance) -> some View {
        let selected = model.menuBarIconAppearance == appearance
        return Button {
            model.menuBarIconAppearance = appearance
        } label: {
            HStack(alignment: .center, spacing: 12) {
                menuIconPreview(appearance: appearance, side: 36)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 4)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary.opacity(selected ? 0.45 : 0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.quaternary.opacity(0.5), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func menuIconPreview(appearance: MenuBarIconAppearance, side: CGFloat) -> some View {
        Image(nsImage: MenuBarIcon.nsImage(forHeight: side, appearance: appearance))
            .interpolation(.none)
            .frame(width: side, height: side)
    }

    private var jiggleBinding: Binding<Bool> {
        Binding(
            get: { model.jiggleEnabled },
            set: { newValue in
                if newValue {
                    if model.requestJiggle(true) {
                        model.showAccessibilityHint = false
                    }
                } else {
                    model.showAccessibilityHint = false
                    model.jiggleEnabled = false
                }
            }
        )
    }
}

#Preview {
    MenuContentView(model: AppModel())
}

// MARK: - Help mark (custom quick tooltip, rounded)

private struct HelpTooltipMark: NSViewRepresentable {
    var tooltip: String
    var accessibilityTitle: String

    func makeNSView(context: Context) -> QuickTooltipButton {
        let b = QuickTooltipButton()
        b.setAccessibilityLabel("Help for \(accessibilityTitle)")
        return b
    }

    func updateNSView(_ b: QuickTooltipButton, context: Context) {
        b.tipText = tooltip.trimmingCharacters(in: .whitespacesAndNewlines)
        b.setAccessibilityLabel("Help for \(accessibilityTitle)")
    }
}

/// Rounded bubble; system `toolTip` can’t be fast or shaped, so we use a short-delay hover panel.
private struct TooltipBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(width: 268, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thickMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 3)
    }
}

private final class QuickTooltipButton: NSButton {
    /// Seconds before showing; kept very short so it feels snappy.
    private static let hoverDelay: TimeInterval = 0.1

    var tipText: String = "" {
        didSet {
            if tipText != oldValue {
                hideTip()
            }
        }
    }

    private var hoverWork: DispatchWorkItem?
    private var tipPanel: NSPanel?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isBordered = false
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyDown
        focusRingType = .none
        setButtonType(.momentaryChange)
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        if let base = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help") {
            image = base.withSymbolConfiguration(config)
        }
        contentTintColor = .secondaryLabelColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        cancelScheduledTip()
        guard !tipText.isEmpty else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.showTip()
        }
        hoverWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hoverDelay, execute: work)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        cancelScheduledTip()
        hideTip()
    }

    private func cancelScheduledTip() {
        hoverWork?.cancel()
        hoverWork = nil
    }

    private func hideTip() {
        tipPanel?.orderOut(nil)
        tipPanel = nil
    }

    private func showTip() {
        hideTip()
        guard let win = window, !tipText.isEmpty else { return }

        let host = NSHostingController(rootView: TooltipBubble(text: tipText))
        let targetWidth: CGFloat = 296
        host.view.setFrameSize(NSSize(width: targetWidth, height: 600))
        host.view.layoutSubtreeIfNeeded()
        var panelH = host.view.fittingSize.height
        if panelH < 40 { panelH = 72 }

        let rect = convert(bounds, to: nil)
        let screen = win.convertToScreen(rect)
        var originX = screen.maxX + 8
        let originY = screen.midY - panelH / 2

        if let scr = win.screen {
            let right = originX + targetWidth
            if right > scr.visibleFrame.maxX - 4 {
                originX = screen.minX - targetWidth - 8
            }
            if originX < scr.visibleFrame.minX + 4 {
                originX = scr.visibleFrame.minX + 4
            }
        }

        let panel = NSPanel(
            contentRect: NSRect(x: originX, y: originY, width: targetWidth, height: panelH),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.contentView = host.view
        panel.setContentSize(NSSize(width: targetWidth, height: panelH))
        panel.orderFrontRegardless()
        tipPanel = panel
    }

    deinit {
        cancelScheduledTip()
        hideTip()
    }
}
