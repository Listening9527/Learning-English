import SwiftUI
import Foundation
import UIKit

struct StudyPage: View {
    let scorer: PronunciationScorer
    private let startInWrongWordsMode: Bool
    private let showPracticeReportOnAppear: Bool

    init(
        scorer: PronunciationScorer,
        startInWrongWordsMode: Bool = false,
        showPracticeReportOnAppear: Bool = false
    ) {
        self.scorer = scorer
        self.startInWrongWordsMode = startInWrongWordsMode
        self.showPracticeReportOnAppear = showPracticeReportOnAppear
    }

    static func makeForTesting(scorer: PronunciationScorer) -> StudyPage {
        StudyPage(scorer: scorer)
    }

    var body: some View {
        LegacyStudyContent(
            scorer: scorer,
            startInWrongWordsMode: startInWrongWordsMode,
            showPracticeReportOnAppear: showPracticeReportOnAppear
        )
    }
}

struct LegacyStudyContent: View {
    private enum InputField: Hashable {
        case spellingAnswer
    }

    @ObservedObject var scorer: PronunciationScorer
    private let startInWrongWordsMode: Bool
    @StateObject private var wordbookStore = WordbookStore()
    @StateObject private var studySessionStore = StudySessionStore()
    @State private var useSlowMode: Bool = false
    @State private var selectedAccent: AccentOption = .american
    @State private var practiceWords: [String] = ["hello", "apple", "banana", "orange", "water"]
    @State private var currentWordIndex: Int = 0
    @State private var useWrongWordsOnly: Bool = false
    @State private var showPracticeReport: Bool = false
    @State private var showDictionaryLookup: Bool = false
    @State private var showCreateWordbookSheet: Bool = false
    @State private var dictionaryInitialTerm: String = ""
    @State private var selectedWordbookID: Int64?
    @State private var newWordbookName: String = ""
    @State private var newWordbookDescription: String = ""
    @State private var wordDetailsByWord: [String: RecentWordSummary] = [:]
    @State private var supplementalSummaries: [RecentWordSummary] = []
    @State private var definitionOptions: [String] = []
    @State private var selectedDefinition: String?
    @State private var definitionSelectionIsCorrect: Bool?
    @State private var spellingAnswer: String = ""
    @State private var spellingFeedback: String?
    @State private var hasUnlockedPronunciation: Bool = false
    @State private var hasUnlockedSpelling: Bool = false
    @State private var errorMessage: String?
    @State private var currentBatchStartOffset: Int = 0
    @State private var hasMarkedCurrentBatchCompleted: Bool = false
    @FocusState private var focusedInput: InputField?

    private let defaultStudyWordLimit = 10

    init(
        scorer: PronunciationScorer,
        startInWrongWordsMode: Bool = false,
        showPracticeReportOnAppear: Bool = false
    ) {
        self.scorer = scorer
        self.startInWrongWordsMode = startInWrongWordsMode
        _useWrongWordsOnly = State(initialValue: startInWrongWordsMode)
        _showPracticeReport = State(initialValue: showPracticeReportOnAppear)
    }

    private var displayedWords: [String] {
        if useWrongWordsOnly {
            let wrongWords = practiceWords.filter {
                if let latest = scorer.latestScores[$0] {
                    return latest < scorer.autoReplayThreshold
                }
                return false
            }
            return wrongWords.isEmpty ? practiceWords : wrongWords
        }
        return practiceWords
    }

    private var currentDisplayedWord: String {
        guard !displayedWords.isEmpty else { return "" }
        let safeIndex = min(currentWordIndex, displayedWords.count - 1)
        return displayedWords[safeIndex]
    }

    private var currentWordSummary: RecentWordSummary? {
        let normalized = normalizeWord(currentDisplayedWord)
        return wordDetailsByWord[normalized]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("单词本学习") {
                    Text("默认每次从所选单词本加载 10 个单词。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("词表与练习模式") {
                    Picker("选择单词本", selection: $selectedWordbookID) {
                        Text("请选择单词本").tag(Int64?.none)
                        ForEach(wordbookStore.wordbookOptions) { option in
                            Text(option.name).tag(Optional(option.id))
                        }
                    }

                    Button("新建单词本") {
                        showCreateWordbookSheet = true
                    }
                    .buttonStyle(.bordered)
                }

                Section("第 1 项：选择正确释义") {
                    if !currentDisplayedWord.isEmpty {
                        Text(currentDisplayedWord)
                            .font(.headline)
                    }

                    if definitionOptions.isEmpty {
                        Text("当前单词暂无足够释义数据，无法生成选项。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(definitionOptions, id: \.self) { option in
                            Button {
                                selectedDefinition = option
                                definitionSelectionIsCorrect = option == currentWordSummary?.definition
                                hasUnlockedPronunciation = definitionSelectionIsCorrect == true
                                if definitionSelectionIsCorrect != true {
                                    hasUnlockedSpelling = false
                                    spellingAnswer = ""
                                    spellingFeedback = nil
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: optionStateIcon(for: option))
                                        .foregroundStyle(optionStateColor(for: option))
                                    Text(option)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if let definitionSelectionIsCorrect {
                            Text(definitionSelectionIsCorrect ? "回答正确。" : "回答错误，请重试。")
                                .font(.footnote)
                                .foregroundStyle(definitionSelectionIsCorrect ? .green : .red)
                        }
                    }
                }

                Section("第 2 项：单词发音练习") {
                    if !hasUnlockedPronunciation {
                        Text("先完成第一项并答对后，再进行发音练习。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !currentDisplayedWord.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(currentDisplayedWord)
                                .font(.headline)
                            if let phonetic = currentWordSummary?.phonetic, !phonetic.isEmpty {
                                Text(phonetic)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let summary = currentWordSummary, !summary.definition.isEmpty {
                                Text(summary.definition)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Picker("发音口音", selection: $selectedAccent) {
                        ForEach(AccentOption.allCases) { accent in
                            Text(accent.title).tag(accent)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!hasUnlockedPronunciation)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            navigationButtons
                            Spacer(minLength: 0)
                            pageIndicator
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            navigationButtons
                            pageIndicator
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            primaryPlaybackButtons
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            primaryPlaybackButtons
                        }
                    }
                    .disabled(!hasUnlockedPronunciation)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            replayButtons
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            replayButtons
                        }
                    }
                    .disabled(!hasUnlockedPronunciation)

                    Toggle("慢速模式（更适合跟读）", isOn: $useSlowMode)
                    .disabled(!hasUnlockedPronunciation)
                    Toggle("低分自动触发教学连播", isOn: $scorer.autoReplayLowScore)
                    .disabled(!hasUnlockedPronunciation)

                    Button("教学连播（标准 + 慢速）") {
                        scorer.speakTeachingSequence(word: currentDisplayedWord, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasUnlockedPronunciation)

                    if let latest = scorer.latestScores[currentDisplayedWord] {
                        Text("当前单词最近一次得分：\(latest) / 100")
                            .foregroundStyle(.secondary)
                    }

                    if !scorer.recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("识别结果")
                                .font(.headline)
                            Text(scorer.recognizedText)
                                .font(.body)
                        }
                    }

                    if let score = scorer.score {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("发音得分")
                                .font(.headline)
                            Text("\(score) / 100")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreColor(score))
                            Text(scoreHint(score))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !scorer.statusMessage.isEmpty {
                        Text(scorer.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("第 3 项：拼写单词") {
                    if !hasUnlockedSpelling {
                        Text("先完成第二项并获得当前单词发音得分后，再进行拼写。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let summary = currentWordSummary, !summary.definition.isEmpty {
                        Text("根据释义拼写单词：\(summary.definition)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    TextField("输入单词拼写", text: $spellingAnswer)
                        .focused($focusedInput, equals: .spellingAnswer)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            checkSpellingAnswer()
                            dismissKeyboard()
                        }
                        .disabled(!hasUnlockedSpelling)

                    Button("检查拼写") {
                        checkSpellingAnswer()
                        dismissKeyboard()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasUnlockedSpelling)

                    if let spellingFeedback {
                        Text(spellingFeedback)
                            .font(.footnote)
                            .foregroundStyle(isSpellingAnswerCorrect ? .green : .red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("单词发音评分")
            .onAppear {
                scorer.setAccent(selectedAccent)
                scorer.loadPersistedScores()
                useWrongWordsOnly = startInWrongWordsMode
                clampCurrentIndex()
            }
            .task {
                await wordbookStore.reload()
                await loadSupplementalSummaries()
                if selectedWordbookID == nil {
                    selectedWordbookID = wordbookStore.wordbookOptions.first?.id
                }
                await loadWordsFromSelectedWordbook()
            }
            .onChange(of: selectedWordbookID) { _ in
                Task {
                    await loadWordsFromSelectedWordbook()
                }
            }
            .onChange(of: selectedAccent) { newAccent in
                scorer.setAccent(newAccent)
            }
            .onChange(of: currentDisplayedWord) { _ in
                resetExerciseStateForCurrentWord()

                Task {
                    await refreshWordSummaries(for: [currentDisplayedWord], replaceAll: false)
                    refreshDefinitionOptions()
                }
            }
            .onChange(of: scorer.latestScores[currentDisplayedWord]) { latest in
                hasUnlockedSpelling = hasUnlockedPronunciation && latest != nil
            }
            .sheet(isPresented: $showPracticeReport) {
                NavigationStack {
                    PracticeReportView(
                        latestScores: scorer.latestScores,
                        threshold: scorer.autoReplayThreshold,
                        averageScoreText: scorer.averageScoreText,
                        scoredWordCount: scorer.scoredWordCount,
                        lowScoreWordCount: scorer.lowScoreWordCount
                    )
                }
            }
            .sheet(isPresented: $showDictionaryLookup) {
                NavigationStack {
                    DictionaryLookupPage(initialTerm: dictionaryInitialTerm)
                }
            }
            .sheet(isPresented: $showCreateWordbookSheet) {
                createWordbookSheet
            }
            .alert("操作失败", isPresented: errorAlertBinding) {
                Button("知道了", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var createWordbookSheet: some View {
        NavigationStack {
            Form {
                Section("新建单词本") {
                    TextField("名称", text: $newWordbookName)
                    TextField("描述（可选）", text: $newWordbookDescription, axis: .vertical)
                }
            }
            .navigationTitle("创建单词本")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        showCreateWordbookSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await createWordbook()
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

    private var isSpellingAnswerCorrect: Bool {
        normalizeWord(spellingAnswer) == normalizeWord(currentDisplayedWord)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 85 { return .green }
        if score >= 60 { return .orange }
        return .red
    }

    private func scoreHint(_ score: Int) -> String {
        if score >= 85 { return "发音较准确，继续保持。" }
        if score >= 60 { return "基本正确，可再练习重音和清晰度。" }
        return "与目标发音差异较大，建议放慢语速并重听标准发音。"
    }

    private func optionStateIcon(for option: String) -> String {
        guard let selectedDefinition else { return "circle" }
        guard selectedDefinition == option else { return "circle" }
        return definitionSelectionIsCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func optionStateColor(for option: String) -> Color {
        guard let selectedDefinition else { return .secondary }
        guard selectedDefinition == option else { return .secondary }
        return definitionSelectionIsCorrect == true ? .green : .red
    }

    @ViewBuilder
    private var navigationButtons: some View {
        Button("上一个") {
            guard currentWordIndex > 0 else { return }
            currentWordIndex -= 1
            scorer.resetForNewWord()
        }
        .buttonStyle(.bordered)
        .disabled(currentWordIndex == 0)

        Button("下一个") {
            guard currentWordIndex < displayedWords.count - 1 else { return }
            currentWordIndex += 1
            scorer.resetForNewWord()
        }
        .buttonStyle(.bordered)
        .disabled(currentWordIndex >= displayedWords.count - 1)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        Text("第 \(min(currentWordIndex + 1, max(displayedWords.count, 1))) / \(displayedWords.count) 个")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var primaryPlaybackButtons: some View {
        Button(useSlowMode ? "播放慢速发音" : "播放标准发音") {
            scorer.speak(word: currentDisplayedWord, slowMode: useSlowMode, accent: selectedAccent)
        }
        .buttonStyle(.borderedProminent)

        Button(scorer.isRecording ? "停止并评分" : "开始录音评分") {
            if scorer.isRecording {
                scorer.stopRecordingAndScore()
            } else {
                scorer.startRecording(for: currentDisplayedWord)
            }
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var replayButtons: some View {
        Button("查词典释义") {
            presentDictionaryDefinition(for: currentDisplayedWord)
        }
        .buttonStyle(.bordered)
    }

    private func createWordbook() async {
        do {
            let option = try await wordbookStore.createWordbook(
                name: newWordbookName,
                description: newWordbookDescription
            )

            selectedWordbookID = option.id
            newWordbookName = ""
            newWordbookDescription = ""
            showCreateWordbookSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSupplementalSummaries() async {
        do {
            supplementalSummaries = try await wordbookStore.fetchRecentWordSummaries(limit: 20)
            refreshDefinitionOptions()
        } catch {
            supplementalSummaries = []
        }
    }

    private func loadWordsFromSelectedWordbook() async {
        guard let wordbookID = selectedWordbookID else {
            return
        }

        do {
            let nextOffset = studySessionStore.nextBatchOffset(for: wordbookID)
            var words = try await wordbookStore.fetchStudyWords(
                wordbookID: wordbookID,
                limit: defaultStudyWordLimit,
                offset: nextOffset
            )

            if words.isEmpty, nextOffset > 0 {
                studySessionStore.resetBatchProgress(for: wordbookID)
                words = try await wordbookStore.fetchStudyWords(
                    wordbookID: wordbookID,
                    limit: defaultStudyWordLimit,
                    offset: 0
                )
                currentBatchStartOffset = 0
            } else {
                currentBatchStartOffset = nextOffset
            }

            guard !words.isEmpty else {
                errorMessage = "该单词本暂无单词，请先在单词详情中加入生词本。"
                return
            }

            practiceWords = words
            currentWordIndex = 0
            hasMarkedCurrentBatchCompleted = false
            scorer.resetForNewWord()
            dismissKeyboard()
            await refreshWordSummaries(for: words, replaceAll: true)
            resetExerciseStateForCurrentWord()
            refreshDefinitionOptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshWordSummaries(for words: [String], replaceAll: Bool) async {
        let normalizedWords = words.map(normalizeWord).filter { !$0.isEmpty }
        guard !normalizedWords.isEmpty else {
            if replaceAll {
                wordDetailsByWord = [:]
            }
            return
        }

        do {
            let summaries = try await wordbookStore.fetchWordSummaries(words: normalizedWords)
            var merged = replaceAll ? [String: RecentWordSummary]() : wordDetailsByWord

            if replaceAll {
                for word in normalizedWords {
                    merged.removeValue(forKey: word)
                }
            }

            for summary in summaries {
                let key = normalizeWord(summary.word)
                if !key.isEmpty {
                    merged[key] = summary
                }
            }

            wordDetailsByWord = merged
            refreshDefinitionOptions()
        } catch {
            if replaceAll {
                wordDetailsByWord = [:]
                definitionOptions = []
            }
        }
    }

    private func refreshDefinitionOptions() {
        guard let summary = currentWordSummary, !summary.definition.isEmpty else {
            definitionOptions = []
            return
        }

        let distractors = Array(
            Set(
                (Array(wordDetailsByWord.values) + supplementalSummaries)
                    .filter { normalizeWord($0.word) != normalizeWord(summary.word) }
                    .map(\.definition)
                    .filter { !$0.isEmpty && $0 != summary.definition }
            )
        )

        var options = Array(distractors.shuffled().prefix(3))
        options.append(summary.definition)

        let fallbackOptions = [
            "一种动作或状态的描述",
            "表示时间或顺序变化的含义",
            "与场景或事物相关的解释"
        ]

        for fallback in fallbackOptions where options.count < 4 {
            if fallback != summary.definition && !options.contains(fallback) {
                options.append(fallback)
            }
        }

        definitionOptions = Array(options.prefix(4)).shuffled()
    }

    private func resetExerciseStateForCurrentWord() {
        selectedDefinition = nil
        definitionSelectionIsCorrect = nil
        spellingAnswer = ""
        spellingFeedback = nil
        hasUnlockedPronunciation = false
        hasUnlockedSpelling = false
    }

    private func checkSpellingAnswer() {
        if isSpellingAnswerCorrect {
            spellingFeedback = "拼写正确。"
            markCurrentBatchCompletedIfNeeded()
        } else {
            spellingFeedback = "拼写不正确，正确答案是 \(currentDisplayedWord)。"
        }
    }

    private func normalizeWord(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func clampCurrentIndex() {
        if displayedWords.isEmpty {
            currentWordIndex = 0
        } else {
            currentWordIndex = min(currentWordIndex, displayedWords.count - 1)
        }
    }

    private func markCurrentBatchCompletedIfNeeded() {
        guard !useWrongWordsOnly,
              !hasMarkedCurrentBatchCompleted,
              !practiceWords.isEmpty,
              currentWordIndex == practiceWords.count - 1,
              let wordbookID = selectedWordbookID else {
            return
        }

        studySessionStore.markBatchCompleted(
            wordbookID: wordbookID,
            batchStart: currentBatchStartOffset,
            batchSize: practiceWords.count
        )
        hasMarkedCurrentBatchCompleted = true
    }

    private func presentDictionaryDefinition(for word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let term = normalized.split(separator: " ").first.map(String.init) ?? ""
        dictionaryInitialTerm = term
        showDictionaryLookup = true
    }

    private func dismissKeyboard() {
        focusedInput = nil
    }
}

private struct DictionaryLookupPage: View {
    @State private var query: String
    @State private var dictionaryLookupItem: DictionaryLookupItem?
    @State private var infoMessage: String = ""

    init(initialTerm: String) {
        _query = State(initialValue: initialTerm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("输入英文单词", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit {
                    runLookup()
                }

            HStack(spacing: 10) {
                Button("查询") {
                    runLookup()
                }
                .buttonStyle(.borderedProminent)

                if dictionaryLookupItem != nil {
                    Button("清空结果") {
                        self.dictionaryLookupItem = nil
                        infoMessage = ""
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if #available(iOS 17.0, *) {
                ContentUnavailableView("查询系统词典", systemImage: "book.closed", description: Text("输入英文单词后点击“查询”"))
            } else {
                Text("输入英文单词后点击“查询”")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("查词典释义")
        .onAppear {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                runLookup()
            }
        }
        .sheet(item: $dictionaryLookupItem) { item in
            DictionaryDefinitionView(term: item.term)
        }
    }

    private func runLookup() {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            infoMessage = "请输入要查询的英文单词。"
            dictionaryLookupItem = nil
            return
        }

        let term = normalized.split(separator: " ").first.map(String.init) ?? normalized
        query = term

        guard UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) else {
            infoMessage = "系统词典中暂未找到“\(term)”的释义。"
            dictionaryLookupItem = nil
            return
        }

        infoMessage = ""
        dictionaryLookupItem = DictionaryLookupItem(term: term)
    }
}

private struct DictionaryLookupItem: Identifiable {
    let id = UUID()
    let term: String
}

private struct DictionaryDefinitionView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {
    }
}

struct PracticeStatsSettingsView: View {
    @ObservedObject var scorer: PronunciationScorer

    var body: some View {
        Form {
            Section("练习统计") {
                Text("已评分单词：\(scorer.scoredWordCount)")
                Text("平均分：\(scorer.averageScoreText)")
                Text("错题数（低于 \(scorer.autoReplayThreshold) 分）：\(scorer.lowScoreWordCount)")
            }

            Section("达标线设置") {
                Stepper(value: $scorer.autoReplayThreshold, in: 40...95, step: 5) {
                    Text("低于 \(scorer.autoReplayThreshold) 分判定为错题")
                        .font(.footnote)
                }
                Text("会同时影响错题本筛选和低分自动教学连播。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("练习统计与设置")
    }
}
