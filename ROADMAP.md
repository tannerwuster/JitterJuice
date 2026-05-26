# JitterJuice roadmap

Planned work for [JitterJuice](https://github.com/tannerwuster/JitterJuice). Track progress on GitHub via **[issue #22](https://github.com/tannerwuster/JitterJuice/issues/22)** (master checklist) and [milestones](https://github.com/tannerwuster/JitterJuice/milestones).

## How to use this doc

- Each bullet links to a GitHub issue for discussion and PRs.
- Phases are ordered by suggested priority, not strict deadlines.
- Check off items on **#22** when they ship; keep this file in sync when adding or closing roadmap issues.

---

## Phase 1 — Quality & hygiene

Fix correctness and tech debt before larger features.

| Issue | Topic |
|------:|-------|
| [#1](https://github.com/tannerwuster/JitterJuice/issues/1) | Remove debug `jjLog` instrumentation from `MouseJiggler` |
| [#2](https://github.com/tannerwuster/JitterJuice/issues/2) | Align bundle identifier between Xcode project and `ipod.sh` |
| [#3](https://github.com/tannerwuster/JitterJuice/issues/3) | Unit tests for schedule logic and settings clamping |
| [#4](https://github.com/tannerwuster/JitterJuice/issues/4) | Add `CONTRIBUTING.md` and `CHANGELOG.md` |

[Milestone: Phase 1](https://github.com/tannerwuster/JitterJuice/milestone/1)

---

## Phase 2 — Distribution & trust

Make installs trustworthy and releases repeatable.

| Issue | Topic |
|------:|-------|
| [#5](https://github.com/tannerwuster/JitterJuice/issues/5) | Developer ID signing and notarization for releases |
| [#6](https://github.com/tannerwuster/JitterJuice/issues/6) | GitHub Actions CI: build, test, and release DMG |
| [#7](https://github.com/tannerwuster/JitterJuice/issues/7) | Add `LICENSE` file |

[Milestone: Phase 2](https://github.com/tannerwuster/JitterJuice/milestone/2)

---

## Phase 3 — Core features

High-impact behavior users expect from a menu bar utility.

| Issue | Topic |
|------:|-------|
| [#8](https://github.com/tannerwuster/JitterJuice/issues/8) | Launch at login option |
| [#9](https://github.com/tannerwuster/JitterJuice/issues/9) | Global hotkeys to toggle Jiggle and Wakey Wakey |
| [#10](https://github.com/tannerwuster/JitterJuice/issues/10) | Daily schedule for Jiggle Mouse (parity with Wakey Wakey) |
| [#11](https://github.com/tannerwuster/JitterJuice/issues/11) | Option to prevent system sleep (not only display) |

[Milestone: Phase 3](https://github.com/tannerwuster/JitterJuice/milestone/3)

---

## Phase 4 — Polish & platform

Maintainability, accessibility, and menu bar robustness.

| Issue | Topic |
|------:|-------|
| [#12](https://github.com/tannerwuster/JitterJuice/issues/12) | Refactor `MenuContentView` into focused modules |
| [#13](https://github.com/tannerwuster/JitterJuice/issues/13) | VoiceOver and accessibility labels for menu UI |
| [#14](https://github.com/tannerwuster/JitterJuice/issues/14) | Menu bar icon: multi-display and appearance refresh |

[Milestone: Phase 4](https://github.com/tannerwuster/JitterJuice/milestone/4)

---

## Phase 5 — Growth & distribution

Easier installs and updates.

| Issue | Topic |
|------:|-------|
| [#15](https://github.com/tannerwuster/JitterJuice/issues/15) | In-app updates (Sparkle) or documented update check |
| [#16](https://github.com/tannerwuster/JitterJuice/issues/16) | Homebrew cask for installation |
| [#17](https://github.com/tannerwuster/JitterJuice/issues/17) | Export and import settings (JSON) |

[Milestone: Phase 5](https://github.com/tannerwuster/JitterJuice/milestone/5)

---

## Phase 6 — Future ideas

Optional enhancements; prioritize after earlier phases.

| Issue | Topic |
|------:|-------|
| [#18](https://github.com/tannerwuster/JitterJuice/issues/18) | Per-app pause list (do not jiggle when app is frontmost) |
| [#19](https://github.com/tannerwuster/JitterJuice/issues/19) | Additional jiggle patterns |
| [#20](https://github.com/tannerwuster/JitterJuice/issues/20) | macOS Shortcuts / App Intents for toggles |
| [#21](https://github.com/tannerwuster/JitterJuice/issues/21) | Localization (String Catalog) |

[Milestone: Phase 6](https://github.com/tannerwuster/JitterJuice/milestone/6)

---

## Suggested order of execution

1. **#1, #2** — quick wins; unblocks clean releases  
2. **#6, #7, #5** — CI, license, notarization  
3. **#3, #4** — tests and contributor docs  
4. **#8–#11** — core feature batch  
5. **#12–#14** — polish  
6. **#15–#17** — distribution growth  
7. **#18–#21** — as appetite allows  

---

## Adding new roadmap items

1. Open a GitHub issue with label `roadmap` and the appropriate `phase-*` label.
2. Assign it to the matching milestone.
3. Add a row to the phase table above and to the checklist on [#22](https://github.com/tannerwuster/JitterJuice/issues/22).
