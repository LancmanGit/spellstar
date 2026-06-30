# SpellStar — Next Steps (continued on MacBook Pro)

## Where we are now

- **App:** `SpellStar.html` — a single self-contained HTML file (React 18 + Babel via CDN, Web Speech API). No build step. Open it in a browser and it just runs.
- **Live web version:** https://lancmangit.github.io/spellstar/SpellStar.html
  (Hosted on GitHub Pages from this repo's `main` branch. Works on any device with a browser.)
- **PWA:** `manifest.json` + `sw.js` are wired in. On a normal iPhone you can Safari → Share → **Add to Home Screen** to install it full-screen and offline.

## The actual goal driving the native build

The app needs to run **inside iOS Assistive Access** on a child's iPhone, with **no browser anywhere reachable**.

**Why the PWA isn't enough:** Assistive Access only lists *native apps* you explicitly enable in its setup. Home-screen web clips (PWAs) do **not** appear in the Assistive Access app picker — that's an Apple limitation, not a config gap. Putting Safari into Assistive Access would work but hands the child a browser, defeating the whole point.

**Conclusion:** the only way to get SpellStar as its own locked-down tile in Assistive Access is to wrap it in a tiny **native iOS app** (a WKWebView that loads the bundled HTML locally → fully offline, no browser engine to escape into).

## What you need on the MacBook Pro

1. **Xcode** — free from the Mac App Store, ~7 GB download (this is the only reason we moved off the other Mac).
2. **Your Apple ID** for signing.
3. **A USB cable** to install onto the iPhone the first time.

## The signing catch (decide this)

- **Free Apple ID:** app works fully but **expires after 7 days** and must be reconnected + rebuilt. No cost, weekly upkeep.
- **Apple Developer Program ($99/yr):** app installs once and **never expires**. The sustainable option for a child's everyday device.

(No decision made yet — pick when you build.)

## Plan once Xcode is installed

The wrapper is genuinely tiny — roughly:

1. In Xcode: **File → New → Project → iOS → App** (SwiftUI or Storyboard, either is fine). Name it "SpellStar".
2. Drag `SpellStar.html` into the project (check "Copy items if needed" so it's bundled in the app).
3. Replace the main view with a `WKWebView` that loads the bundled `SpellStar.html` from the app bundle (local file URL — no internet needed).
4. Set the app icon (a proper star icon — can be generated; right now there isn't one).
5. Plug in the iPhone, select it as the build target, sign with your Apple ID, **Build & Run**.
6. On the iPhone: trust the developer profile (Settings → General → VPN & Device Management).
7. Add SpellStar to **Assistive Access** in its setup → it now shows as a native tile, no browser.

## How to continue with Claude Code on the MacBook Pro

After `git clone https://github.com/LancmanGit/spellstar.git`, open the `spellstar` folder with Claude Code and say you want to build the native Assistive Access wrapper. Reference this file. Claude can write the full WKWebView Swift code and generate the app icon — the only things needing your hands are the Xcode GUI steps, signing, and the physical iPhone connection.

## Repo contents

- `SpellStar.html` — the entire app
- `manifest.json`, `sw.js` — PWA support (already live)
- `HANDOVER.md` — full feature/architecture history (v2)
- `NEXT_STEPS.md` — this file
