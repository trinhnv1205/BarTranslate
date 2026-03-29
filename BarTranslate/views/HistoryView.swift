import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var BT: BarTranslate
    @State private var searchQuery: String = ""
    @State private var languageFilter: String = "all"

    private var filteredItems: [TranslationHistoryItem] {
        BT.filteredHistory(query: searchQuery, languageFilter: languageFilter)
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

            if BT.history.contains(where: { !$0.isFavorite }) {
                HStack {
                    Spacer()
                    Button("Clear non-favorites") {
                        BT.clearNonFavoriteHistory()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
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
