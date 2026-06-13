//
//  Constants.swift
//  BarTranslate
//
//  Created by Thijmen Dam on 26/05/2023.
//

import Foundation
import HotKey

struct Constants {

  struct AppSize {
    static let width = CGFloat(400)
    static let height = CGFloat(500)
  }

  /// Outbound links used across the app (marketing, legal, support).
  /// Centralized so they can be updated in one place before release.
  struct Links {
    static let website      = "https://github.com/trinhnv1205/BarTranslate"
    static let proPurchase  = "https://github.com/trinhnv1205/BarTranslate#pro"
    static let privacy      = "https://github.com/trinhnv1205/BarTranslate/blob/master/PRIVACY.md"
    static let terms        = "https://github.com/trinhnv1205/BarTranslate/blob/master/TERMS.md"
    static let appStore     = "macappstore://apps.apple.com/app/bartranslate"
    static let supportEmail = "trinhnv1205@gmail.com"
  }
}
