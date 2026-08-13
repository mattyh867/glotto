# Glotto — Design Plan

*Working title. Swap in your final chosen name throughout before publishing the repo.*

## 1. Product summary

A native iOS app that surfaces one word a day — with a short definition — as a Lock Screen widget. Built first for personal use while learning Thai, with English as the initial second language and an architecture that supports adding more languages later without a redesign.

**Core loop:** open the widget on your lock screen throughout the day -> glance at today's word -> tap to open the app for the full definition, romanization, and example sentence.

## 2. Scope

### In scope for v1
- One shared word per day, same for all installs, deterministic by date
- Two languages: English and Thai, user picks a focus language on first launch
- Lock Screen widgets: `accessoryRectangular` and `accessoryInline`
- Main app: today's word in full detail, a simple word history, and a language switch in settings
- Content sourced from Wiktionary's Thai-language entries only (words that already have a documented Thai section), stored as static versioned JSON in the repo — no backend
- iOS 16 minimum

### Deliberately out of scope for v1
- Personalized/per-user word rotation
- Server/backend of any kind
- Notifications, streaks, quizzes, saved-word review, audio pronunciation
- StandBy widget (near-free add-on once the core widget works — good Phase 2 target, not v1)
- Monetization (ads, IAP) — irrelevant until this has real users beyond you

Keeping v1 this narrow is deliberate: as a solo dev building for personal use first, the fastest path to "I actually use this every day" is more valuable right now than a feature-complete app nobody's validated yet.

## 3. Content architecture

### Sourcing pipeline (one-time / periodic, done by hand or semi-scripted, not runtime)
1. Pull the Thai-language slice of Wiktionary's bulk data export (via a kaikki.org-style pre-processed dump).
2. Filter to entries with a genuine Thai section and an English gloss.
3. Hand-review the filtered list; select words that are useful for a learner rather than obscure.
4. For each selected word, record: Thai script, romanization (if present in the source), part of speech, English gloss, example sentence (if present).
5. Shorten the gloss into a widget-length version (a handful of words) separately from the full definition shown in-app.
6. Append to the language's JSON file, commit to the repo.

### Data files
```
/content
  en.json
  th.json
```

### Entry schema (per word)
```json
{
  "id": "th-0001",
  "word": "สวัสดี",
  "romanization": "sawatdee",
  "partOfSpeech": "interjection",
  "glossShort": "hello; a common greeting",
  "definitionFull": "A common greeting used at any time of day...",
  "example": {
    "text": "สวัสดีตอนเช้า",
    "translation": "Good morning"
  },
  "source": "wiktionary",
  "sourceUrl": "https://en.wiktionary.org/wiki/..."
}
```

### Word-of-the-day selection
`index = dayOfYear % entries.length` — no state, no server, trivially testable, same word for everyone on a given date. Attribution to Wiktionary (required under CC BY-SA 4.0) goes on a simple "Sources" screen in Settings, linking each word back to its Wiktionary page via `sourceUrl`.

## 4. iOS app architecture

```
GlottoApp/              — main app target (SwiftUI)
GlottoWidget/           — WidgetKit extension target
GlottoShared/           — shared framework: models, content loading, date logic
  ├─ WordEntry.swift
  ├─ ContentStore.swift     (loads/decodes the JSON files)
  └─ TodayWordProvider.swift (date → entry lookup, shared by app + widget)
```

- **App Group** shared between the app and widget targets so both read the same bundled content and the same user default for "focus language."
- Content JSON ships bundled inside the app (no network calls needed at runtime) — this is what makes the whole thing work fully offline and removes any backend/hosting concern.
- `TimelineProvider` in the widget schedules its next reload for the next local midnight, so it recomputes `dayOfYear % length` once a day and otherwise sits idle (good for battery, matches how the system wants widgets to behave).

## 5. Widget design

| Family | Content | Notes |
|---|---|---|
| `accessoryRectangular` | Word (Thai script + romanization) on line 1, short gloss on line 2 | Primary widget — most usable space (2-4 lines) |
| `accessoryInline` | Word only | Single line above the clock, teaser-style |

Constraints to design around:
- System renders these **monochrome/tinted** — no custom colors, so typography and layout carry all the visual weight
- No interactivity in v1 (iOS 17+ interactive widgets are a nice future add, not needed for a passive glance)
- Thai script has no spaces between words, so test real Thai strings in both widget families early — line-wrapping behaves differently than English

## 6. Main app — information architecture

```
Onboarding (first launch only)
  └─ Pick focus language (Thai / English)

Today (home)
  ├─ Word, romanization, part of speech
  ├─ Full definition
  ├─ Example sentence + translation
  └─ Source attribution link

History
  └─ Scrollable list of past words (date + word), tap to view detail

Settings
  ├─ Focus language toggle
  └─ Sources / attribution (Wiktionary link, per current word)
```

Three screens total for v1. No accounts, no sync, no settings beyond the language toggle.

## 7. Repo structure

```
/GlottoApp.xcodeproj
/GlottoApp/            (SwiftUI app target)
/GlottoWidget/          (WidgetKit extension target)
/GlottoShared/          (shared framework)
/content/
  en.json
  th.json
/scripts/
  fetch_wiktionary.py   (pulls + filters the bulk Thai data dump)
/DESIGN.md              (this file)
/README.md
```

Keeping content as plain JSON in the repo (rather than in a database or CMS) means every content change is a normal, reviewable git commit — useful even solo, and it means if you ever want help curating words later, it's just a pull request.

## 8. Build sequence

1. **Content pipeline** - script the Wiktionary bulk-data filter, hand-pick and format the first ~60 words (two months' worth) for Thai
2. **Widget proof of concept** — get `accessoryRectangular` and `accessoryInline` rendering real Thai text on a physical device, using hardcoded sample data
3. **Shared content loading** — `ContentStore` + `TodayWordProvider` in the shared framework, wired to the real JSON via App Group
4. **Main app** — the three screens above, reading from the same shared layer
5. **Polish** — real device testing for Thai line-wrapping, App Store metadata, TestFlight for yourself
6. **Ongoing** — keep curating words in batches; revisit English content, StandBy widget, and any personalization once the Thai-only version is something you're actually using daily

## 9. Open decisions to revisit later

- Whether to keep "same word for everyone" once/if this has other users, or add per-user rotation
- Whether English content also sources from Wiktionary-only, or gets a richer source once the pattern is proven
- Whether to formalize the Wiktionary fetch script into something re-runnable for future languages, or keep it a one-off per language