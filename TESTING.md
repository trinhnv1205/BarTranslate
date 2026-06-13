# Manual QA Checklist

A focused checklist for verifying this branch's changes after building in Xcode.
Grouped by feature; each item is a concrete, observable check.

## Build
- [ ] `BarTranslate (Debug)` builds and runs.
- [ ] `BarTranslate (App Store)` configuration builds (verifies `#if APPSTORE` paths).

## Pro / freemium
- [ ] Fresh install shows the trial as active in Settings ▸ BarTranslate Pro (days remaining).
- [ ] During trial: iCloud sync toggle is enabled, CSV export and Backup work, history limit can be set to 200.
- [ ] Simulate trial end (set `firstLaunchDate` back >14 days in `UserDefaults`):
  - [ ] One-time "trial has ended" prompt appears on next launch (only once).
  - [ ] iCloud sync toggle shows a PRO badge and is disabled.
  - [ ] CSV export / Backup show the paywall prompt naming "Export & backup".
  - [ ] History "Saved items" caps at 50; options >50 show "(Pro)" and trigger the paywall.
  - [ ] Existing **favorites are NOT deleted** when the limit drops to 50.
- [ ] License: enter an invalid key → error shown; enter a key from `LicenseValidator.generate(seed:)` → Pro unlocks.
- [ ] With a license active, "Deactivate this Mac" (confirmed) clears Pro.

## Localization (English / Tiếng Việt)
- [ ] Settings ▸ General ▸ Language: switching to Tiếng Việt translates the UI.
- [ ] Switch is **live across all tabs** (Translate / History / Flashcards / Settings) without restart.
- [ ] Switching language preserves History search text and the current flashcard.
- [ ] "System" follows the macOS language (Vietnamese system → Vietnamese UI).
- [ ] Brand strings ("BarTranslate Pro", "Google Translate", "PRO") stay as-is.

## History & backup
- [ ] Backup (JSON) → Restore on a clean install reproduces favorites and flashcard progress (full fidelity).
- [ ] Restore on a tier without Pro still works; Backup/CSV require Pro.
- [ ] Restoring an invalid file shows the "Couldn't read backup" alert.
- [ ] "Reuse" on a history entry with a different language pair restores that pair before translating.
- [ ] Searching with no matches shows "No matches" (not "No translations yet").

## Flashcards
- [ ] In "Due only" mode, grading a card advances to the next due card **without skipping one**.
- [ ] In all-cards mode, Prev/Flip/Again/Remembered behave as before.

## Translate / WebView
- [ ] Go offline → an offline message with a Retry button appears (no infinite spinner); Retry reloads when back online.
- [ ] Translating text containing `${...}` (e.g. `Hello ${name}`) injects/translates it correctly.
- [ ] With auto-translate-clipboard + in-place Copy on: a single translation does **not** loop/re-translate its own output.
- [ ] Enabling "Paste to previous app" prompts for Accessibility permission; paste-back then works.

## General
- [ ] Quit (menu bar power button and Settings) exits cleanly and persists the last setting change.
- [ ] About shows version, build, and a copyright line.
- [ ] Support & Legal links open (feedback mail, website, Privacy, Terms).
