# SpellStar — Handover Document
**Last updated: 2026-06-21 (v2)**

---

## What this is
A single-file web app (`SpellStar.html`) for children's spelling practice, aligned to the Australian Curriculum. Built with React 18 (CDN) + Babel standalone + Web Speech API. No build step — open the HTML file directly in a browser or serve via the local Python HTTP server.

---

## The file
`/Users/olivialancman/Claude/Projects/Spelling App/SpellStar.html`
- ~200KB, ~2059 lines
- **Line 221** is one giant line (~104KB) — the embedded word data JSON (`const WORD_DATA = [...]`). **Never touch this line.** Use targeted string replacements for all other edits.

---

## Running the app
A Python HTTP server is configured in `.claude/launch.json`:
```
http://localhost:7432/SpellStar.html
```
Start with: `python3 -m http.server 7432 --directory "/Users/olivialancman/Claude/Projects/Spelling App"`

**Important:** Babel is pinned to `@babel/standalone@7`. Do not upgrade — Babel 8 defaults to ES module output which breaks plain `<script>` tags.

---

## Architecture (all in one file)
```
<style>                 CSS custom properties + component styles (lines ~15–220)
<script>                WORD_DATA JSON (line 221)
<script type="text/babel">
  Constants             SESSION_SIZE=8, CRAM_SESSION_SIZE=30, CRAM_DAYS=30
  TTS                   ttsGen counter, cancelTTS(), speakWordSequence(), speakSyllable(),
                        speakSyllables(), initVoices()
  Sentence gen          WORD_SENTENCES lookup (~200 entries) + generateSentence() fallback
  Utilities             todayStr, yesterdayStr, addDays, daysBetween, loadStore, saveStore
  Word helpers          buildSession(), buildCramSession(), buildReviewSession (inline in App),
                        updateWordProgress(), getProgressStats(), getCramProgress(),
                        getStrugglingWords()
  Level helpers         LEVEL_CRESTS[], getLevelProgress()
  Sound It Out          syllabify(), levenshtein(), isPhoneticNearMiss(), getLetterFeedback()
  Components            WelcomeScreen → SetupScreen → DiagnosticScreen → HomeScreen
                        → PracticeScreen → SessionEndScreen
                        CramSetupScreen
                        PinScreen → ParentDashboard
                        ProgressScreen
  App                   Main state machine, screen router
```

---

## Storage
`localStorage` key `spellstar_v3`. Shape:
```js
{
  profile: {
    name, age, levelIdx, streak, lastPlayed, totalXP, spellingAge,
    streakFrozen, freezeUntil,
    // (no hearts — removed)
    streakRepairAvailable, streakRepairDeadline, streakBeforeBreak,
    cramMode: {
      active,           // bool
      targetLevelIdx,   // year level index being targeted
      startDate,        // 'YYYY-MM-DD'
      masteredAtStart,  // string[] — words already mastered when CRAM began (excluded from sessions)
    }
  },
  progress: { [word]: { stage:0-4, correct, wrong, nextReview, lastSeen, skipped?, lastSkipped? } },
  // skipped: true if word was skipped; cleared to false on correct answer
  // lastSkipped: 'YYYY-MM-DD' of the skip — skipped words re-enter the queue the following day
  customWords: [{ word, addedBy, date, sentence }]
}
```
Additional keys:
- `ss_pin` — parent PIN (default `1234`)
- `ss_theme` — `"dark"` or `"light"`
- `ss_bg` — background name (`"space"` | `"ocean"` | `"sunset"` | `"aurora"` | `"galaxy"` | `"rose"`)

---

## Word data structure
```js
WORD_DATA = [
  { label: "Foundation", age: "4-6", cats: [{ cat: "...", words: [...] }] },
  // 12 levels: Foundation through Year 11-12, ~9,184 words total
]
```

---

## Spaced repetition
**Normal mode intervals:** `REVIEW_INTERVALS = [0, 1, 3, 7, 30]` days
**CRAM mode intervals:** `CRAM_INTERVALS  = [0, 0, 1, 3, 7]` days (4× faster)

Stages: **New(0) → Shaky(1) → Learning(2) → Consolidating(3) → Mastered(4)**

---

## TTS — critical: generation counter
```js
let ttsGen = 0;
function cancelTTS() { ttsGen++; window.speechSynthesis?.cancel(); }
```
Every `speakWordSequence` call captures the current `ttsGen`. Pending `setTimeout` callbacks bail out if `ttsGen` has moved on. **Always call `cancelTTS()` instead of `window.speechSynthesis.cancel()` directly** — bare cancel triggers `onerror` which restarts the sequence.

---

## Key components & state

### PracticeScreen phases
`speaking → answering → feedback → retry → correct`
- Input visible during ALL phases including `speaking` (user can type while audio plays)
- `hintLevel` — 0 or 1 (hint used)
- `attemptCount` — enables Skip after 2 attempts

### TTS functions
```js
cancelTTS()                           // abort in-flight sequence
speakWordSequence(word, sentence, onStateChange)
// onStateChange: 'word' | 'word2' | 'sentence' | 'done'
speakSyllable(text)                   // single syllable, rate 0.55
speakSyllables(syllables, onDone)     // sequential, 380ms gaps
```

### Level crests
```js
LEVEL_CRESTS = [
  { emoji:'🌱', color:'#86EFAC' },  // Foundation
  { emoji:'⭐', color:'#FDE68A' },  // Year 1
  { emoji:'🔵', color:'#93C5FD' },  // Year 2
  { emoji:'🌙', color:'#C4B5FD' },  // Year 3
  { emoji:'🦅', color:'#FCA5A5' },  // Year 4
  { emoji:'⚡', color:'#FCD34D' },  // Year 5
  { emoji:'🔥', color:'#FB923C' },  // Year 6
  { emoji:'🗡️', color:'#6EE7B7' },  // Year 7
  { emoji:'🦁', color:'#FDE68A' },  // Year 8
  { emoji:'🌊', color:'#67E8F9' },  // Year 9
  { emoji:'🏆', color:'#F9A8D4' },  // Year 10
  { emoji:'👑', color:'#FFD700' },  // Year 11-12
]
```

---

## Changes log: v1 → current

### Change 1 — Babel CDN fix
**Before:** CDN loaded unversioned `@babel/standalone/babel.min.js`. Babel 8 silently activated, outputting ES module `import` statements → app blank on load.
**After:** Pinned to `@babel/standalone@7/babel.min.js`.

---

### Change 2 — Individual sentences per word
**Before:** `generateSentence()` used shared category-aware templates — multiple words could get identical sentence patterns.
**After:**
- Added `WORD_SENTENCES` object (~200 hand-crafted entries) for Foundation sight words, animals, colours, numbers, body parts, homophones, and commonly confused words.
- Homophones have sentences that convey meaning (e.g. "their" vs "there" vs "they're").
- `generateSentence()` checks `WORD_SENTENCES[word.toLowerCase()]` first; falls through to templates for unrecognised words.
- `SentenceWithBlank` component renders the sentence with the word replaced by a styled underline blank, and speaks "blank" via TTS.

---

### Change 3 — Light/dark mode toggle
**Before:** Dark theme only, hardcoded.
**After:**
- `theme` state in `App`, initialised from `localStorage` key `ss_theme` (default `"dark"`).
- `useEffect` applies `document.body.dataset.theme` and persists to localStorage.
- Added `body[data-theme="light"]` CSS overrides for all custom properties.
- Toggle button in an appearance bar at the bottom of HomeScreen.

---

### Change 4 — Multiple backgrounds
**Before:** Single fixed background gradient.
**After:**
- `background` state in `App`, initialised from `localStorage` key `ss_bg` (default `"space"`).
- 6 backgrounds: Space (purple), Ocean (teal), Sunset (orange), Aurora (green), Galaxy (blue), Rose (pink).
- `body[data-bg="X"]` CSS overrides for `--bg`, `--bg2`, `--card` per background.
- Colour-coded dot picker in the appearance bar on HomeScreen.

---

### Change 5 — Custom words require a sentence
**Before:** `customWords` stored as `{ word, addedBy, date }`. No sentence required.
**After:**
- Parent Dashboard requires a sentence field when adding a custom word.
- Validation: the word must appear in the sentence.
- Auto-wraps word in double quotes if not already present.
- Stored as `{ word, addedBy, date, sentence }`.
- `PracticeScreen` uses `cw.customSentence` when available.

---

### Change 6 — Sound It Out redesign (audio only, no letter reveals)
**Before:** 3-level hint system: (1) first syllable audio, (2) all syllables audio, (3) visual letter grid (`S__ / a / ____`). Each click revealed more. Changed `phase` to `'hinting'`, hiding the input.
**After:**
- Single "💡 Sound it out" button — plays word syllable-by-syllable via audio only. No visual breakdown shown.
- Added `speakSyllables(syllables, onDone)` — iterates syllable array with 380ms pauses.
- `useHint()` simplified: sets `hintLevel = 1`, calls `speakSyllables()`. Does **not** change phase — input stays visible.
- Hint panel JSX removed entirely.
- Button is **disabled + greyed out** (`opacity: 0.35`) when `syllables.length <= 1` (single-syllable words).
- Added `autoComplete="off"` to the answer input (already had `autoCorrect="off" spellCheck="false"`).
- Removed `hintVisual` variable.

---

### Change 7 — Type while audio plays
**Before:** `showInput = phase === 'answering' || phase === 'retry'` — input hidden during TTS.
**After:** `showInput = phase === 'speaking' || phase === 'answering' || phase === 'retry'` — input visible immediately so user can start typing while the word is being read aloud.

---

### Change 8 — Audio cut on correct answer
**Before:** `window.speechSynthesis.cancel()` called on correct answer, but `onerror` callback in `speakWordSequence` triggered `setTimeout(next, 100)` — the sequence restarted after 100ms despite the cancel.
**After:**
- Added module-level `ttsGen` counter and `cancelTTS()` function.
- `speakWordSequence` captures `gen = ttsGen` at start; all `setTimeout` callbacks check `if (ttsGen !== gen) return`.
- `onerror` only continues if `ttsGen === gen` (not aborted).
- All `window.speechSynthesis.cancel()` calls replaced with `cancelTTS()` throughout.
- Effect: correct answer immediately and truly stops all pending audio; next word's TTS starts clean.

---

### Change 9 — Due Review tab shows same-day words (greyed out)
**Before:** Due Review tab in Progress screen only showed words where `nextReview <= today`.
**After:**
- Shows all words practiced today (`lastSeen === today`) at stages 1–3, whether or not they're due yet.
- Words due: full opacity, labelled "Ready ✓".
- Words not yet due: 40% opacity, labelled "From YYYY-MM-DD".
- Due words sorted to top.

---

### Change 10 — Home screen Due Review count synced to Progress section
**Before:** Home screen `dueReview` stat used `nextReview <= today` (only actually-due words).
**After:** Uses same filter as Progress section: `nextReview <= today || lastSeen === today` — count always matches what the Due Review tab shows.

---

### Change 11 — Due Review card launches a review session
**Before:** Due Review stat card on home screen was display-only.
**After:**
- Card is clickable when `dueReview > 0` (shows border highlight + "→" arrow on label).
- Clicking launches `handleStartReview()`: builds a session of all currently-due words.
- In **normal mode**: pulls due words from current level only.
- In **CRAM mode**: pulls due words from all levels between current and target, ordered by level (easiest first).

---

### Change 12 — Year level crest badges + progress bar
**Before:** HomeScreen showed "Spelling Age: Year 1" as plain text.
**After:**
- Added `LEVEL_CRESTS` array (12 entries) with unique emoji, label, and accent colour per level.
- Added `getLevelProgress(levelIdx, progress)` helper counting mastered words in current and next level word lists.
- HomeScreen now shows: crest emoji + level name (in crest colour) + arrow to next level + progress bar (threshold: 25% of next level's words mastered) + percentage.
- At Year 11-12 (max level): shows "👑 Maximum level reached!" instead.

---

### Change 13 — CRAM Mode (30-day express pathway)
**Before:** No CRAM mode.
**After:** Full CRAM mode system:

**Constants added:**
```js
CRAM_SESSION_SIZE = 30   // words per session (~30 min)
CRAM_INTERVALS = [0,0,1,3,7]  // vs normal [0,1,3,7,30]
CRAM_DAYS = 30
```

**`buildCramSession(profile, progress)`:**
- Pass 1: due reviews across all levels in range (shuffled — already known, just reinforcing).
- Pass 2: new words in strict level order — current level exhausted before moving up.
- Both passes skip words in `cramMode.masteredAtStart` (pre-existing mastery snapshot).

**`getCramProgress(profile, progress)`:**
- Excludes `masteredAtStart` words from both `total` and `mastered` counts.
- Returns `{ daysDone, daysLeft, mastered, total, pct }`.
- Called live in HomeScreen with current `progress` prop — percentage updates automatically as words are mastered.

**`updateWordProgress(progress, word, correct, isCram=false)`:**
- Added `isCram` param; uses `CRAM_INTERVALS` when true.

**`handleCramStart(targetLevelIdx)`:**
- Snapshots `masteredAtStart = Object.keys(progress).filter(w => progress[w].stage >= 4)`.
- Stores in `cramMode` object on profile.

**`CramSetupScreen` component:**
- Pick target level (only shows levels above current).
- Visual journey bar: current crest → gradient bridge → target crest.
- Stats panel: total words / 30 words/session / 30-day program.
- "⚡ Start 30-Day CRAM →" button.

**HomeScreen when CRAM active:**
- Quest card replaced by teal CRAM card.
- Shows: day X/30, target level crest, mastered % progress bar, words mastered/total, days remaining.
- "⚡ Start CRAM Session" + "Exit CRAM mode" buttons.
- When CRAM inactive: "⚡ Start 30-Day CRAM Mode" button shown below normal Start Practice button.

**Session end:** Shows "⚡ CRAM Session Complete — keep going tomorrow!" banner after CRAM sessions.

**Auto-completion:** CRAM deactivates when 30 days elapsed or 100% mastered.

---

### Change 14 — Hearts system removed
**Before:** `HEARTS_MAX=3` constant, `hearts` state in PracticeScreen, heart emoji display in the top bar. Skipping cost a heart; 0 hearts ended the session early.
**After:** Hearts system entirely removed. No `HEARTS_MAX`, no heart CSS, no heart state. Skip button appears after 2 attempts with no penalty — it's neutral. Session always runs to completion.

---

### Change 15 — Skipped word tracking
**Before:** Skipped words recorded as `{ correct: false }` only.
**After:**
- `skipWord()` passes `{ skipped: true }` in the result object.
- `updateWordProgress()` accepts a `skipped` 5th param: sets `skipped: true` + `lastSkipped: todayStr()` on the progress record; clears `skipped: false` on a correct answer.
- `buildSession()` now has three passes: (1) due reviews, (2) skipped words from a previous day (priority re-entry before new words), (3) new words.

---

### Change 16 — `getStrugglingWords()` helper
Added `getStrugglingWords(progress)` — returns `[word, progressEntry]` pairs where either `skipped: true` OR `wrong >= 3 && stage <= 2`. Sorted by `wrong` count descending.

---

### Change 17 — Struggling tab on ProgressScreen
Added a fifth tab **"Struggling 🔥"** to ProgressScreen alongside All / Mastered / Learning / Due Review.
- Shows all words from `getStrugglingWords()`.
- Each card shows: word, wrong count, skipped label if applicable, stage badge.
- Empty state: encouraging message "Nothing here — you're on top of it! 💪".
- `ProgressScreen` accepts an `initialTab` prop to pre-select a tab on mount.

---

### Change 18 — Struggling stat card on HomeScreen
- HomeScreen calls `getStrugglingWords(progress).length` to get the count.
- If count > 0: renders an extra stat card "🔥 N / Struggling →" in the stat grid with a red border.
- Tapping it calls `onProgress('struggling')` which navigates to ProgressScreen with the Struggling tab pre-selected.
- The `onProgress` handler in App now accepts an optional `tab` arg and stores it in `progressTab` state, passed as `initialTab` to ProgressScreen.

---

## Known patterns & gotchas
- **Always use `cancelTTS()`** — never `window.speechSynthesis.cancel()` directly.
- Voice selection priority: en-AU (Karen/Zoe/Nicky) > en-AU any > en-GB Enhanced > en-GB > en-US Samantha > any en.
- Syllabify uses heuristic V-CV / VCC-CV rules — not a dictionary.
- Parent PIN stored in localStorage as plain text (`ss_pin`).
- CSS theming uses custom properties on `:root`, overridden by `body[data-theme]` and `body[data-bg]` attribute selectors.
- Spelling year level is set at diagnostic and **not** automatically updated during practice. Level progression is currently manual.
- CRAM `masteredAtStart` snapshot only taken at CRAM activation — words mastered mid-CRAM correctly count toward CRAM progress.

---

## Suggested next features
1. **Automatic level promotion** — after enough mastered words at current level, prompt parent to bump year level (`getLevelProgress` helper already in place).
2. **Progress export/import** — "Download my progress" JSON + restore, to protect against localStorage loss.
3. **Multiple child profiles** — currently one profile per device.
4. **Achievements/badges** — first 10 mastered, 7-day streak, CRAM complete, etc.
5. **PWA / offline mode** — service worker + manifest so it installs as an app on tablets.
6. **Child word additions** — let child add their own words from home screen (currently parent-only).
