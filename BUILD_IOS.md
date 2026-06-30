# Building the SpellStar iOS app (Assistive Access wrapper)

This is a tiny native iOS app that loads the bundled `SpellStar.html` in a
full-screen `WKWebView`. No address bar, no browser chrome — which is what lets
it appear as its own tile in **iOS Assistive Access**.

The Xcode project is already built and committed. You do **not** need to create
a project or drag files in — just open it and run.

## Prerequisites

1. **Xcode** (full app, from the Mac App Store — ~7 GB). Command Line Tools
   alone are not enough.
2. Your **Apple ID** (free is fine — see signing note below).
3. A **USB cable** to connect the iPhone the first time.

## Project layout

```
spellstar/
├── SpellStar.html                  ← the actual app (single source of truth)
├── SpellStar.xcodeproj/            ← open this in Xcode
└── SpellStarApp/
    ├── SpellStarApp.swift          ← @main entry point
    ├── ContentView.swift           ← the WKWebView wrapper
    ├── Info.plist
    └── Assets.xcassets/            ← app icon (gold star) + accent colour
```

The project references `../SpellStar.html` directly, so there is only ever one
copy of the app. Olivia edits `SpellStar.html`, you rebuild, done.

## Steps

1. Open **`SpellStar.xcodeproj`** in Xcode.
2. Select the **SpellStar** target → **Signing & Capabilities** tab.
   - Tick **Automatically manage signing**.
   - **Team:** pick your Apple ID. If it's not listed, *Add an Account…* and
     sign in with your Apple ID (free account is fine).
   - If it complains the bundle ID is taken, change
     **`com.lancman.spellstar`** to something unique like
     `com.lancman.spellstar.benn`.
3. Plug in the iPhone via USB. Pick it as the run destination (top bar, next to
   the SpellStar scheme). First connect may prompt to "Trust This Computer" on
   the phone.
4. Press **▶ Run** (⌘R). Xcode builds, installs, and launches it.
5. On the iPhone: **Settings → General → VPN & Device Management** → tap your
   Apple ID under *Developer App* → **Trust**. Re-launch the app.
6. Add SpellStar to **Assistive Access**: Settings → Accessibility → Assistive
   Access → set it up and enable the SpellStar tile. It now appears as a native
   app with no browser reachable.

## Free Apple ID = 7-day expiry

With a free Apple ID the app **stops working after 7 days**. To renew: plug the
iPhone back into this Mac, open the project, press ▶ Run again. That's the whole
chore. (A $99/yr Apple Developer account removes the expiry — switch any time by
enrolling and re-selecting the team in step 2.)

## ⚠️ Offline caveat (read this)

`SpellStar.html` loads **React, ReactDOM, and Babel from the unpkg CDN**:

```html
<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@babel/standalone@7/babel.min.js"></script>
```

So **the app needs wifi to start**, even though the HTML itself is bundled. For
a child's device that's usually fine on home wifi, but it is *not* truly offline
yet. To make it fully offline (recommended for a locked-down kid device):

- Download those three scripts into a `vendor/` folder next to `SpellStar.html`.
- Change the three `<script src>` tags to point at the local files.
- Add the `vendor/` folder to the Xcode target's *Copy Bundle Resources*.

This also speeds up the live GitHub Pages PWA. Ask Claude to do the vendoring —
it's a mechanical change but touches Olivia's living HTML, so it's kept separate
from this first build.
