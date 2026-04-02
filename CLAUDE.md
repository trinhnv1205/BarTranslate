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

### Key Types
- `TranslationProvider` — Currently only `.google`
- `InPlaceAction` — `.none`, `.copy`, `.paste` (post-translate action)
- `MenuBarIcon` — `.yandex` (default)
