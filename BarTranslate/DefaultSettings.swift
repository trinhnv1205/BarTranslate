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

}
