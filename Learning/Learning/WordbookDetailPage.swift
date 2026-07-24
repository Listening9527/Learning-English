import SwiftUI

struct WordbookDetailPage: View {
    let wordbook: WordbookSummary

    @State private var selectedFilter: WordbookFilter = .today
    @State private var words: [RecentWordSummary] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Picker("筛选", selection: $selectedFilter) {
                    ForEach(WordbookFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("单词") {
                if words.isEmpty {
                    Text("当前筛选下暂无单词")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(words) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.word)
                                .font(.headline)
                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle(wordbook.name)
        .task(id: selectedFilter) {
            await loadWords()
        }
        .alert("加载失败", isPresented: errorAlertBinding) {
            Button("知道了", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { show in
                if !show {
                    errorMessage = nil
                }
            }
        )
    }

    private func loadWords() async {
        do {
            words = try DatabaseManager.shared.fetchWordbookWords(wordbookID: wordbook.id, filter: selectedFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
