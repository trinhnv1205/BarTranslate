//
//  Injections.swift
//  BarTranslate
//
//  Created by Thijmen Dam on 28/05/2023.
//
//  References:
//  https://medium.com/@mahdi.mahjoobi/injection-css-and-javascript-in-wkwebview-eabf58e5c54e
//  https://stackoverflow.com/questions/38952420/swift-wait-until-datataskwithrequest-has-finished-to-call-the-return

import Foundation
import SwiftUI
import WebKit

private func readFileBy(name: String, type: String) -> String {
  guard let path = Bundle.main.path(forResource: name, ofType: type) else {
    return "Failed to find path"
  }
  
  do {
    return try String(contentsOfFile: path, encoding: .utf8)
  } catch {
    return "Couldn't read file contents"
  }
}

private func encodeStringTo64(fromString: String) -> String? {
  let plainData = fromString.data(using: .utf8)
  return plainData?.base64EncodedString(options: [])
}

private func inject(webView: WKWebView, css: String, provider: TranslationProvider) {
  let javascript = """
    (function() {
      var existing = document.getElementById('BarTranslate-css');
      if (existing) { existing.remove() }

      var style = document.createElement('style');
      style.id = 'BarTranslate-css';
      style.type = 'text/css';
      style.innerHTML = window.atob('\(encodeStringTo64(fromString: css) ?? "")');
    
      var parent = document.getElementsByTagName('head').item(0);
      if (parent) { parent.appendChild(style); }
    })()
  """
    
  webView.configuration.userContentController.addUserScript(
    WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
  )
  
  // Also evaluate immediately in case the document is already loaded
  webView.evaluateJavaScript(javascript, completionHandler: nil)
}

private func fallbackCSS(provider: TranslationProvider) -> String {
  return readFileBy(name: "\(provider)", type: "css")
}

// Injects CSS into the translation webview, such that redundant elements are hidden.
func injectCSS(webView: WKWebView, provider: TranslationProvider) {
  // Links to the CSS that has to be injected for Google translate
  let gistGoogle = "https://gist.github.com/ThijmenDam/6d8727f27ff1a1c5397682d866ffae9b/raw/css-injection-google.css"
  let gistURL = URL(string: gistGoogle)!
  
  // 1. Synchronously inject the local fallback CSS immediately to prevent FOUC (Flash of Unstyled Content)
  let localCSS = fallbackCSS(provider: provider)
  inject(webView: webView, css: localCSS, provider: provider)
  
  // 2. Asynchronously fetch the latest CSS update without blocking the main thread
  let task = URLSession.shared.dataTask(with: gistURL) { data, response, error in 
    if let error = error {
      print("[WARNING] Failed to retrieve GitHub Gist. Reason: \(error)")
    } else if let data = data, let response = response as? HTTPURLResponse {
      if response.statusCode == 200 {
        if let fetchedCSS = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                inject(webView: webView, css: fetchedCSS, provider: provider)
                print("Injected remote CSS for \(provider)")
            }
        }
      } else {
        print("[WARNING] Failed to retrieve GitHub Gist. Reason: HTTP \(response.statusCode)")
      }
    }
  }
  task.resume() 
}



