import SwiftUI

struct SearchPage: View {
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var wordbookStore: WordbookStore

    @State private var query = ""
    @State private var results: [RecentWordSummary] = []
    @State private var history: [String] = []
    @State private var isShowingCreateSheet = false
    @State private var createWord = ""
    @State private var createPhonetic = ""
    @State private var createPartOfSpeech = ""
    @State private var createDefinition = ""
    @State private var createExample = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            if !history.isEmpty && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("最近搜索") {
                    ForEach(history, id: \.self) { item in
                        Button(item) {
                            query = item
                            Task {
                                await runSearch()
                            }
                        }
                    }
                }
            }

            Section("结果") {
                if results.isEmpty {
                    Text("暂无结果")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(results) { word in
                        NavigationLink {
                            WordDetailPage(
                                word: word,
                                dashboardStore: dashboardStore,
                                wordbookStore: wordbookStore
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(word.word)
                                        .font(.headline)
                                    if let phonetic = word.phonetic, !phonetic.isEmpty {
                                        Text(phonetic)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text(word.definition)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("搜索")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索单词或释义")
        .onSubmit(of: .search) {
            Task {
                await runSearch()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("新建") {
                    isShowingCreateSheet = true
                }
            }
        }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createSheet
        }
        .alert("操作失败", isPresented: errorAlertBinding) {
            Button("知道了", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section("新词") {
                    TextField("单词", text: $createWord)
                    TextField("音标", text: $createPhonetic)
                    TextField("词性", text: $createPartOfSpeech)
                    TextField("释义", text: $createDefinition, axis: .vertical)
                    TextField("例句", text: $createExample, axis: .vertical)
                }
            }
            .navigationTitle("添加自定义词")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isShowingCreateSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await createCustomWord()
                        }
                    }
                }
            }
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

    private func loadInitialData() async {
        await refreshSearchHistory()
        await wordbookStore.reload()
    }

    private func refreshSearchHistory() async {
        do {
            history = try DatabaseManager.shared.fetchSearchHistory(limit: 10)
        } catch {
            history = []
        }
    }

    private func runSearch() async {
        do {
            results = try DatabaseManager.shared.searchWords(query: query)
            await refreshSearchHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createCustomWord() async {
        do {
            _ = try DatabaseManager.shared.createCustomWord(
                word: createWord,
                phonetic: createPhonetic,
                partOfSpeech: createPartOfSpeech,
                definition: createDefinition,
                example: createExample
            )

            createWord = ""
            createPhonetic = ""
            createPartOfSpeech = ""
            createDefinition = ""
            createExample = ""
            isShowingCreateSheet = false

            await dashboardStore.refresh()
            await refreshSearchHistory()
            await runSearch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
