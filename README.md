# JitterJuice

![JitterJuice logo](jitterjuicelogo.png)

The smug little can up there is **Jerry**. He’s the mascot, the attitude, and—let’s be honest—the whole brand.

macOS menu bar utility that **occasionally moves your cursor** because apparently that’s a thing people need. It also **pesters your display into staying awake** if you’d rather not babysit `caffeinate` in Terminal.

**What it’s “for”:** You know that little indicator that pretends to know if you’re “there”? This doesn’t talk about that. It definitely isn’t for making certain chat apps think you’re riveted to your desk instead of, say, making toast. That would be weird. We’re all professionals here.

## Download (Mac)

**[⬇ Latest release](https://github.com/tannerwuster/JitterJuice/releases/latest)** — open the latest release, download the attached **`.zip`**, unzip it, drag **JitterJuice.app** into **Applications**.

If that link 404s, you haven’t published a release with a downloadable **`.zip`** yet—Jerry’s waiting in the wings.

**First open:** Unsigned or lightly signed apps often get the “can’t be opened” lecture. **Right-click** the app → **Open** → confirm **Open**, or use **System Settings → Privacy & Security** and allow it there. Jerry’s worth the paperwork.

### Shipping a release on GitHub (for you, the human with the keys)

1. In Xcode, **Product → Archive** (Release), then **Distribute App** → **Copy App** (or export however you like) so you have **`JitterJuice.app`**.
2. Zip it: **Finder → Compress “JitterJuice”** (you get `JitterJuice.zip`).
3. On GitHub: repo → **Releases** → **Draft a new release** → pick a tag (e.g. `v1.0.0`) → upload **`JitterJuice.zip`** as a release asset → publish.

After that, the **Latest release** link above sends people straight to the download.

## Build & run

**Repo:** [github.com/tannerwuster/JitterJuice](https://github.com/tannerwuster/JitterJuice)

```bash
git clone https://github.com/tannerwuster/JitterJuice.git
cd JitterJuice
```

*(SSH: `git@github.com:tannerwuster/JitterJuice.git`)*

Open `JitterJuice.xcodeproj` in Xcode and run the **JitterJuice** scheme, or from the repo root:

```bash
xcodebuild -project JitterJuice.xcodeproj -scheme JitterJuice -configuration Debug -derivedDataPath "$(pwd)/.derivedData" build
open .derivedData/Build/Products/Debug/JitterJuice.app
```

## Permissions

- **Accessibility** is required for mouse nudges—Apple considers nudging pixels a sacred ritual. Enable JitterJuice under **System Settings → Privacy & Security → Accessibility**.

## Assets

- Menu bar icon source: `jitterjuiceicon.png` (resized into the asset catalog as `JitterJuiceMenuBar`).
- Marketing / README art: `jitterjuicelogo.png`.
