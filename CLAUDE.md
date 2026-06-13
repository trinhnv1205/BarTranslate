# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BarTranslate is a native macOS menu bar translator widget that presents Google Translate in a WKWebView popover. Built with SwiftUI.

## Build Commands

```bash
# Open in Xcode
open BarTranslate.xcodeproj

# Build via command line
xcodebuild -project BarTranslate.xcodeproj -scheme BarTranslate -configuration Debug build

# Run
open -a BarTranslate
```

## Architecture

### Entry Point
- `BarTranslate/BarTranslateApp.swift` — `@main` entry point; contains `BarTranslate` (ObservableObject model), `TranslationHistoryItem` struct, and `AppDelegate`

### AppDelegate Responsibilities
- Menu bar status item and popover management
- Global hotkey registration via `HotKey` library
- Clipboard watcher for auto-translate feature
- KVO observation of UserDefaults for hotkey changes

### Views (BarTranslate/views/)
- `ContentView.swift` — Root view managing navigation between Translate/History/Flashcards/Settings via `CurrentContentView` enum
- `TranslateView.swift` — Contains `WebView` (WKWebView wrapper) and overlay UI (char counter, copy button)
- `HistoryView.swift` — Translation history list with search/filter
- `FlashcardView.swift` — Spaced-repetition flashcard review
- `SettingsView.swift` — App preferences

### WebView & JavaScript Injection
- `TranslateView.swift` contains `WebView` struct (NSViewRepresentable wrapping WKWebView)
- JavaScript message handlers: `charCount`, `resultAvailable`, `urlChanged`, `sourceBlur`
- Scripts injected after page load: `injections/features.swift` (char count, result observer, language tracker, source blur)
- CSS injection via `injections/style.swift` and `injections/css/`
- Focus injection via `injections/autofocus.swift`

### Data Model
- `BarTranslate` class holds all state: `currentView`, `history`, `webView`, language pair preferences
- History persisted to UserDefaults as JSON-encoded `[TranslationHistoryItem]`
- Flashcard spaced-repetition intervals defined in `nextReviewInterval(for:remembered:)`

### Settings
- `@AppStorage` properties in `AppDelegate` and views
- `DefaultSettings.swift` provides static defaults (hotkeys, provider, limits)
- Settings accessible via Settings menu or `SettingsView`

### Localization (i18n)
- `Localization.swift` — in-app translation layer. `"english".loc` returns the
  Vietnamese string (or English fallback) based on `AppLanguage`
  (System/English/Vietnamese, stored in `appLanguage`). Translations live in
  `viTable` in code (not `.strings`/`.xcstrings`) because many custom views take
  plain `String` params that SwiftUI renders verbatim, so system auto-l10n
  wouldn't apply. Apply `.loc` to user-facing English source literals.
- Shared `SettingsSection`/`SettingsRow`/`SettingsLinkRow` apply `.loc` to their
  title/label internally, so call sites pass English literals.
- Language picker: Settings ▸ General ▸ Language.

### Commercialization / Pro (freemium)
- `ProManager.swift` — `ProManager` singleton (`ObservableObject`) is the single
  source of truth for entitlements. `hasFullAccess == isPro || isTrialActive`
  (14-day trial). `ProFeature` enumerates gated capabilities. `LicenseValidator`
  does offline `BART-XXXX-XXXX-XXXX` key validation (SHA-256 checksum);
  `setPurchased(_:)` is the hook for a future StoreKit IAP.
- Gating: `enforceHistoryLimit()` caps free tier at `ProManager.freeHistoryLimit`
  (50); `exportHistoryCSV()` and `configureICloudSync(enabled:)` require full
  access. Use `requireFullAccess(for:)` to gate + show the paywall prompt.
- `views/ProView.swift` — `ProSettingsCard` (Settings upgrade card),
  `LicenseActivationView` (key entry sheet), `OnboardingView` +
  `OnboardingController` (first-run window, shown once via `presentIfNeeded()`).
- `Constants.Links` centralizes marketing/legal/support URLs.
- Legal docs live at repo root: `PRIVACY.md`, `TERMS.md`.

### Key Types
- `TranslationProvider` — Currently only `.google`
- `InPlaceAction` — `.none`, `.copy`, `.paste` (post-translate action)
- `MenuBarIcon` — `.yandex` (default)
