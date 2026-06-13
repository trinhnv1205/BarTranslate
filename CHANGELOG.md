# BarTranslate Changelog

## Unreleased | BarTranslate Pro

A commercialization milestone: BarTranslate becomes a freemium app.

- **Free 14-day trial** that unlocks every premium feature, after which Pro
  features require a one-time unlock (`ProManager`).
- **Offline license activation** via `BART-XXXX-XXXX-XXXX` keys, with the
  entitlement layer structured for a future StoreKit in-app purchase.
- **Pro upgrade card** in Settings showing trial/Pro status, plus a license-key
  entry sheet.
- **First-run onboarding** window introducing core features and the trial.
- **Support & Legal** section in Settings: send feedback, rate the app, website,
  Privacy Policy, and Terms of Use.
- Added **Privacy Policy** (`PRIVACY.md`) and **Terms of Use** (`TERMS.md`).
- History retention, iCloud sync, and CSV export are now Pro features. The free
  tier keeps up to 50 history items; Pro/trial unlocks the full 200.
- Pro card now offers **Deactivate this Mac** to move a license between Macs.
- Onboarding lets you **choose your primary target language**.
- The history "Saved items" picker honestly reflects the free-tier cap.
- Request an **App Store rating** after sustained use (once per version).
- Set the app **copyright**; show version, build, and copyright in About.
- Full-fidelity **JSON backup & restore** of history (favorites and flashcard
  progress included); restore merges and is available on every tier.
- **Vietnamese localization** of the entire UI, with a language picker
  (System/English/Tiếng Việt) in Settings ▸ General.

### Fixed
- Never auto-delete **favorites** when enforcing the history limit (no silent
  data loss when a trial ends).
- Show a friendly **offline / retry** state instead of an endless spinner when
  Google Translate can't be reached.
- History **Reuse** now restores the entry's original language pair before
  re-translating.
- Prompt for **Accessibility** permission when enabling paste-back, which
  needs it to synthesize ⌘V.

### Chore
- Stop tracking generated `build/` artifacts in version control.

## v2.0.0 | Autofocus; Removed DeepL

- When opening BarTranslate, the translation input is now focussed automatically (except on startup).
- Removed DeepL due to compatibility issues with WKWebView. 

## v1.2.0 | CSS Hosted Externally

This is a nice one! 🚀

1. The CSS injected into the translation pages is now hosted [externally](https://gist.github.com/ThijmenDam/6d8727f27ff1a1c5397682d866ffae9b). This allows for interface adjustments to be made on-the-fly whenever Google or DeepL updates their translation page, eliminating the need to download a new release when this happens.

2. Fixed the briefly visible change in styling when switching from application settings to the translation view (#44). Big thanks to @BepsiKohler for the contribution!

## v1.1.0 | Configurable Menu Bar Icon

Thanks to the great work of @BepsiKohler, BarTranslate now has a configurable menu bar icon.

## v1.0.0

BarTranslate switched from Electron to SwiftUI! In other words, macOS is now natively supported.

## Prior Releases

Because BarTranslate switched from Electron to SwiftUI at version 1.0.0, prior releases are not included in this file.
