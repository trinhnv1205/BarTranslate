import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var BT: BarTranslate
    @State private var searchQuery: String = ""
    @State private var languageFilter: String = "all"
    @State private var favoritesOnly: Bool = false

    private var filteredItems: [TranslationHistoryItem] {
        let items = BT.filteredHistory(query: searchQuery, languageFilter: languageFilter)
        if favoritesOnly {
            return items.filter { $0.isFavorite }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search source, result, or language", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Picker("Language", selection: $languageFilter) {
                    Text("All").tag("all")
                    ForEach(BT.allHistoryLanguages(), id: \.self) { lang in
                        Text(lang.uppercased()).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 90)

                Button {
                    favoritesOnly.toggle()
                } label: {
                    Image(systemName: favoritesOnly ? "pin.fill" : "pin")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(favoritesOnly ? Color(NSColor.systemOrange) : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help(favoritesOnly ? "Show all" : "Show favorites only")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text("No translations yet")
                        .font(.system(size: 13, weight: .medium))
                    Text("Use Translate tab or clipboard auto translate to build history")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            HistoryRow(item: item, BT: BT)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }

            if !BT.history.isEmpty {
                HStack {
                    Button("Export CSV") {
                        BT.exportHistoryCSV()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))

                    Spacer()

                    if BT.history.contains(where: { !$0.isFavorite }) {
                        Button("Clear non-favorites") {
                            BT.clearNonFavoriteHistory()
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 11))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

private struct HistoryRow: View {
    let item: TranslationHistoryItem
    @ObservedObject var BT: BarTranslate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(item.sourceLang.uppercased()) -> \(item.targetLang.uppercased())")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Text(item.sourceText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text(item.resultText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(3)

            HStack(spacing: 10) {
                Button {
                    BT.toggleFavorite(itemID: item.id)
                } label: {
                    Label(item.isFavorite ? "Pinned" : "Pin", systemImage: item.isFavorite ? "pin.fill" : "pin")
                }

                Button {
                    BT.toggleFlashcardDeck(itemID: item.id)
                } label: {
                    Label(item.isInFlashcardDeck ? "In deck" : "Add deck", systemImage: item.isInFlashcardDeck ? "rectangle.stack.fill" : "rectangle.stack.badge.plus")
                }

                Button {
                    BT.speak(text: item.resultText, language: item.targetLang)
                } label: {
                    Label("Speak", systemImage: "speaker.wave.2")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.resultText, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {
                    BT.removeHistory(itemID: item.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Spacer()

                Button {
                    guard let webView = BT.webView else { return }
                    injectClipboardText(webView: webView, text: item.sourceText)
                    triggerTranslateNow(webView: webView)
                    withAnimation(.easeInOut(duration: 0.15)) {
                        BT.currentView = .translate
                    }
                } label: {
                    Label("Reuse", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 0.5)
                )
        )
    }
}

struct FlashcardView: View {
    @ObservedObject var BT: BarTranslate
    @State private var searchQuery: String = ""
    @State private var dueOnly: Bool = true
    @State private var showAnswer: Bool = false
    @State private var currentIndex: Int = 0

    private var deck: [TranslationHistoryItem] {
        BT.flashcardDeck(query: searchQuery, dueOnly: dueOnly)
    }

    private var currentCard: TranslationHistoryItem? {
        guard !deck.isEmpty else { return nil }
        let safeIndex = max(0, min(currentIndex, deck.count - 1))
        return deck[safeIndex]
    }

    private var dueCount: Int {
        BT.flashcardDeck(query: searchQuery, dueOnly: true).count
    }

    private var masteredCount: Int {
        BT.history.filter { $0.isInFlashcardDeck && $0.memoryScore >= 4 }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search flashcards", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Toggle("Due only", isOn: $dueOnly)
                    .toggleStyle(.switch)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            HStack(spacing: 8) {
                StatBadge(title: "Deck", value: "\(BT.history.filter { $0.isInFlashcardDeck }.count)")
                StatBadge(title: "Due", value: "\(dueCount)")
                StatBadge(title: "Mastered", value: "\(masteredCount)")
                Spacer()
            }
            .padding(.horizontal, 12)

            if let card = currentCard {
                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        Text(showAnswer ? "Back" : "Front")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("\(card.sourceLang.uppercased()) -> \(card.targetLang.uppercased())")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 6)

                    Text(showAnswer ? card.resultText : card.sourceText)
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 14)

                    Spacer(minLength: 6)

                    HStack(spacing: 6) {
                        Label("Score \(card.memoryScore)/5", systemImage: "brain")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Reviews \(card.reviewCount)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 12)

                HStack(spacing: 8) {
                    Button {
                        if deck.isEmpty { return }
                        currentIndex = (currentIndex - 1 + deck.count) % deck.count
                        showAnswer = false
                    } label: {
                        Label("Prev", systemImage: "arrow.left")
                    }

                    Button {
                        showAnswer.toggle()
                    } label: {
                        Label(showAnswer ? "Hide" : "Flip", systemImage: "arrow.2.squarepath")
                    }

                    Spacer()

                    Button {
                        BT.recordFlashcardReview(itemID: card.id, remembered: false)
                        showAnswer = false
                        moveToNextCard()
                    } label: {
                        Label("Again", systemImage: "arrow.uturn.backward")
                    }

                    Button {
                        BT.recordFlashcardReview(itemID: card.id, remembered: true)
                        showAnswer = false
                        moveToNextCard()
                    } label: {
                        Label("Remembered", systemImage: "checkmark.circle")
                    }
                }
                .buttonStyle(.link)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text("No flashcards available")
                        .font(.system(size: 13, weight: .medium))
                    Text("Add cards from History, or disable Due only to review everything")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: deck.map(\.id)) { _ in
            if currentIndex >= deck.count {
                currentIndex = max(0, deck.count - 1)
            }
            showAnswer = false
        }
    }

    private func moveToNextCard() {
        if deck.isEmpty {
            currentIndex = 0
            return
        }
        currentIndex = (currentIndex + 1) % deck.count
    }
}

private struct StatBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
