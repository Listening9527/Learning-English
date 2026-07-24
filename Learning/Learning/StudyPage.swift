import SwiftUI
import Foundation
import UIKit

struct StudyPage: View {
    let scorer: PronunciationScorer

    static func makeForTesting(scorer: PronunciationScorer) -> StudyPage {
        StudyPage(scorer: scorer)
    }

    var body: some View {
        LegacyStudyContent(scorer: scorer)
    }
}

struct LegacyStudyContent: View {
    private enum InputField: Hashable {
        case customWords
        case targetWord
    }

    @ObservedObject var scorer: PronunciationScorer
    @State private var useSlowMode: Bool = false
    @State private var selectedAccent: AccentOption = .american
    @State private var practiceWords: [String] = ["hello", "apple", "banana", "orange", "water"]
    @State private var currentWordIndex: Int = 0
    @State private var customWordsText: String = "hello, apple, banana, orange, water"
    @State private var useWrongWordsOnly: Bool = false
    @State private var showPracticeReport: Bool = false
    @State private var dictionaryLookupItem: DictionaryLookupItem?
    @FocusState private var focusedInput: InputField?

    private var currentPracticeWordIndex: Int {
        if let index = practiceWords.firstIndex(of: currentDisplayedWord) {
            return index
        }
        return min(currentWordIndex, max(practiceWords.count - 1, 0))
    }

    private var targetWord: Binding<String> {
        Binding(
            get: { practiceWords[currentPracticeWordIndex] },
            set: { practiceWords[currentPracticeWordIndex] = $0 }
        )
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

    var body: some View {
        NavigationStack {
            Form {
                Section("单词发音评分") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义词表（逗号或换行分隔）")
                            .font(.headline)
                        TextEditor(text: $customWordsText)
                            .focused($focusedInput, equals: .customWords)
                            .frame(minHeight: 90)
                            .padding(8)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                actionButtons
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                actionButtons
                            }
                        }

                        Text(useWrongWordsOnly ? "当前为错题本模式" : "当前为完整词表模式")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("更多") {
                    NavigationLink("练习统计与达标线设置") {
                        PracticeStatsSettingsView(scorer: scorer)
                    }
                }

                Section("练习控制") {
                    TextField("输入要练习的英文单词", text: targetWord)
                        .focused($focusedInput, equals: .targetWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            dismissKeyboard()
                        }

                    Picker("发音口音", selection: $selectedAccent) {
                        ForEach(AccentOption.allCases) { accent in
                            Text(accent.title).tag(accent)
                        }
                    }
                    .pickerStyle(.segmented)

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

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            replayButtons
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            replayButtons
                        }
                    }

                    Toggle("慢速模式（更适合跟读）", isOn: $useSlowMode)
                    Toggle("低分自动触发教学连播", isOn: $scorer.autoReplayLowScore)

                    Button("教学连播（标准 + 慢速）") {
                        scorer.speakTeachingSequence(word: currentDisplayedWord, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)
                }

                Section("结果") {
                    if let latest = scorer.latestScores[currentDisplayedWord] {
                        Text("当前单词最近一次得分：\(latest) / 100")
                            .foregroundStyle(.secondary)
                    }

                    if !scorer.latestScores.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("最近得分")
                                .font(.headline)
                            ForEach(displayedWords, id: \.self) { word in
                                HStack {
                                    Text(word)
                                    Spacer()
                                    if let latest = scorer.latestScores[word] {
                                        Text("\(latest)")
                                            .foregroundStyle(latest >= 85 ? .green : (latest >= scorer.autoReplayThreshold ? .orange : .red))
                                    } else {
                                        Text("-")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.footnote)
                            }
                        }
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
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起键盘") {
                        dismissKeyboard()
                    }
                }
            }
            .navigationTitle("单词发音评分")
            .onAppear {
                scorer.setAccent(selectedAccent)
                scorer.loadPersistedScores()
                applyCustomWords()
            }
            .onChange(of: selectedAccent) { newAccent in
                scorer.setAccent(newAccent)
            }
            .sheet(isPresented: $showPracticeReport) {
                PracticeReportView(
                    latestScores: scorer.latestScores,
                    threshold: scorer.autoReplayThreshold,
                    averageScoreText: scorer.averageScoreText,
                    scoredWordCount: scorer.scoredWordCount,
                    lowScoreWordCount: scorer.lowScoreWordCount
                )
            }
            .sheet(item: $dictionaryLookupItem) { item in
                DictionaryDefinitionView(term: item.term)
            }
        }
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

    @ViewBuilder
    private var actionButtons: some View {
        Button("应用词表") {
            applyCustomWords()
        }
        .buttonStyle(.borderedProminent)

        Button("错题本练习") {
            useWrongWordsOnly.toggle()
            clampCurrentIndex()
            scorer.resetForNewWord()
        }
        .buttonStyle(.bordered)

        Button("重置错题记录") {
            scorer.resetLatestScores(for: practiceWords)
            useWrongWordsOnly = false
            clampCurrentIndex()
        }
        .buttonStyle(.bordered)

        Button("今日练习报告") {
            showPracticeReport = true
        }
        .buttonStyle(.bordered)
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
        Button("重听当前单词") {
            scorer.speakTeachingSequence(word: currentDisplayedWord, accent: selectedAccent)
        }
        .buttonStyle(.bordered)

        Button("查词典释义") {
            presentDictionaryDefinition(for: currentDisplayedWord)
        }
        .buttonStyle(.bordered)

        Button("重新录音") {
            scorer.resetRecognitionOnly()
            scorer.startRecording(for: currentDisplayedWord)
        }
        .buttonStyle(.bordered)
    }

    private func applyCustomWords() {
        let parsedWords = customWordsText
            .lowercased()
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let uniqueWords = Array(NSOrderedSet(array: parsedWords)) as? [String] ?? parsedWords
        if uniqueWords.isEmpty {
            practiceWords = ["hello"]
            customWordsText = "hello"
        } else {
            practiceWords = uniqueWords
        }

        clampCurrentIndex()
        scorer.resetForNewWord()
    }

    private func clampCurrentIndex() {
        if displayedWords.isEmpty {
            currentWordIndex = 0
        } else {
            currentWordIndex = min(currentWordIndex, displayedWords.count - 1)
        }
    }

    private func presentDictionaryDefinition(for word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            scorer.statusMessage = "当前单词为空，无法查询词典释义。"
            return
        }

        let term = normalized.split(separator: " ").first.map(String.init) ?? normalized

        guard UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) else {
            scorer.statusMessage = "系统词典中暂未找到“\(term)”的释义。"
            return
        }

        dictionaryLookupItem = DictionaryLookupItem(term: term)
    }

    private func dismissKeyboard() {
        focusedInput = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

private struct PracticeStatsSettingsView: View {
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