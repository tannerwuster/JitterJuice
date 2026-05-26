# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Releases are also published on [GitHub Releases](https://github.com/tannerwuster/JitterJuice/releases).

## [Unreleased]

### Added

- `JitterJuiceTests` unit test target (stay-awake schedule and settings clamping)
- [CONTRIBUTING.md](CONTRIBUTING.md) and this changelog
- `make test` for local test runs

### Changed

- `Tools/ipod.sh` bundle ID aligned with Xcode (`com.jitterjuice.JitterJuice`)

### Removed

- Debug `jjLog` instrumentation from `MouseJiggler`

## [1.1] — 2025-05-26

### Added

- **Jiggle Mouse** — cursor nudges on a configurable interval; idle-only mode; nudge distance; 360° and up/down patterns
- **Wakey Wakey** — prevent display sleep via IOKit power assertion; optional auto-stop timer; daily time window
- **Settings** — menu bar icon appearance (original, monochrome, match theme)
- **Juice themes** — retro and classic macOS appearances, including Custom Juice (hex/RGB colors)
- Menu bar utility (`LSUIElement`) with SwiftUI menu UI and bundled Press Start 2P font

[1.1]: https://github.com/tannerwuster/JitterJuice/releases/tag/v1.1.0
