//
//  Settings.swift
//  BarTranslate
//
//  Created by Thijmen Dam on 19/07/2023.
//


import Foundation
import HotKey
import AppKit

enum TranslationProvider: String {
  case google
}

enum InPlaceAction: String, CaseIterable, Identifiable {
  case none
  case copy
  case paste

  var id: String { self.rawValue }
}

enum MenuBarIcon: String, CaseIterable, Identifiable {
  case yandex = "MenuIconYandex"

  var id: String { self.rawValue }
}

enum WebAppearance: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { self.rawValue }
}

struct DefaultSettings {

  static let translationProvider = TranslationProvider.google
  static let menuBarIcon = MenuBarIcon.yandex

  struct ToggleApp {
    static let key = Key(string: ";")!
    static let modifier = Key(string: "⌥")!
  }

  struct TranslateNow {
    static let key = Key.return
    static let modifier = Key.command
  }

  static let autoClipboardTranslate = false
  static let autoClipboardPaste = false
  static let historyLimit = 100
  static let inPlaceAction = InPlaceAction.none
  static let launchAtLogin = false
  static let pinPopover = false
  static let webAppearance = WebAppearance.system
  static let checkForUpdates = true
  static let iCloudSync = false

  struct SwapLang {
    static let key = Key.s
    static let modifier = Key.option
  }

  struct TranslateClipboard {
    static let key = Key.t
    static let modifier = Key.option
  }

  struct CopyResult {
    static let key = Key.c
    static let modifier = Key.option
  }

}

enum PopoverSize: String, CaseIterable, Identifiable {
  case compact
  case normal
  case wide

  var id: String { self.rawValue }

  var dimensions: (width: CGFloat, height: CGFloat) {
    switch self {
    case .compact: return (360, 450)
    case .normal: return (400, 500)
    case .wide: return (500, 560)
    }
  }
}
