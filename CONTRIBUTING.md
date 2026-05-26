# Contributing to JitterJuice

Thanks for helping improve Jerry. This guide covers day-to-day development; the [README](README.md) stays the user-facing overview.

## Prerequisites

- macOS **13.0** or later
- **Xcode** (recent stable; run `xcodebuild -runFirstLaunch` after Xcode updates if builds fail)
- **Accessibility** permission when testing **Jiggle Mouse**: System Settings → Privacy & Security → Accessibility → enable JitterJuice

## Build and run

From the repo root:

```bash
make ipod    # quit (if running), build Debug, launch
make build   # build only
make run     # open the last Debug build
```

Or open **`JitterJuice.xcodeproj`** in Xcode and run scheme **JitterJuice**.

Plain `xcodebuild` (same paths as the Makefile):

```bash
xcodebuild -project JitterJuice.xcodeproj -scheme JitterJuice -configuration Debug -derivedDataPath "$(pwd)/.derivedData" build
open .derivedData/Build/Products/Debug/JitterJuice.app
```

Bundle ID: `com.jitterjuice.JitterJuice` (used by the app and `Tools/ipod.sh`).

## Tests

Run unit tests from the command line:

```bash
make test
```

Or in Xcode: **Product → Test** (⌘U). Tests live in **`JitterJuiceTests/`** and cover stay-awake schedule windows and settings clamping.

## Releases (maintainers)

See the **Maintainers: ship a release** section in [README.md](README.md). Summary:

1. Archive or export **Release** `JitterJuice.app` from Xcode.
2. Run **`Tools/make-dmg.sh`** to produce a drag-to-Applications DMG.
3. Upload the DMG on [GitHub Releases](https://github.com/tannerwuster/JitterJuice/releases) and update [CHANGELOG.md](CHANGELOG.md) and the README version table.

## Menu bar artwork

Master PNGs live under **`Artwork/MenuBar/`**. When updating icons:

1. Edit the source PNG in `Artwork/MenuBar/` (see README **Assets** table for filenames).
2. Copy into the matching **`JitterJuice/Assets.xcassets/MenuBarIcons/<name>.imageset/`** (replace `Contents.json` references if you add scales).
3. Rebuild and check the menu bar in light/dark mode and with **Settings → Appearance** themes.

Optional maintainer tool: **`Tools/StripMenuBarPNGBackground.swift`** (standalone; not part of the app target).

## Roadmap and issues

Planned work is tracked in [ROADMAP.md](ROADMAP.md) and [GitHub issues](https://github.com/tannerwuster/JitterJuice/issues). Use labels **`roadmap`** and **`phase-*`** for roadmap items; link PRs to the issue they close.

## Pull requests

- Keep changes focused; match existing Swift and UI style in the touched files.
- Run **`make test`** before opening a PR when you change logic in `AppModel`, schedules, or settings.
- Do not commit secrets, `.derivedData`, or local `xcuserdata`.
