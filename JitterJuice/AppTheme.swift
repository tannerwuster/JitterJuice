import AppKit
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case eightBit
    case macOS
    case dracula
    case light
    case dark
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eightBit: return "Jitter Juice"
        case .macOS: return "Apple Juice"
        case .dracula: return "Dracula Juice"
        case .light: return "Moon Juice"
        case .dark: return "Deadly Juice"
        case .custom: return "Custom Juice"
        }
    }
}

struct ThemePalette {
    let theme: AppTheme
    let backgroundDeep: Color
    let backgroundPanel: Color
    let accent: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textMuted: Color
    let border: Color
    let toggleOnFill: Color
    let toggleOffFill: Color
    let helpBadgeFill: Color
    let helpBadgeStroke: Color
    let helpGlyph: Color
    let buttonLabelOnAccent: Color
    let tooltipShadow: Color
    let usePixelFont: Bool
    let useLightningToggle: Bool
    let useSparkles: Bool
    let usePixelHelpBadge: Bool
    let usePixelChrome: Bool
    let preferredColorScheme: ColorScheme

    func titleFont(size: CGFloat) -> Font {
        if usePixelFont {
            PixelTheme.font(size: size)
        } else {
            .system(size: size, weight: .semibold)
        }
    }

    func bodyFont(size: CGFloat) -> Font {
        if usePixelFont {
            PixelTheme.font(size: size)
        } else {
            .system(size: size)
        }
    }

    var tooltipFontSize: CGFloat { usePixelFont ? 8 : 12 }

    /// Pre–8-bit system UI: standard toggles, materials, no forced popover styling.
    var isClassicMacOS: Bool { theme == .macOS }

    /// Bundled menu bar art already matches this palette; skip runtime recolor for pixel-perfect parity with **Color (original)**.
    var matchesOriginalMenuBarAsset: Bool { theme == .eightBit }

    /// Default JitterJuice (8-bit) colors; used where no `AppModel` is available.
    static let builtinEightBit = ThemePalette(
        theme: .eightBit,
        backgroundDeep: Color(red: 0.14, green: 0.07, blue: 0.26),
        backgroundPanel: Color(red: 0.22, green: 0.11, blue: 0.40),
        accent: Color(red: 1.0, green: 0.92, blue: 0.22),
        accentSecondary: Color(red: 0.96, green: 0.78, blue: 0.18),
        textPrimary: Color(red: 1.0, green: 0.92, blue: 0.22),
        textMuted: Color(red: 0.82, green: 0.70, blue: 0.35),
        border: Color(red: 1.0, green: 0.92, blue: 0.22),
        toggleOnFill: Color(red: 1.0, green: 0.92, blue: 0.22),
        toggleOffFill: Color(red: 0.14, green: 0.07, blue: 0.26),
        helpBadgeFill: Color(red: 0.14, green: 0.07, blue: 0.26),
        helpBadgeStroke: Color(red: 1.0, green: 0.92, blue: 0.22),
        helpGlyph: Color(red: 1.0, green: 0.92, blue: 0.22),
        buttonLabelOnAccent: Color(red: 0.14, green: 0.07, blue: 0.26),
        tooltipShadow: Color.black.opacity(0.45),
        usePixelFont: true,
        useLightningToggle: true,
        useSparkles: true,
        usePixelHelpBadge: true,
        usePixelChrome: true,
        preferredColorScheme: .dark
    )

    static func contrastingLabel(on accent: Color) -> Color {
        ThemeColorUtils.relativeLuminance(accent) > 0.55
            ? Color(red: 0.06, green: 0.06, blue: 0.08)
            : Color(white: 0.96)
    }

    static func palette(for theme: AppTheme, model: AppModel) -> ThemePalette {
        if theme == .custom {
            return customPalette(mainHex: model.customThemeMainHex, accentHex: model.customThemeAccentHex)
        }
        return palette(for: theme)
    }

    static func palette(for theme: AppTheme) -> ThemePalette {
        switch theme {
        case .eightBit:
            return builtinEightBit

        case .macOS:
            return ThemePalette(
                theme: theme,
                backgroundDeep: Color(nsColor: .windowBackgroundColor),
                backgroundPanel: Color(nsColor: .controlBackgroundColor),
                accent: Color.accentColor,
                accentSecondary: Color.secondary,
                textPrimary: Color.primary,
                textMuted: Color.secondary,
                border: Color(nsColor: .separatorColor),
                toggleOnFill: Color.accentColor,
                toggleOffFill: Color(nsColor: .controlBackgroundColor),
                helpBadgeFill: Color(nsColor: .controlBackgroundColor),
                helpBadgeStroke: Color(nsColor: .separatorColor),
                helpGlyph: Color.secondary,
                buttonLabelOnAccent: Color.white,
                tooltipShadow: Color.black.opacity(0.2),
                usePixelFont: false,
                useLightningToggle: false,
                useSparkles: false,
                usePixelHelpBadge: false,
                usePixelChrome: false,
                preferredColorScheme: .dark
            )

        case .dracula:
            return ThemePalette(
                theme: theme,
                backgroundDeep: Color(red: 0.157, green: 0.165, blue: 0.212),
                backgroundPanel: Color(red: 0.267, green: 0.278, blue: 0.353),
                accent: Color(red: 0.741, green: 0.576, blue: 0.976),
                accentSecondary: Color(red: 0.945, green: 0.980, blue: 0.549),
                textPrimary: Color(red: 0.973, green: 0.973, blue: 0.949),
                textMuted: Color(red: 0.384, green: 0.447, blue: 0.643),
                border: Color(red: 0.741, green: 0.576, blue: 0.976),
                toggleOnFill: Color(red: 0.741, green: 0.576, blue: 0.976),
                toggleOffFill: Color(red: 0.157, green: 0.165, blue: 0.212),
                helpBadgeFill: Color(red: 0.157, green: 0.165, blue: 0.212),
                helpBadgeStroke: Color(red: 0.945, green: 0.980, blue: 0.549),
                helpGlyph: Color(red: 0.945, green: 0.980, blue: 0.549),
                buttonLabelOnAccent: Color(red: 0.157, green: 0.165, blue: 0.212),
                tooltipShadow: Color.black.opacity(0.5),
                usePixelFont: true,
                useLightningToggle: true,
                useSparkles: true,
                usePixelHelpBadge: true,
                usePixelChrome: true,
                preferredColorScheme: .dark
            )

        case .light:
            let accent = Color(white: 0.08)
            return ThemePalette(
                theme: theme,
                backgroundDeep: Color(red: 0.95, green: 0.95, blue: 0.97),
                backgroundPanel: Color.white,
                accent: accent,
                accentSecondary: Color(white: 0.42),
                textPrimary: Color(white: 0.1),
                textMuted: Color(white: 0.48),
                border: accent,
                toggleOnFill: accent,
                toggleOffFill: Color.white,
                helpBadgeFill: Color.white,
                helpBadgeStroke: accent,
                helpGlyph: accent,
                buttonLabelOnAccent: Color.white,
                tooltipShadow: Color.black.opacity(0.15),
                usePixelFont: true,
                useLightningToggle: true,
                useSparkles: true,
                usePixelHelpBadge: true,
                usePixelChrome: true,
                preferredColorScheme: .light
            )

        case .dark:
            let deep = Color(red: 0.06, green: 0.06, blue: 0.07)
            let panel = Color(red: 0.11, green: 0.11, blue: 0.12)
            let accent = Color(white: 0.96)
            return ThemePalette(
                theme: theme,
                backgroundDeep: deep,
                backgroundPanel: panel,
                accent: accent,
                accentSecondary: Color(white: 0.72),
                textPrimary: Color(white: 0.94),
                textMuted: Color(white: 0.52),
                border: accent,
                toggleOnFill: accent,
                toggleOffFill: deep,
                helpBadgeFill: deep,
                helpBadgeStroke: accent,
                helpGlyph: accent,
                buttonLabelOnAccent: Color(white: 0.06),
                tooltipShadow: Color.black.opacity(0.55),
                usePixelFont: true,
                useLightningToggle: true,
                useSparkles: true,
                usePixelHelpBadge: true,
                usePixelChrome: true,
                preferredColorScheme: .dark
            )

        case .custom:
            return customPalette(
                mainHex: AppModel.defaultCustomMainHex,
                accentHex: AppModel.defaultCustomAccentHex
            )
        }
    }

    private static func customPalette(mainHex: String, accentHex: String) -> ThemePalette {
        let fallbackMain = ThemeColorUtils.color(fromHex6: AppModel.defaultCustomMainHex)!
        let fallbackAccent = ThemeColorUtils.color(fromHex6: AppModel.defaultCustomAccentHex)!
        let main = ThemeColorUtils.color(fromHex6: mainHex) ?? fallbackMain
        let accent = ThemeColorUtils.color(fromHex6: accentHex) ?? fallbackAccent
        let lum = ThemeColorUtils.relativeLuminance(main)
        let isDark = lum < 0.4
        let panel = ThemeColorUtils.mix(main, Color.white, t: isDark ? 0.14 : 0.1)
        let textPrimary = isDark ? Color(white: 0.95) : Color(white: 0.08)
        let textMuted = isDark ? Color(white: 0.55) : Color(white: 0.45)
        let accentSecondary = ThemeColorUtils.mix(accent, main, t: 0.28)
        return ThemePalette(
            theme: .custom,
            backgroundDeep: main,
            backgroundPanel: panel,
            accent: accent,
            accentSecondary: accentSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
            border: accent,
            toggleOnFill: accent,
            toggleOffFill: main,
            helpBadgeFill: main,
            helpBadgeStroke: accent,
            helpGlyph: accent,
            buttonLabelOnAccent: contrastingLabel(on: accent),
            tooltipShadow: Color.black.opacity(isDark ? 0.45 : 0.16),
            usePixelFont: true,
            useLightningToggle: true,
            useSparkles: true,
            usePixelHelpBadge: true,
            usePixelChrome: true,
            preferredColorScheme: isDark ? .dark : .light
        )
    }
}

private struct JJThemeKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .builtinEightBit
}

extension EnvironmentValues {
    var jjTheme: ThemePalette {
        get { self[JJThemeKey.self] }
        set { self[JJThemeKey.self] = newValue }
    }
}

// MARK: - Button styles (theme-aware)

struct ThemedPrimaryButtonStyle: ButtonStyle {
    var palette: ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        if palette.usePixelChrome {
            return AnyView(
                configuration.label
                    .font(palette.bodyFont(size: 9))
                    .foregroundStyle(palette.buttonLabelOnAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Rectangle()
                            .fill(pressed ? palette.accentSecondary : palette.accent)
                    )
                    .overlay(
                        Rectangle()
                            .strokeBorder(palette.toggleOffFill.opacity(0.35), lineWidth: 2)
                    )
            )
        } else {
            return AnyView(
                configuration.label
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.accentColor.opacity(pressed ? 0.85 : 1))
                    )
            )
        }
    }
}

struct ThemedOutlineButtonStyle: ButtonStyle {
    var palette: ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        if palette.usePixelChrome {
            return AnyView(
                configuration.label
                    .font(palette.bodyFont(size: 9))
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Rectangle().fill(palette.toggleOffFill.opacity(0.55)))
                    .overlay(Rectangle().strokeBorder(palette.border, lineWidth: 2))
                    .opacity(pressed ? 0.78 : 1)
            )
        } else {
            return AnyView(
                configuration.label
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .opacity(pressed ? 0.8 : 1)
            )
        }
    }
}

// MARK: - Toggle (lightning vs system checkbox)

struct ThemedToggleStyle: ToggleStyle {
    var palette: ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if palette.useLightningToggle {
                PixelLightningToggleStyle().makeBody(configuration: configuration)
            } else {
                HStack(alignment: .center, spacing: 10) {
                    Toggle("", isOn: configuration.$isOn)
                        .toggleStyle(.checkbox)
                        .labelsHidden()
                    configuration.label
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

