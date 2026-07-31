import SwiftUI

struct SearchPage: View {
    @ObservedObject var dashboardStore: DashboardStore

    @State private var query = ""
    @State private var results: [RecentWordSummary] = []
    @State private var history: [String] = []
    @State private var isShowingCreateSheet = false
    @State private var createWord = ""
    @State private var createPhonetic = ""
    @State private var createSyllableDivision = ""
    @State private var createFrequency = ""
    @State private var createWordRoot = ""
    @State private var createPartOfSpeech = ""
    @State private var createDefinition = ""
    @State private var createTranslation = ""
    @State private var createExample1 = ""
    @State private var createExample1Translation = ""
    @State private var createExample2 = ""
    @State private var createExample2Translation = ""
    @State private var createExample3 = ""
    @State private var createExample3Translation = ""
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
                                dashboardStore: dashboardStore
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

                                HStack(spacing: 8) {
                                    if let part = word.partOfSpeech, !part.isEmpty {
                                        Text(part)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let frequency = word.frequency {
                                        Text(String(format: "频率 %.3f", frequency))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text(word.definition)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                if let translation = word.translation, !translation.isEmpty {
                                    Text(translation)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
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
                    TextField("音节划分", text: $createSyllableDivision)
                    TextField("出现频率（数字）", text: $createFrequency)
                        .keyboardType(.decimalPad)
                    TextField("词根", text: $createWordRoot)
                    TextField("词性", text: $createPartOfSpeech)
                    TextField("英文释义", text: $createDefinition, axis: .vertical)
                    TextField("中文翻译", text: $createTranslation, axis: .vertical)
                }

                Section("例句 1") {
                    TextField("英文例句 1", text: $createExample1, axis: .vertical)
                    TextField("例句翻译 1", text: $createExample1Translation, axis: .vertical)
                }

                Section("例句 2") {
                    TextField("英文例句 2", text: $createExample2, axis: .vertical)
                    TextField("例句翻译 2", text: $createExample2Translation, axis: .vertical)
                }

                Section("例句 3") {
                    TextField("英文例句 3", text: $createExample3, axis: .vertical)
                    TextField("例句翻译 3", text: $createExample3Translation, axis: .vertical)
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
            let frequencyValue = Double(createFrequency.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            _ = try DatabaseManager.shared.createCustomWord(
                word: createWord,
                phonetic: createPhonetic,
                syllableDivision: createSyllableDivision,
                frequency: frequencyValue,
                wordRoot: createWordRoot,
                partOfSpeech: createPartOfSpeech,
                definition: createDefinition,
                translation: createTranslation,
                example1: createExample1,
                example1Translation: createExample1Translation,
                example2: createExample2,
                example2Translation: createExample2Translation,
                example3: createExample3,
                example3Translation: createExample3Translation
            )

            createWord = ""
            createPhonetic = ""
            createSyllableDivision = ""
            createFrequency = ""
            createWordRoot = ""
            createPartOfSpeech = ""
            createDefinition = ""
            createTranslation = ""
            createExample1 = ""
            createExample1Translation = ""
            createExample2 = ""
            createExample2Translation = ""
            createExample3 = ""
            createExample3Translation = ""
            isShowingCreateSheet = false

            await dashboardStore.refresh()
            await refreshSearchHistory()
            await runSearch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
