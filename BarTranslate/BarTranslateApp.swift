//
//  BarTranslateApp.swift
//  BarTranslate
//
//  Created by Thijmen Dam on 26/05/2023.
//

import Cocoa
import SwiftUI
import HotKey
import WebKit
import Carbon.HIToolbox

@main
struct BarTranslateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      EmptyView()
    }.commands {
      CommandGroup(replacing: CommandGroupPlacement.newItem) {}
    }
    Settings {
      SettingsView()
    }
  }
}

// MARK: - BarTranslate Model

class BarTranslate: ObservableObject {
    @Published var currentView: CurrentContentView = .translate
    @Published var isLoading: Bool = true
    @Published var characterCount: Int = 0
    @Published var hasResult: Bool = false
    @Published var justCopied: Bool = false
    @Published var history: [TranslationHistoryItem] = []

    var webView: WKWebView?
    private var lastHistoryFingerprint: String?

    private let historyStorageKey = "translationHistory"

    // Remember last language pair
    var lastSourceLang: String {
        get { UserDefaults.standard.string(forKey: "lastSourceLang") ?? "auto" }
        set { UserDefaults.standard.set(newValue, forKey: "lastSourceLang") }
    }
    var lastTargetLang: String {
        get { UserDefaults.standard.string(forKey: "lastTargetLang") ?? "vi" }
        set { UserDefaults.standard.set(newValue, forKey: "lastTargetLang") }
    }

    init() {
        loadHistory()
    }

    func reloadWebView(for provider: TranslationProvider) {
        guard let webView = webView else { return }

        let sl = lastSourceLang
        let tl = lastTargetLang
        let urlString = "https://translate.google.com/?sl=\(sl)&tl=\(tl)&op=translate"
        let providerURL = URL(string: urlString)!
        let request = URLRequest(url: providerURL)

        webView.load(request)
        injectCSS(webView: webView, provider: provider)
    }

    var sortedHistory: [TranslationHistoryItem] {
        history.sorted {
            if $0.isFavorite != $1.isFavorite {
                return $0.isFavorite && !$1.isFavorite
            }
            return $0.createdAt > $1.createdAt
        }
    }

    func filteredHistory(query: String, languageFilter: String) -> [TranslationHistoryItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return sortedHistory.filter { item in
            let matchesLanguage = languageFilter == "all"
                || item.sourceLang == languageFilter
                || item.targetLang == languageFilter
            guard matchesLanguage else { return false }

            guard !trimmedQuery.isEmpty else { return true }
            let q = trimmedQuery.lowercased()
            return item.sourceText.lowercased().contains(q)
                || item.resultText.lowercased().contains(q)
                || item.sourceLang.lowercased().contains(q)
                || item.targetLang.lowercased().contains(q)
        }
    }

    func allHistoryLanguages() -> [String] {
        let langs = Set(history.flatMap { [$0.sourceLang, $0.targetLang] })
        return langs.sorted()
    }

    func flashcardDeck(query: String, dueOnly: Bool) -> [TranslationHistoryItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let now = Date()

        return history
            .filter { $0.isInFlashcardDeck }
            .filter { item in
                guard dueOnly else { return true }
                guard let nextReviewAt = item.nextReviewAt else { return true }
                return nextReviewAt <= now
            }
            .filter { item in
                guard !trimmedQuery.isEmpty else { return true }
                return item.sourceText.lowercased().contains(trimmedQuery)
                    || item.resultText.lowercased().contains(trimmedQuery)
                    || item.sourceLang.lowercased().contains(trimmedQuery)
                    || item.targetLang.lowercased().contains(trimmedQuery)
            }
            .sorted {
                let lhs = $0.nextReviewAt ?? .distantPast
                let rhs = $1.nextReviewAt ?? .distantPast
                if lhs != rhs { return lhs < rhs }
                return $0.createdAt > $1.createdAt
            }
    }

    func toggleFlashcardDeck(itemID: UUID) {
        guard let index = history.firstIndex(where: { $0.id == itemID }) else { return }
        history[index].isInFlashcardDeck.toggle()
        saveHistory()
    }

    func recordFlashcardReview(itemID: UUID, remembered: Bool) {
        guard let index = history.firstIndex(where: { $0.id == itemID }) else { return }

        history[index].reviewCount += 1
        if remembered {
            history[index].correctCount += 1
            history[index].memoryScore = min(history[index].memoryScore + 1, 5)
        } else {
            history[index].memoryScore = max(history[index].memoryScore - 1, 0)
        }

        let now = Date()
        history[index].lastReviewedAt = now
        history[index].nextReviewAt = now.addingTimeInterval(nextReviewInterval(for: history[index].memoryScore, remembered: remembered))
        saveHistory()
    }

    private func nextReviewInterval(for score: Int, remembered: Bool) -> TimeInterval {
        if !remembered {
            return 10 * 60
        }

        switch score {
        case 0: return 10 * 60
        case 1: return 60 * 60
        case 2: return 12 * 60 * 60
        case 3: return 24 * 60 * 60
        case 4: return 3 * 24 * 60 * 60
        default: return 7 * 24 * 60 * 60
        }
    }

    func addHistory(sourceText: String, resultText: String, sourceLang: String, targetLang: String) -> Bool {
        let source = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = resultText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty, !result.isEmpty else { return false }

        let fingerprint = "\(sourceLang)|\(targetLang)|\(source)|\(result)"
        if fingerprint == lastHistoryFingerprint { return false }
        lastHistoryFingerprint = fingerprint

        if let index = history.firstIndex(where: {
            $0.sourceText == source && $0.resultText == result && $0.sourceLang == sourceLang && $0.targetLang == targetLang
        }) {
            var existing = history.remove(at: index)
            existing.createdAt = Date()
            history.insert(existing, at: 0)
        } else {
            history.insert(
                TranslationHistoryItem(
                    sourceText: source,
                    resultText: result,
                    sourceLang: sourceLang,
                    targetLang: targetLang
                ),
                at: 0
            )
        }

        enforceHistoryLimit()
        saveHistory()
        return true
    }

    func toggleFavorite(itemID: UUID) {
        guard let index = history.firstIndex(where: { $0.id == itemID }) else { return }
        history[index].isFavorite.toggle()
        saveHistory()
    }

    func removeHistory(itemID: UUID) {
        history.removeAll(where: { $0.id == itemID })
        saveHistory()
    }

    func clearNonFavoriteHistory() {
        history.removeAll(where: { !$0.isFavorite })
        saveHistory()
    }

    private func enforceHistoryLimit() {
        let configuredLimit = UserDefaults.standard.integer(forKey: "historyLimit")
        let limit = max(50, min(configuredLimit == 0 ? DefaultSettings.historyLimit : configuredLimit, 200))
        if history.count > limit {
            history = Array(history.prefix(limit))
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyStorageKey) else { return }
        let decoder = JSONDecoder()
        if let items = try? decoder.decode([TranslationHistoryItem].self, from: data) {
            history = items
            enforceHistoryLimit()
        }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyStorageKey)
    }

    func captureAndStoreCurrentTranslation(completion: ((TranslationHistoryItem?) -> Void)? = nil) {
        guard let webView = webView else {
            completion?(nil)
            return
        }

        readSourceText(from: webView) { source in
            readTranslationResult(from: webView) { result in
                guard let source, let result else {
                    completion?(nil)
                    return
                }

                let sourceLang = self.lastSourceLang
                let targetLang = self.lastTargetLang
                let didStore = self.addHistory(sourceText: source, resultText: result, sourceLang: sourceLang, targetLang: targetLang)
                completion?(didStore ? self.history.first : nil)
            }
        }
    }
}

struct TranslationHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var sourceText: String
    var resultText: String
    var sourceLang: String
    var targetLang: String
    var createdAt: Date
    var isFavorite: Bool
    var isInFlashcardDeck: Bool
    var reviewCount: Int
    var correctCount: Int
    var memoryScore: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceText
        case resultText
        case sourceLang
        case targetLang
        case createdAt
        case isFavorite
        case isInFlashcardDeck
        case reviewCount
        case correctCount
        case memoryScore
        case lastReviewedAt
        case nextReviewAt
    }

    init(
        id: UUID = UUID(),
        sourceText: String,
        resultText: String,
        sourceLang: String,
        targetLang: String,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        isInFlashcardDeck: Bool = true,
        reviewCount: Int = 0,
        correctCount: Int = 0,
        memoryScore: Int = 0,
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil
    ) {
        self.id = id
        self.sourceText = sourceText
        self.resultText = resultText
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.isInFlashcardDeck = isInFlashcardDeck
        self.reviewCount = reviewCount
        self.correctCount = correctCount
        self.memoryScore = memoryScore
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sourceText = try container.decode(String.self, forKey: .sourceText)
        resultText = try container.decode(String.self, forKey: .resultText)
        sourceLang = try container.decode(String.self, forKey: .sourceLang)
        targetLang = try container.decode(String.self, forKey: .targetLang)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isInFlashcardDeck = try container.decodeIfPresent(Bool.self, forKey: .isInFlashcardDeck) ?? true
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        memoryScore = try container.decodeIfPresent(Int.self, forKey: .memoryScore) ?? 0
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        nextReviewAt = try container.decodeIfPresent(Date.self, forKey: .nextReviewAt)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var instance: AppDelegate!

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var hotkeyToggleApp: HotKey!
    var hotkeyTranslateNow: HotKey!
    var clipboardWatcherTimer: Timer?
    var lastPasteboardChangeCount: Int = NSPasteboard.general.changeCount
    var lastClipboardText: String = ""
    var previousActiveApp: NSRunningApplication?

    var BT: BarTranslate = BarTranslate()

    @AppStorage("translationProvider") private var translationProvider: TranslationProvider = DefaultSettings.translationProvider
    @AppStorage("showHideKey") private var showHideKey: String = DefaultSettings.ToggleApp.key.description
    @AppStorage("showHideModifier") private var showHideModifier: String = DefaultSettings.ToggleApp.modifier.description
    @AppStorage("translateNowKey") private var translateNowKey: String = DefaultSettings.TranslateNow.key.description
    @AppStorage("translateNowModifier") private var translateNowModifier: String = DefaultSettings.TranslateNow.modifier.description
    @AppStorage("menuBarIcon") private var menuBarIcon: MenuBarIcon = DefaultSettings.menuBarIcon
    @AppStorage("autoClipboardPaste") private var autoClipboardPaste: Bool = DefaultSettings.autoClipboardPaste
    @AppStorage("autoClipboardTranslate") private var autoClipboardTranslate: Bool = DefaultSettings.autoClipboardTranslate
    @AppStorage("inPlaceAction") private var inPlaceActionRaw: String = DefaultSettings.inPlaceAction.rawValue

    override init() {
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: "showHideKey", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "showHideModifier", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "translateNowKey", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "translateNowModifier", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "menuBarIcon", options: .new, context: nil)
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "showHideKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "showHideModifier")
        UserDefaults.standard.removeObserver(self, forKeyPath: "translateNowKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "translateNowModifier")
        UserDefaults.standard.removeObserver(self, forKeyPath: "menuBarIcon")
        clipboardWatcherTimer?.invalidate()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "showHideKey" || keyPath == "showHideModifier" {
            setupToggleAppHotkeys()
        } else if keyPath == "translateNowKey" || keyPath == "translateNowModifier" {
            setupTranslateNowHotkey()
        } else if keyPath == "menuBarIcon" {
            updateMenuBarIcon()
        }
    }

    func setupToggleAppHotkeys() {
        let key = Key(string: showHideKey) ?? DefaultSettings.ToggleApp.key
        let mod = Key(string: showHideModifier) ?? DefaultSettings.ToggleApp.modifier

        hotkeyToggleApp = HotKey(
            key: key,
            modifiers: keyToNSEventModifierFlags(key: mod),
            keyDownHandler: { self.togglePopover(nil) }
        )
    }

    func setupTranslateNowHotkey() {
        let key = Key(string: translateNowKey) ?? DefaultSettings.TranslateNow.key
        let mod = Key(string: translateNowModifier) ?? DefaultSettings.TranslateNow.modifier

        hotkeyTranslateNow = HotKey(
            key: key,
            modifiers: keyToNSEventModifierFlags(key: mod),
            keyDownHandler: { [weak self] in
                self?.translateNowFromHotkey()
            }
        )
    }

    func updateMenuBarIcon() {
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: menuBarIcon.id)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self

        if let window = NSApplication.shared.windows.first { window.close() }

        let contentView = ContentView(BT: BT)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.AppSize.width, height: Constants.AppSize.height)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        #if DEBUG
        popover.behavior = .applicationDefined
        #endif

        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: menuBarIcon.id)
            button.action = #selector(togglePopover(_:))
        }

        setupToggleAppHotkeys()
        setupTranslateNowHotkey()
        startClipboardWatcher()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = self.statusBarItem.button else { return }

        if self.popover.isShown {
            self.popover.performClose(sender)
        } else {
            previousActiveApp = NSWorkspace.shared.frontmostApplication
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)

            guard let webView = BT.webView, !webView.isHidden else { return }

            // Autofocus textarea
            injectFocusScript(webView: webView, provider: translationProvider)

            // Auto-paste clipboard if setting enabled and clipboard has text
            if autoClipboardPaste,
               let clipText = NSPasteboard.general.string(forType: .string),
               !clipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    injectClipboardText(webView: webView, text: clipText)
                }
            }
        }
    }

    private func translateNowFromHotkey() {
        showPopoverIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let webView = self.BT.webView else { return }
            triggerTranslateNow(webView: webView)
        }
    }

    private func showPopoverIfNeeded() {
        if !popover.isShown {
            togglePopover(nil)
        }
    }

    private func startClipboardWatcher() {
        clipboardWatcherTimer?.invalidate()
        lastPasteboardChangeCount = NSPasteboard.general.changeCount
        lastClipboardText = NSPasteboard.general.string(forType: .string) ?? ""

        clipboardWatcherTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { [weak self] _ in
            self?.handleClipboardChange()
        }
    }

    private func handleClipboardChange() {
        guard autoClipboardTranslate else { return }

        let pb = NSPasteboard.general
        guard pb.changeCount != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = pb.changeCount

        guard let text = pb.string(forType: .string) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed != lastClipboardText else { return }
        lastClipboardText = trimmed

        showPopoverIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let webView = self.BT.webView else { return }
            injectClipboardText(webView: webView, text: trimmed)
            triggerTranslateNow(webView: webView)
        }
    }

    func performInPlaceActionIfNeeded(with translatedText: String) {
        guard let action = InPlaceAction(rawValue: inPlaceActionRaw) else { return }
        switch action {
        case .none:
            return
        case .copy:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(translatedText, forType: .string)
        case .paste:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(translatedText, forType: .string)
            pasteBackToPreviousApp()
        }
    }

    private func pasteBackToPreviousApp() {
        guard let targetApp = previousActiveApp else { return }

        popover.performClose(nil)
        targetApp.activate(options: [.activateIgnoringOtherApps])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)

            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand

            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
