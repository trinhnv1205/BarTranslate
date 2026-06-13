//
//  focusInjection.swift
//  BarTranslate
//
//  Created by Thijmen Dam on 18/05/2025.
//

import Foundation
import WebKit

func injectFocusScript(webView: WKWebView, provider: TranslationProvider) {
  // Guard against a missing textarea (page not yet loaded / different page),
  // which would otherwise throw a TypeError.
  let script = "var ta = document.querySelector('textarea'); if (ta) ta.focus();"

  webView.evaluateJavaScript(script) { result, error in
    if let error = error {
      print("Autofocus JS injection failed: \(error)")
    } else {
      print("Autofocus JS injected successfully.")
    }
  }
}
