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
                TextField("Search source, result, or language".loc, text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Picker("Language", selection: $languageFilter) {
                    Text("All".loc).tag("all")
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
                .help(favoritesOnly ? "Show all".loc : "Show favorites only".loc)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: BT.history.isEmpty ? "tray" : "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text(BT.history.isEmpty ? "No translations yet".loc : "No matches".loc)
                        .font(.system(size: 13, weight: .medium))
                    Text(BT.history.isEmpty
                         ? "Use Translate tab or clipboard auto translate to build history".loc
                         : "Try a different search or filter".loc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
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

            HStack(spacing: 12) {
                if !BT.history.isEmpty {
                    Button("Export CSV".loc) { BT.exportHistoryCSV() }
                        .buttonStyle(.link)
                        .font(.system(size: 11))
                    Button("Backup".loc) { BT.exportHistoryJSON() }
                        .buttonStyle(.link)
                        .font(.system(size: 11))
                        .help("Save a full backup (favorites and flashcard progress included)")
                }

                Button("Restore".loc) { BT.importHistoryJSON() }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                    .help("Restore history from a backup file")

                Spacer()

                if BT.history.contains(where: { !$0.isFavorite }) {
                    Button("Clear non-favorites".loc) {
                        BT.clearNonFavoriteHistory()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
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

            HStack(spacing: 6) {
                Button {
                    BT.toggleFavorite(itemID: item.id)
                } label: {
                    Image(systemName: item.isFavorite ? "pin.fill" : "pin")
                }
                .help(item.isFavorite ? "Unpin".loc : "Pin".loc)
                .accessibilityLabel(item.isFavorite ? "Unpin".loc : "Pin".loc)

                Button {
                    BT.toggleFlashcardDeck(itemID: item.id)
                } label: {
                    Image(systemName: item.isInFlashcardDeck ? "rectangle.stack.fill" : "rectangle.stack.badge.plus")
                }
                .help(item.isInFlashcardDeck ? "Remove from flashcard deck".loc : "Add to flashcard deck".loc)
                .accessibilityLabel(item.isInFlashcardDeck ? "Remove from flashcard deck".loc : "Add to flashcard deck".loc)

                Button {
                    BT.speak(text: item.resultText, language: item.targetLang)
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .help("Speak".loc)
                .accessibilityLabel("Speak translation".loc)

                Button {
                    AppDelegate.instance?.setClipboard(item.resultText)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy".loc)
                .accessibilityLabel("Copy translation".loc)

                Button {
                    BT.removeHistory(itemID: item.id)
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete".loc)
                .accessibilityLabel("Delete entry".loc)

                Spacer()

                Button {
                    BT.reuseHistoryItem(item)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reuse with original languages".loc)
                .accessibilityLabel("Reuse with original languages".loc)
            }
            .buttonStyle(.link)
            .font(.system(size: 12))
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
                TextField("Search flashcards".loc, text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Toggle("Due only".loc, isOn: $dueOnly)
                    .toggleStyle(.switch)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            HStack(spacing: 8) {
                StatBadge(title: "Deck".loc, value: "\(BT.history.filter { $0.isInFlashcardDeck }.count)")
                StatBadge(title: "Due".loc, value: "\(dueCount)")
                StatBadge(title: "Mastered".loc, value: "\(masteredCount)")
                Spacer()
            }
            .padding(.horizontal, 12)

            if let card = currentCard {
                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        Text(showAnswer ? "Back".loc : "Front".loc)
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
                        Label("Prev".loc, systemImage: "arrow.left")
                    }

                    Button {
                        showAnswer.toggle()
                    } label: {
                        Label(showAnswer ? "Hide".loc : "Flip".loc, systemImage: "arrow.2.squarepath")
                    }

                    Spacer()

                    Button {
                        BT.recordFlashcardReview(itemID: card.id, remembered: false)
                        advanceAfterReview()
                    } label: {
                        Label("Again".loc, systemImage: "arrow.uturn.backward")
                    }

                    Button {
                        BT.recordFlashcardReview(itemID: card.id, remembered: true)
                        advanceAfterReview()
                    } label: {
                        Label("Remembered".loc, systemImage: "checkmark.circle")
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
                    Text("No flashcards available".loc)
                        .font(.system(size: 13, weight: .medium))
                    Text("Add cards from History, or disable Due only to review everything".loc)
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

    /// Advance after grading a card. In "Due only" mode the graded card has
    /// just left the deck, so the same index already points to the next card —
    /// incrementing would skip one. Otherwise move forward normally.
    private func advanceAfterReview() {
        showAnswer = false
        if dueOnly {
            if currentIndex >= deck.count {
                currentIndex = max(0, deck.count - 1)
            }
        } else {
            moveToNextCard()
        }
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
