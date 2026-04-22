import AppKit
import SwiftUI

private enum MenuBarIconSettingsPreview {
    static let side: CGFloat = 58
}

struct MenuContentView: View {
    @ObservedObject var model: AppModel
    @State private var showSettings = false
    /// Frames of UI “boxes” in `jjMenuRain` space; used to block rain and draw edge trickles (Hail Storm).
    @State private var rainOccluderRects: [CGRect] = []

    var body: some View {
        let palette = ThemePalette.palette(for: model.appTheme, model: model)
        Group {
            if palette.isClassicMacOS {
                macClassicChrome
            } else {
                retroChrome(palette: palette)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var macClassicChrome: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if showSettings {
                    macClassicSettingsPanel
                } else {
                    macClassicMainPanel
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

    @ViewBuilder
    private func retroChrome(palette: ThemePalette) -> some View {
        Group {
            if showSettings {
                settingsPanel(palette: palette)
            } else {
                mainPanel(palette: palette)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .padding(.trailing, showSettings ? 0 : 12)
        .background {
            ZStack {
                Rectangle()
                    .fill(palette.backgroundDeep)
                if palette.showsMenuPixelRain {
                    PixelMenuRainOverlay(occluders: rainOccluderRects)
                        .allowsHitTesting(false)
                }
            }
        }
        .coordinateSpace(name: "jjMenuRain")
        .onPreferenceChange(RainOccluderKey.self) { rainOccluderRects = $0 }
        .frame(minWidth: 320)
        .environment(\.colorScheme, palette.preferredColorScheme)
        .environment(\.jjTheme, palette)
        .tint(palette.chromeControlTint)
    }

    private var macClassicMainPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("JitterJuice")
                .font(.headline)

            Toggle(isOn: jiggleBinding) {
                macClassicToggleLabel(
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
                macClassicToggleLabel(
                    title: "Wakey Wakey",
                    tip: """
                    Keeps the display from sleeping while enabled. Optional auto-stop timer, plus a daily window (e.g. on at 6:00, off at 5:00). macOS can still sleep if it disagrees—rude, but possible.
                    """
                )
            }

            if model.stayAwakeEnabled {
                stayAwakeMacClassicCard
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
        .animation(.easeInOut(duration: 0.2), value: model.stayAwakeEnabled)
    }

    private var macClassicSettingsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.headline)

                    macClassicSectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        macClassicSettingsSectionTitle("Appearance")

                        VStack(alignment: .leading, spacing: 0) {
                            macClassicThemePickRow(theme: .eightBit)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .dracula)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .light)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .dark)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .macOS)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .donny)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .treehugger)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .pride)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .hailStorm)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .bladeRunner)
                            macClassicRowDivider
                            macClassicThemePickRow(theme: .custom)
                            if model.appTheme == .custom {
                                macClassicRowDivider
                                macClassicCustomThemeEditors
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.quaternary.opacity(0.22))
                        )
                    }

                    macClassicSectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        macClassicSettingsSectionTitle("Jiggle")

                        VStack(alignment: .leading, spacing: 0) {
                            Toggle("Jiggle only when idle", isOn: $model.jiggleWhenIdleOnly)
                                .padding(.vertical, 4)

                            macClassicRowDivider

                            Stepper(value: Binding(
                                get: { model.jiggleIdleThresholdSeconds },
                                set: { model.applyIdleThresholdFromStepper($0) }
                            ), in: 5...600, step: 5) {
                                Text("Idle at least \(model.jiggleIdleThresholdSeconds) seconds")
                            }
                            .disabled(!model.jiggleWhenIdleOnly)
                            .opacity(model.jiggleWhenIdleOnly ? 1 : 0.45)
                            .padding(.vertical, 4)

                            macClassicRowDivider

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

                    macClassicSectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        macClassicSettingsSectionTitle("Menu bar icon")

                        VStack(alignment: .leading, spacing: 0) {
                            macClassicIconPickRow(title: "Color", appearance: .original)
                            macClassicRowDivider
                            macClassicIconPickRow(title: "White", appearance: .menuBarMonochrome)
                            macClassicRowDivider
                            macClassicIconPickRow(title: "Match theme", appearance: .matchTheme)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(minHeight: 520, maxHeight: 1040)

            Divider()

            HStack(alignment: .center) {
                AttributionsFooterLink(model: model)
                Spacer(minLength: 8)
                Button("Done") {
                    showSettings = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 10)
            .padding(.bottom, 2)
        }
    }

    private func macClassicToggleLabel(title: String, tip: String) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(title)
            ClassicHelpTooltipMark(tooltip: tip, accessibilityTitle: title)
                .frame(width: 18, height: 18)
        }
    }

    private func macClassicThemePickRow(theme: AppTheme) -> some View {
        let selected = model.appTheme == theme
        return Button {
            model.appTheme = theme
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(theme.displayName)
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

    private var macClassicCustomThemeEditors: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Input format", selection: $model.customThemeInputUsesRGB) {
                Text("Hex").tag(false)
                Text("RGB").tag(true)
            }
            .pickerStyle(.segmented)

            macClassicCustomColorBlock(title: "Main (background)", isMain: true)
            macClassicCustomColorBlock(title: "Accent", isMain: false)
        }
        .padding(.vertical, 4)
    }

    private func macClassicCustomColorBlock(title: String, isMain: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if model.customThemeInputUsesRGB {
                HStack(spacing: 10) {
                    macClassicRGBField(channel: 0, label: "R", isMain: isMain)
                    macClassicRGBField(channel: 1, label: "G", isMain: isMain)
                    macClassicRGBField(channel: 2, label: "B", isMain: isMain)
                }
            } else {
                TextField("RRGGBB", text: hexBinding(isMain: isMain))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func macClassicRGBField(channel: Int, label: String, isMain: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", text: rgbByteBinding(channel: channel, isMain: isMain))
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
        }
    }

    private func hexBinding(isMain: Bool) -> Binding<String> {
        Binding(
            get: { isMain ? model.customThemeMainHex : model.customThemeAccentHex },
            set: {
                if isMain { model.applyCustomMainHexInput($0) }
                else { model.applyCustomAccentHexInput($0) }
            }
        )
    }

    private func rgbByteBinding(channel: Int, isMain: Bool) -> Binding<String> {
        Binding(
            get: {
                let hex = isMain ? model.customThemeMainHex : model.customThemeAccentHex
                let rgb = ThemeColorUtils.rgbFromHex(hex)
                let v = channel == 0 ? rgb.r : channel == 1 ? rgb.g : rgb.b
                return String(v)
            },
            set: { newStr in
                let digits = newStr.filter(\.isNumber)
                guard let n = Int(digits), (0...255).contains(n) else { return }
                var rgb = ThemeColorUtils.rgbFromHex(isMain ? model.customThemeMainHex : model.customThemeAccentHex)
                switch channel {
                case 0: rgb = (n, rgb.g, rgb.b)
                case 1: rgb = (rgb.r, n, rgb.b)
                default: rgb = (rgb.r, rgb.g, n)
                }
                let h = ThemeColorUtils.hexFromRGB(rgb.r, rgb.g, rgb.b)
                if isMain { model.customThemeMainHex = h }
                else { model.customThemeAccentHex = h }
            }
        )
    }

    private func macClassicIconPickRow(title: String, appearance: MenuBarIconAppearance) -> some View {
        let selected = model.menuBarIconAppearance == appearance
        let iconPalette = ThemePalette.palette(for: model.appTheme, model: model)
        return Button {
            model.menuBarIconAppearance = appearance
        } label: {
            HStack(alignment: .center, spacing: 12) {
                menuIconPreview(appearance: appearance, side: MenuBarIconSettingsPreview.side, palette: iconPalette)

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

    private var macClassicSectionDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }

    private var macClassicRowDivider: some View {
        Divider()
            .padding(.vertical, 6)
    }

    private func macClassicSettingsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func mainPanel(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(palette.usePixelFont ? "JITTERJUICE" : "JitterJuice")
                .font(palette.titleFont(size: palette.usePixelFont ? 11 : 17))
                .foregroundStyle(palette.textPrimary)
                .tracking(palette.usePixelFont ? 1 : 0)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)
                .jjRainOccluder(palette.showsMenuPixelRain)

            Toggle(isOn: jiggleBinding) {
                toggleLabelWithTooltip(
                    palette: palette,
                    title: "Jiggle Mouse",
                    tip: """
                    Moves the cursor during a time interval you choose—thrilling, I know. Turn it on to set the interval right below. Open Settings for idle-only mode and nudge distance. Requires Accessibility, because apparently moving pixels is a privileged operation.
                    """
                )
            }
            .toggleStyle(ThemedToggleStyle(palette: palette))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .jjRainOccluder(palette.showsMenuPixelRain)

            if model.jiggleEnabled {
                Stepper(value: Binding(
                    get: { model.jiggleIntervalSeconds },
                    set: { model.applyIntervalFromStepper($0) }
                ), in: 15...300, step: 5) {
                    Text("Every \(model.jiggleIntervalSeconds) sec")
                        .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                        .foregroundStyle(palette.accentSecondary)
                }
                .padding(.leading, palette.useLightningToggle ? 32 : 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .jjRainOccluder(palette.showsMenuPixelRain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Toggle(isOn: $model.stayAwakeEnabled) {
                toggleLabelWithTooltip(
                    palette: palette,
                    title: "Wakey Wakey",
                    tip: """
                    Keeps the display from sleeping while enabled. Use Stop after for a countdown, or Daily window so it only runs between times you set (e.g. 6:00–17:00). macOS may still sleep on rare occasions.
                    """
                )
            }
            .toggleStyle(ThemedToggleStyle(palette: palette))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .jjRainOccluder(palette.showsMenuPixelRain)

            if model.stayAwakeEnabled {
                stayAwakeRetroCard(palette: palette)
                    .padding(.leading, palette.useLightningToggle ? 32 : 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .jjRainOccluder(palette.showsMenuPixelRain)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if model.showAccessibilityHint {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable Accessibility for this app so it can nudge the cursor.")
                        .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                        .foregroundStyle(palette.accentSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Accessibility Settings…") {
                        AccessibilityPrompt.openAccessibilitySettings()
                    }
                    .buttonStyle(ThemedOutlineButtonStyle(palette: palette))
                    .keyboardShortcut(.defaultAction)
                }
                .padding(10)
                .background(palette.backgroundPanel.opacity(palette.usePixelChrome ? 0.85 : 0.95))
                .overlay(
                    Group {
                        if palette.usePixelChrome {
                            Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(palette.chromeBorderStyle(opacity: 0.5), lineWidth: 1)
                        }
                    }
                )
                .jjRainOccluder(palette.showsMenuPixelRain)
            }

            themedDivider(palette: palette)

            HStack(alignment: .center) {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(ThemedPrimaryButtonStyle(palette: palette))
                .keyboardShortcut("q", modifiers: .command)

                Spacer(minLength: 0)

                Button {
                    showSettings = true
                } label: {
                    ThemedGearIcon()
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .jjRainOccluder(palette.showsMenuPixelRain)
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: model.jiggleEnabled)
        .animation(.easeInOut(duration: 0.15), value: model.stayAwakeEnabled)
    }

    private func stayAwakeRetroCard(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let line = model.stayAwakeStatusLine(now: context.date) {
                    Text(palette.usePixelFont ? line.uppercased() : line)
                        .font(palette.bodyFont(size: palette.usePixelFont ? 7 : 11))
                        .foregroundStyle(palette.accentSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(palette.usePixelFont ? "STOP AFTER" : "Stop after")
                    .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                    .foregroundStyle(palette.textMuted)
                Picker("", selection: $model.stayAwakeAutoStopMinutes) {
                    Text(palette.usePixelFont ? "NEVER" : "Never").tag(0)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("1 hr").tag(60)
                    Text("2 hr").tag(120)
                    Text("4 hr").tag(240)
                    Text("8 hr").tag(480)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $model.stayAwakeScheduleEnabled) {
                    Text(palette.usePixelFont ? "DAILY WINDOW" : "Daily window")
                        .font(palette.bodyFont(size: palette.usePixelFont ? 9 : 13))
                        .foregroundStyle(palette.textPrimary)
                }
                .toggleStyle(ThemedToggleStyle(palette: palette))

                if model.stayAwakeScheduleEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(palette.usePixelFont ? "FROM" : "From")
                                .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                                .foregroundStyle(palette.textMuted)
                            Spacer(minLength: 8)
                            DatePicker(
                                "",
                                selection: stayAwakeDayMinuteBinding($model.stayAwakeDailyStartMinute),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        HStack {
                            Text(palette.usePixelFont ? "UNTIL" : "Until")
                                .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                                .foregroundStyle(palette.textMuted)
                            Spacer(minLength: 8)
                            DatePicker(
                                "",
                                selection: stayAwakeDayMinuteBinding($model.stayAwakeDailyEndMinute),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(palette.backgroundPanel.opacity(palette.usePixelChrome ? 0.72 : 0.88))
        .overlay(
            Group {
                if palette.usePixelChrome {
                    Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 0.55), lineWidth: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(palette.chromeBorderStyle(opacity: 0.35), lineWidth: 1)
                }
            }
        )
    }

    private var stayAwakeMacClassicCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let line = model.stayAwakeStatusLine(now: context.date) {
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Stop after")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("", selection: $model.stayAwakeAutoStopMinutes) {
                    Text("Never").tag(0)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                    Text("4 hours").tag(240)
                    Text("8 hours").tag(480)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Toggle("Limit to daily window", isOn: $model.stayAwakeScheduleEnabled)

            if model.stayAwakeScheduleEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Awake from",
                        selection: stayAwakeDayMinuteBinding($model.stayAwakeDailyStartMinute),
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "Awake until",
                        selection: stayAwakeDayMinuteBinding($model.stayAwakeDailyEndMinute),
                        displayedComponents: .hourAndMinute
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.45), lineWidth: 1)
        )
    }

    private func stayAwakeDayMinuteBinding(_ value: Binding<Int>) -> Binding<Date> {
        let cal = Calendar.current
        return Binding(
            get: {
                let start = cal.startOfDay(for: Date())
                let m = min(1439, max(0, value.wrappedValue))
                return cal.date(byAdding: .minute, value: m, to: start) ?? start
            },
            set: { date in
                let h = cal.component(.hour, from: date)
                let min = cal.component(.minute, from: date)
                value.wrappedValue = h * 60 + min
            }
        )
    }

    private func settingsPanel(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(palette.usePixelFont ? "SETTINGS" : "Settings")
                        .font(palette.titleFont(size: palette.usePixelFont ? 11 : 18))
                        .foregroundStyle(palette.textPrimary)
                        .tracking(palette.usePixelFont ? 1 : 0)
                        .padding(.vertical, 4)
                        .jjRainOccluder(palette.showsMenuPixelRain)

                    settingsSectionDivider(palette: palette)

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionTitle("Appearance", palette: palette)

                        VStack(alignment: .leading, spacing: 0) {
                            themeChoiceRow(theme: .eightBit, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .dracula, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .light, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .dark, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .macOS, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .donny, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .treehugger, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .pride, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .hailStorm, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .bladeRunner, palette: palette)
                            settingsRowDivider(palette: palette)
                            themeChoiceRow(theme: .custom, palette: palette)
                            if model.appTheme == .custom {
                                settingsRowDivider(palette: palette)
                                retroCustomThemeEditors(palette: palette)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.backgroundPanel.opacity(palette.usePixelChrome ? 0.75 : 0.6))
                        .overlay(
                            Group {
                                if palette.usePixelChrome {
                                    Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 0.55), lineWidth: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(palette.chromeBorderStyle(opacity: 0.35), lineWidth: 1)
                                }
                            }
                        )
                    }

                    settingsSectionDivider(palette: palette)

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionTitle("Jiggle", palette: palette)

                        VStack(alignment: .leading, spacing: 0) {
                            Toggle(isOn: $model.jiggleWhenIdleOnly) {
                                Text(palette.usePixelFont ? "JIGGLE ONLY WHEN IDLE" : "Jiggle only when idle")
                                    .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                                    .foregroundStyle(palette.textPrimary)
                            }
                            .toggleStyle(ThemedToggleStyle(palette: palette))
                            .padding(.vertical, 4)

                            settingsRowDivider(palette: palette)

                            Stepper(value: Binding(
                                get: { model.jiggleIdleThresholdSeconds },
                                set: { model.applyIdleThresholdFromStepper($0) }
                            ), in: 5...600, step: 5) {
                                Text("Idle \(model.jiggleIdleThresholdSeconds)s+")
                                    .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                                    .foregroundStyle(palette.accentSecondary)
                            }
                            .disabled(!model.jiggleWhenIdleOnly)
                            .opacity(model.jiggleWhenIdleOnly ? 1 : 0.45)
                            .padding(.vertical, 4)

                            settingsRowDivider(palette: palette)

                            Stepper(value: Binding(
                                get: { model.nudgePixels },
                                set: { model.applyNudgePixelsFromStepper($0) }
                            ), in: 1...25, step: 1) {
                                Text("Nudge \(model.nudgePixels) px")
                                    .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                                    .foregroundStyle(palette.accentSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.backgroundPanel.opacity(palette.usePixelChrome ? 0.75 : 0.6))
                        .overlay(
                            Group {
                                if palette.usePixelChrome {
                                    Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 0.55), lineWidth: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(palette.chromeBorderStyle(opacity: 0.35), lineWidth: 1)
                                }
                            }
                        )
                        .jjRainOccluder(palette.showsMenuPixelRain)
                    }

                    settingsSectionDivider(palette: palette)

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionTitle("Menu bar icon", palette: palette)

                        VStack(alignment: .leading, spacing: 0) {
                            iconChoiceRow(title: "Color", appearance: .original, palette: palette)
                            settingsRowDivider(palette: palette)
                            iconChoiceRow(title: "White", appearance: .menuBarMonochrome, palette: palette)
                            settingsRowDivider(palette: palette)
                            iconChoiceRow(title: "Match theme", appearance: .matchTheme, palette: palette)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(minHeight: 520, maxHeight: 1040)

            themedDivider(palette: palette)

            HStack(alignment: .center) {
                AttributionsFooterLink(model: model)
                Spacer(minLength: 8)
                Button("Done") {
                    showSettings = false
                }
                .buttonStyle(ThemedPrimaryButtonStyle(palette: palette))
                .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 10)
            .padding(.bottom, 2)
            .jjRainOccluder(palette.showsMenuPixelRain)
        }
    }

    private func toggleLabelWithTooltip(palette: ThemePalette, title: String, tip: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(palette.usePixelFont ? title.uppercased() : title)
                .font(palette.bodyFont(size: palette.usePixelFont ? 9 : 13))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            HelpTooltipMark(model: model, tooltip: tip, accessibilityTitle: title)
                .frame(width: 20, height: 20)
        }
    }

    private func themedDivider(palette: ThemePalette) -> some View {
        Rectangle()
            .fill(palette.chromeDividerFill(opacity: 0.4))
            .frame(height: palette.usePixelChrome ? 2 : 1)
    }

    private func settingsSectionDivider(palette: ThemePalette) -> some View {
        themedDivider(palette: palette)
            .padding(.vertical, 10)
    }

    private func settingsRowDivider(palette: ThemePalette) -> some View {
        themedDivider(palette: palette)
            .padding(.vertical, 6)
    }

    private func settingsSectionTitle(_ title: String, palette: ThemePalette) -> some View {
        Text(palette.usePixelFont ? title.uppercased() : title)
            .font(palette.bodyFont(size: palette.usePixelFont ? 9 : 12))
            .fontWeight(palette.usePixelFont ? .regular : .semibold)
            .foregroundStyle(palette.textMuted)
    }

    private func themeChoiceRow(theme: AppTheme, palette: ThemePalette) -> some View {
        ThemeChoiceBurstRow(model: model, theme: theme, palette: palette)
    }

    private func retroCustomThemeEditors(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(palette.usePixelFont ? "COLOR INPUT" : "Color input")
                    .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 12))
                    .foregroundStyle(palette.textMuted)
                Spacer(minLength: 8)
                Picker("", selection: $model.customThemeInputUsesRGB) {
                    Text(palette.usePixelFont ? "HEX" : "Hex").tag(false)
                    Text("RGB").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 200)
            }
            retroCustomColorBlock(
                palette: palette,
                titlePixel: "MAIN (BG)",
                titleSystem: "Main (background)",
                isMain: true
            )
            retroCustomColorBlock(
                palette: palette,
                titlePixel: "ACCENT",
                titleSystem: "Accent",
                isMain: false
            )
        }
        .padding(.vertical, 4)
    }

    private func retroCustomColorBlock(palette: ThemePalette, titlePixel: String, titleSystem: String, isMain: Bool) -> some View {
        let title = palette.usePixelFont ? titlePixel : titleSystem
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(palette.bodyFont(size: palette.usePixelFont ? 8 : 11))
                .foregroundStyle(palette.textMuted)
            if model.customThemeInputUsesRGB {
                HStack(spacing: 8) {
                    retroRGBField(palette: palette, channel: 0, label: "R", isMain: isMain)
                    retroRGBField(palette: palette, channel: 1, label: "G", isMain: isMain)
                    retroRGBField(palette: palette, channel: 2, label: "B", isMain: isMain)
                }
            } else {
                TextField("RRGGBB", text: hexBinding(isMain: isMain))
                    .textFieldStyle(.plain)
                    .font(palette.usePixelFont ? PixelTheme.font(size: 9) : .system(.body, design: .monospaced))
                    .foregroundStyle(palette.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(palette.toggleOffFill.opacity(0.55))
                    .overlay(Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 0.5), lineWidth: palette.usePixelChrome ? 2 : 1))
            }
        }
    }

    private func retroRGBField(palette: ThemePalette, channel: Int, label: String, isMain: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(palette.bodyFont(size: palette.usePixelFont ? 7 : 10))
                .foregroundStyle(palette.textMuted)
            TextField("0", text: rgbByteBinding(channel: channel, isMain: isMain))
                .textFieldStyle(.plain)
                .font(palette.usePixelFont ? PixelTheme.font(size: 9) : .system(.body, design: .monospaced))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(width: 40)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(palette.toggleOffFill.opacity(0.55))
                .overlay(Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 0.5), lineWidth: palette.usePixelChrome ? 2 : 1))
        }
    }

    private func iconChoiceRow(title: String, appearance: MenuBarIconAppearance, palette: ThemePalette) -> some View {
        IconChoiceBurstRow(model: model, title: title, appearance: appearance, palette: palette)
    }

    private func menuIconPreview(appearance: MenuBarIconAppearance, side: CGFloat, palette: ThemePalette) -> some View {
        Image(nsImage: MenuBarIcon.nsImage(forHeight: side, appearance: appearance, palette: palette))
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

// MARK: - Retro settings rows with tap bursts (sparkles / macOS apples)

/// Burst centered on the square radio control (same origin as the lightning-toggle stars).
private struct RetroRadioBurstAnchor: View {
    var filled: Bool
    var burstKey: Int
    var kind: RetroSettingsRowBurstKind

    var body: some View {
        ThemedRadioDot(filled: filled)
            .overlay {
                RetroSettingsRowBurstOverlay(burstKey: burstKey, kind: kind)
                    .frame(width: 118, height: 78)
            }
    }
}

private struct ThemeChoiceBurstRow: View {
    @ObservedObject var model: AppModel
    let theme: AppTheme
    let palette: ThemePalette
    @State private var burstKey = 0

    var body: some View {
        let selected = model.appTheme == theme
        let label = palette.usePixelFont ? theme.displayName.uppercased() : theme.displayName
        let burstKind: RetroSettingsRowBurstKind = theme == .macOS ? .macApples : .sparkles

        Button {
            model.appTheme = theme
            burstKey &+= 1
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(palette.bodyFont(size: palette.usePixelFont ? 9 : 13))
                    .foregroundStyle(palette.textPrimary)

                Spacer(minLength: 4)

                RetroRadioBurstAnchor(filled: selected, burstKey: burstKey, kind: burstKind)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Group {
                    if palette.usePixelChrome {
                        Rectangle()
                            .fill(selected ? palette.backgroundPanel : palette.toggleOffFill.opacity(0.65))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selected ? palette.backgroundPanel : palette.toggleOffFill.opacity(0.5))
                    }
                }
            )
            .overlay(
                Group {
                    if palette.usePixelChrome {
                        Rectangle()
                            .strokeBorder(palette.chromeBorderStyle(opacity: selected ? 1 : 0.45), lineWidth: selected ? 2 : 1)
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(palette.chromeBorderStyle(opacity: selected ? 0.9 : 0.35), lineWidth: selected ? 1.5 : 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .jjRainOccluder(palette.showsMenuPixelRain)
    }
}

private struct IconChoiceBurstRow: View {
    @ObservedObject var model: AppModel
    let title: String
    let appearance: MenuBarIconAppearance
    let palette: ThemePalette
    @State private var burstKey = 0

    var body: some View {
        let selected = model.menuBarIconAppearance == appearance

        Button {
            model.menuBarIconAppearance = appearance
            burstKey &+= 1
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(nsImage: MenuBarIcon.nsImage(forHeight: MenuBarIconSettingsPreview.side, appearance: appearance, palette: palette))
                    .interpolation(.none)
                    .frame(width: MenuBarIconSettingsPreview.side, height: MenuBarIconSettingsPreview.side)

                Text(palette.usePixelFont ? title.uppercased() : title)
                    .font(palette.bodyFont(size: palette.usePixelFont ? 9 : 13))
                    .foregroundStyle(palette.textPrimary)

                Spacer(minLength: 4)

                RetroRadioBurstAnchor(filled: selected, burstKey: burstKey, kind: .sparkles)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Group {
                    if palette.usePixelChrome {
                        Rectangle()
                            .fill(selected ? palette.backgroundPanel : palette.toggleOffFill.opacity(0.65))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selected ? palette.backgroundPanel : palette.toggleOffFill.opacity(0.5))
                    }
                }
            )
            .overlay(
                Group {
                    if palette.usePixelChrome {
                        Rectangle()
                            .strokeBorder(palette.chromeBorderStyle(opacity: selected ? 1 : 0.45), lineWidth: selected ? 2 : 1)
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(palette.chromeBorderStyle(opacity: selected ? 0.9 : 0.35), lineWidth: selected ? 1.5 : 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .jjRainOccluder(palette.showsMenuPixelRain)
    }
}

// MARK: - Hail Storm rain occluders

private struct RainOccluderKey: PreferenceKey {
    static var defaultValue: [CGRect] = []

    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

private extension View {
    @ViewBuilder
    func jjRainOccluder(_ enabled: Bool) -> some View {
        if enabled {
            background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: RainOccluderKey.self,
                        value: [geo.frame(in: .named("jjMenuRain"))]
                    )
                }
            }
        } else {
            self
        }
    }
}

#Preview {
    MenuContentView(model: AppModel())
}

// MARK: - Chrome

private struct ThemedGearIcon: View {
    @Environment(\.jjTheme) private var palette

    var body: some View {
        ZStack {
            Group {
                if palette.usePixelChrome {
                    Rectangle()
                        .fill(palette.toggleOffFill)
                        .frame(width: 28, height: 28)
                    Rectangle()
                        .strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                        .frame(width: 28, height: 28)
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.backgroundPanel)
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(palette.chromeBorderStyle(opacity: 0.5), lineWidth: 1)
                        .frame(width: 28, height: 28)
                }
            }
            Image(systemName: "gearshape.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.chromeForegroundAccent())
        }
        .frame(width: 28, height: 28)
        .accessibilityLabel("Settings")
    }
}

private struct ThemedRadioDot: View {
    @Environment(\.jjTheme) private var palette

    var filled: Bool

    var body: some View {
        ZStack {
            if palette.usePixelChrome {
                Rectangle()
                    .fill(filled ? palette.chromeAccentFill(isPressed: false) : AnyShapeStyle(palette.toggleOffFill))
                    .frame(width: 14, height: 14)
                Rectangle()
                    .strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                    .frame(width: 14, height: 14)
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(filled ? palette.chromeAccentFill(isPressed: false) : AnyShapeStyle(palette.toggleOffFill))
                    .frame(width: 14, height: 14)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(palette.chromeBorderStyle(opacity: 0.6), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityLabel(filled ? "Selected" : "Not selected")
    }
}

// MARK: - Settings attributions (hover typewriter tip)

private struct AttributionTooltipContent: View {
    /// Unicode black heart (♥); reads cleanly in pixel and system tooltips.
    static let fullText = "Made with \u{2665} Tanner A. Wuster"

    let palette: ThemePalette
    @State private var visibleCount = 0
    @State private var typeTask: Task<Void, Never>?

    var body: some View {
        let shown = String(Self.fullText.prefix(visibleCount))
        let caret = visibleCount < Self.fullText.count ? "▌" : ""

        Text(shown + caret)
            .font(palette.isClassicMacOS ? .callout : palette.bodyFont(size: palette.tooltipFontSize))
            .foregroundStyle(palette.isClassicMacOS ? Color.primary : palette.accentSecondary)
            .multilineTextAlignment(.leading)
            .frame(width: 268, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background {
                if palette.isClassicMacOS {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.thickMaterial)
                } else {
                    palette.backgroundPanel
                }
            }
            .overlay {
                Group {
                    if palette.isClassicMacOS {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                    } else if palette.usePixelChrome {
                        Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(palette.chromeBorderStyle(opacity: 0.4), lineWidth: 1)
                    }
                }
            }
            .shadow(
                color: palette.isClassicMacOS ? Color.black.opacity(0.35) : palette.tooltipShadow,
                radius: palette.isClassicMacOS ? 10 : (palette.usePixelChrome ? 0 : 4),
                x: 0,
                y: palette.isClassicMacOS ? 3 : 2
            )
            .onAppear { runTypewriter() }
            .onDisappear {
                typeTask?.cancel()
                typeTask = nil
            }
    }

    private func runTypewriter() {
        typeTask?.cancel()
        visibleCount = 0
        typeTask = Task {
            let n = Self.fullText.count
            for i in 0...n {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { visibleCount = i }
            }
        }
    }
}

private final class AttributionsHoverControl: NSButton {
    private static let hoverDelay: TimeInterval = 0.1

    private var palette: ThemePalette = .builtinEightBit
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
        setButtonType(.momentaryChange)
        focusRingType = .none
        applyPalette(.builtinEightBit)
    }

    func applyPalette(_ p: ThemePalette) {
        palette = p
        let title = p.isClassicMacOS ? "Attributions" : "ATTRIBUTIONS"
        let font: NSFont = p.isClassicMacOS
            ? .systemFont(ofSize: 11, weight: .regular)
            : (p.usePixelFont ? PixelTheme.nsFont(size: 7) : .systemFont(ofSize: 11, weight: .medium))
        let color: NSColor = p.isClassicMacOS ? .secondaryLabelColor : NSColor(p.textMuted)
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
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
        guard let win = window else { return }

        let bubble = AttributionTooltipContent(palette: palette)
        let host = NSHostingController(rootView: bubble)
        let targetWidth: CGFloat = 296
        host.view.setFrameSize(NSSize(width: targetWidth, height: 600))
        host.view.layoutSubtreeIfNeeded()
        var panelH = host.view.fittingSize.height
        if panelH < 40 { panelH = 72 }

        let rect = convert(bounds, to: nil)
        let screen = win.convertToScreen(rect)
        var originX = screen.midX - targetWidth / 2
        var originY = screen.maxY + 8

        if let scr = win.screen {
            if originX + targetWidth > scr.visibleFrame.maxX - 4 {
                originX = scr.visibleFrame.maxX - targetWidth - 4
            }
            if originX < scr.visibleFrame.minX + 4 {
                originX = scr.visibleFrame.minX + 4
            }
            let panelTop = originY + panelH
            if panelTop > scr.visibleFrame.maxY - 4 {
                originY = screen.minY - panelH - 8
            }
            if originY < scr.visibleFrame.minY + 4 {
                originY = scr.visibleFrame.minY + 4
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

private struct AttributionsLinkRepresentable: NSViewRepresentable {
    @ObservedObject var model: AppModel

    func makeNSView(context: Context) -> AttributionsHoverControl {
        let b = AttributionsHoverControl()
        b.setAccessibilityLabel("Attributions, shows credit on hover")
        return b
    }

    func updateNSView(_ b: AttributionsHoverControl, context: Context) {
        b.applyPalette(ThemePalette.palette(for: model.appTheme, model: model))
    }
}

private struct AttributionsFooterLink: View {
    @ObservedObject var model: AppModel

    var body: some View {
        AttributionsLinkRepresentable(model: model)
            .fixedSize()
    }
}

// MARK: - Help mark + tooltip

private struct HelpTooltipMark: NSViewRepresentable {
    @ObservedObject var model: AppModel
    @Environment(\.jjTheme) private var palette

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
        b.appModel = model
        b.applyPalette(palette)
    }
}

private struct TooltipBubble: View {
    let fullText: String
    let palette: ThemePalette
    let typewriter: Bool
    let onTypewriterComplete: () -> Void

    @State private var visibleCount = 0
    @State private var typeTask: Task<Void, Never>?

    var body: some View {
        let shown: String = {
            if !typewriter { return fullText }
            return String(fullText.prefix(visibleCount))
        }()

        Text(shown + (typewriter && visibleCount < fullText.count ? "▌" : ""))
            .font(palette.bodyFont(size: palette.tooltipFontSize))
            .foregroundStyle(palette.accentSecondary)
            .multilineTextAlignment(.leading)
            .frame(width: 268, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background(palette.backgroundPanel)
            .overlay(
                Group {
                    if palette.usePixelChrome {
                        Rectangle().strokeBorder(palette.chromeBorderStyle(opacity: 1), lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(palette.chromeBorderStyle(opacity: 0.4), lineWidth: 1)
                    }
                }
            )
            .shadow(color: palette.tooltipShadow, radius: palette.usePixelChrome ? 0 : 4, x: 0, y: 2)
            .onAppear {
                runTypewriterIfNeeded()
            }
            .onDisappear {
                typeTask?.cancel()
                typeTask = nil
            }
    }

    private func runTypewriterIfNeeded() {
        typeTask?.cancel()
        guard typewriter else {
            visibleCount = fullText.count
            return
        }
        visibleCount = 0
        typeTask = Task {
            let chars = Array(fullText)
            for i in 0...chars.count {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    visibleCount = i
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onTypewriterComplete()
            }
        }
    }
}

private final class QuickTooltipButton: NSButton {
    private static let hoverDelay: TimeInterval = 0.1

    weak var appModel: AppModel?

    var tipText: String = "" {
        didSet {
            if tipText != oldValue {
                hideTip()
            }
        }
    }

    private var palette: ThemePalette = .builtinEightBit

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

    func applyPalette(_ p: ThemePalette) {
        palette = p
        if p.usePixelHelpBadge {
            image = PixelTheme.helpBadgeNSImage(side: 20, palette: p)
            contentTintColor = nil
        } else {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help")?
                .withSymbolConfiguration(config)
            contentTintColor = NSColor(p.helpGlyph)
        }
    }

    private func commonInit() {
        isBordered = false
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyDown
        focusRingType = .none
        setButtonType(.momentaryChange)
        applyPalette(.builtinEightBit)
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

        let typewriter = !(appModel?.tooltipTypewriterPlayedThisSession ?? true)
        let bubble = TooltipBubble(
            fullText: tipText,
            palette: palette,
            typewriter: typewriter,
            onTypewriterComplete: { [weak self] in
                self?.appModel?.markTooltipTypewriterFinished()
            }
        )
        let host = NSHostingController(rootView: bubble)
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

// MARK: - Classic macOS help (pre–8-bit)

private struct ClassicHelpTooltipMark: NSViewRepresentable {
    var tooltip: String
    var accessibilityTitle: String

    func makeNSView(context: Context) -> ClassicQuickTooltipButton {
        let b = ClassicQuickTooltipButton()
        b.setAccessibilityLabel("Help for \(accessibilityTitle)")
        return b
    }

    func updateNSView(_ b: ClassicQuickTooltipButton, context: Context) {
        b.tipText = tooltip.trimmingCharacters(in: .whitespacesAndNewlines)
        b.setAccessibilityLabel("Help for \(accessibilityTitle)")
    }
}

private struct ClassicTooltipBubble: View {
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

private final class ClassicQuickTooltipButton: NSButton {
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

        let host = NSHostingController(rootView: ClassicTooltipBubble(text: tipText))
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
