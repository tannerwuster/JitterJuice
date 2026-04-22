# JitterJuice · v1.0

![JitterJuice logo](jitterjuicelogo.png)

**Jerry** is the smug little can in the art—mascot, attitude, entire brand.

macOS menu bar app: **nudge the cursor on a timer** and optionally **keep the display awake**, without living in Terminal.

*What it’s “for”:* That status indicator that claims to know if you’re “there”? Not our department. Definitely not for convincing certain chat apps you’re glued to your desk while you make toast. Professionals, all of us.

---

## Download

| Version | macOS |
|--------:|--------|
| **1.0** | [**Latest release** (`.zip`)](https://github.com/tannerwuster/JitterJuice/releases/latest) |

Unzip, drag **JitterJuice.app** into **Applications**. If the release page is empty, publish a **`.zip`** on [Releases](https://github.com/tannerwuster/JitterJuice/releases) first.

**Gatekeeper:** Right-click the app → **Open** → **Open**, or allow it under **System Settings → Privacy & Security**. Worth it for Jerry.

<details>
<summary><strong>Maintainers: ship a release</strong></summary>

1. **Xcode:** Product → Archive → Distribute App → **Copy App** (or export **`JitterJuice.app`**).
2. Zip **`JitterJuice.app`** → upload **`JitterJuice.zip`** on GitHub **Releases** with tag **`v1.0.0`** (or bump to match the table above).
3. Update this README’s version in the title and table when you cut a new release.

</details>

---

## Build from source

Repo: [github.com/tannerwuster/JitterJuice](https://github.com/tannerwuster/JitterJuice)

```bash
git clone https://github.com/tannerwuster/JitterJuice.git
cd JitterJuice
# SSH: git@github.com:tannerwuster/JitterJuice.git
```

Open **`JitterJuice.xcodeproj`** in Xcode (scheme **JitterJuice**), or:

```bash
xcodebuild -project JitterJuice.xcodeproj -scheme JitterJuice -configuration Debug -derivedDataPath "$(pwd)/.derivedData" build
open .derivedData/Build/Products/Debug/JitterJuice.app
```

## Permissions

**Accessibility** (mouse nudges): **System Settings → Privacy & Security → Accessibility** → enable JitterJuice.

## Assets

| File | Role |
|------|------|
| `jitterjuiceicon.png` | Menu bar source → `JitterJuiceMenuBar` in the asset catalog |
| `jitterjuicelogo.png` | README / marketing |
