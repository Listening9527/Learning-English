//
//  ContentView.swift
//  Learning
//
//  Created by CNCEMNV02 on 2026/7/20.
//

import SwiftUI
import AVFoundation
import Speech
import Combine

struct ContentView: View {
    @StateObject private var scorer = PronunciationScorer()
    @State private var useSlowMode: Bool = false
    @State private var selectedAccent: AccentOption = .american
    @State private var practiceWords: [String] = ["hello", "apple", "banana", "orange", "water"]
    @State private var currentWordIndex: Int = 0

    private var targetWord: Binding<String> {
        Binding(
            get: { practiceWords[currentWordIndex] },
            set: { practiceWords[currentWordIndex] = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("单词发音评分")
                    .font(.title2.bold())

                TextField("输入要练习的英文单词", text: targetWord)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Picker("发音口音", selection: $selectedAccent) {
                    ForEach(AccentOption.allCases) { accent in
                        Text(accent.title).tag(accent)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    Button("上一个") {
                        guard currentWordIndex > 0 else { return }
                        currentWordIndex -= 1
                        scorer.resetForNewWord()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentWordIndex == 0)

                    Text("第 \(currentWordIndex + 1) / \(practiceWords.count) 个")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("下一个") {
                        guard currentWordIndex < practiceWords.count - 1 else { return }
                        currentWordIndex += 1
                        scorer.resetForNewWord()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentWordIndex == practiceWords.count - 1)
                }

                HStack(spacing: 12) {
                    Button(useSlowMode ? "播放慢速发音" : "播放标准发音") {
                        scorer.speak(word: practiceWords[currentWordIndex], slowMode: useSlowMode, accent: selectedAccent)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(scorer.isRecording ? "停止并评分" : "开始录音评分") {
                        if scorer.isRecording {
                            scorer.stopRecordingAndScore()
                        } else {
                            scorer.startRecording(for: practiceWords[currentWordIndex])
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Toggle("慢速模式（更适合跟读）", isOn: $useSlowMode)

                Toggle("低分自动触发教学连播", isOn: $scorer.autoReplayLowScore)

                Button("教学连播（标准 + 慢速）") {
                    scorer.speakTeachingSequence(word: practiceWords[currentWordIndex], accent: selectedAccent)
                }
                .buttonStyle(.bordered)

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

                Spacer()
            }
            .padding()
            .navigationTitle("Learning")
            .onAppear {
                scorer.setAccent(selectedAccent)
            }
            .onChange(of: selectedAccent) { newAccent in
                scorer.setAccent(newAccent)
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
}

enum AccentOption: String, CaseIterable, Identifiable {
    case american = "en-US"
    case british = "en-GB"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .american: return "美音"
        case .british: return "英音"
        }
    }
}

final class PronunciationScorer: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var score: Int?
    @Published var statusMessage: String = ""
    @Published var isRecording: Bool = false
    @Published var autoReplayLowScore: Bool = true

    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentTargetWord: String = ""
    private var currentAccent: AccentOption = .american
    private let autoReplayThreshold = 60

    private enum SpeakingStyle {
        case normal
        case slow
    }

    func speak(word: String, slowMode: Bool, accent: AccentOption) {
        let cleaned = normalizeWord(word)
        guard !cleaned.isEmpty else {
            statusMessage = "请先输入英文单词。"
            return
        }

        currentAccent = accent

        let utterance = buildUtterance(for: cleaned, style: slowMode ? .slow : .normal, accent: accent)
        synthesizer.speak(utterance)
        statusMessage = slowMode ? "正在播放\(accent.title)慢速发音：\(cleaned)" : "正在播放\(accent.title)标准发音：\(cleaned)"
    }

    func speakTeachingSequence(word: String, accent: AccentOption) {
        let cleaned = normalizeWord(word)
        guard !cleaned.isEmpty else {
            statusMessage = "请先输入英文单词。"
            return
        }

        currentAccent = accent

        let normal = buildUtterance(for: cleaned, style: .normal, accent: accent)
        let slow = buildUtterance(for: cleaned, style: .slow, accent: accent)
        synthesizer.speak(normal)
        synthesizer.speak(slow)
        statusMessage = "正在教学连播：\(accent.title)标准 + 慢速（\(cleaned)）"
    }

    func startRecording(for targetWord: String) {
        let cleaned = normalizeWord(targetWord)
        guard !cleaned.isEmpty else {
            statusMessage = "请先输入英文单词。"
            return
        }
        currentTargetWord = cleaned
        score = nil
        recognizedText = ""

        requestPermissionsIfNeeded { [weak self] granted in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard granted else {
                    self.statusMessage = "未获得麦克风或语音识别权限。"
                    return
                }
                self.beginRecognition()
            }
        }
    }

    func stopRecordingAndScore() {
        stopRecognitionPipeline()
        evaluateScore()
    }

    func resetForNewWord() {
        stopRecognitionPipeline()
        recognizedText = ""
        score = nil
        statusMessage = "已切换单词，请先听标准发音再录音。"
    }

    func setAccent(_ accent: AccentOption) {
        currentAccent = accent
    }

    private func beginRecognition() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: currentAccent.rawValue)), recognizer.isAvailable else {
            statusMessage = "当前\(currentAccent.title)识别不可用。"
            return
        }

        stopRecognitionPipeline()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                statusMessage = "创建识别请求失败。"
                return
            }
            recognitionRequest.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true
            statusMessage = "正在录音，请朗读：\(currentTargetWord)"

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    DispatchQueue.main.async {
                        self.recognizedText = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.stopRecognitionPipeline()
                            self.evaluateScore()
                        }
                    }
                }

                if error != nil {
                    DispatchQueue.main.async {
                        self.stopRecognitionPipeline()
                        self.evaluateScore()
                    }
                }
            }
        } catch {
            statusMessage = "启动录音失败：\(error.localizedDescription)"
            stopRecognitionPipeline()
        }
    }

    private func stopRecognitionPipeline() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func evaluateScore() {
        let expected = normalizeWord(currentTargetWord)
        let actual = normalizeWord(recognizedText)

        guard !expected.isEmpty else {
            score = nil
            statusMessage = "目标单词为空。"
            return
        }

        guard !actual.isEmpty else {
            score = 0
            statusMessage = "未识别到有效发音，请重试。"
            return
        }

        let bestToken = actual.split(separator: " ").max(by: { tokenSimilarity(String($0), expected) < tokenSimilarity(String($1), expected) }).map(String.init) ?? actual
        let bestSimilarity = tokenSimilarity(bestToken, expected)
        let finalScore = Int((bestSimilarity * 100.0).rounded())

        score = max(0, min(100, finalScore))
        statusMessage = "目标：\(expected)；识别：\(bestToken)"

        if let score, autoReplayLowScore, score < autoReplayThreshold {
            speakTeachingSequence(word: expected, accent: currentAccent)
        }
    }

    private func tokenSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let distance = levenshteinDistance(lhs, rhs)
        let maxLen = max(lhs.count, rhs.count)
        guard maxLen > 0 else { return 1.0 }
        return 1.0 - Double(distance) / Double(maxLen)
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var previous = Array(0...bChars.count)
        var current = Array(repeating: 0, count: bChars.count + 1)

        for i in 1...aChars.count {
            current[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            swap(&previous, &current)
        }
        return previous[bChars.count]
    }

    private func normalizeWord(_ input: String) -> String {
        let lowered = input.lowercased()
        let filtered = lowered.map { ch -> Character in
            if ch.isLetter || ch.isWhitespace { return ch }
            return " "
        }
        return String(filtered).split(separator: " ").joined(separator: " ")
    }

    private func requestPermissionsIfNeeded(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechAuth in
            let speechGranted = speechAuth == .authorized
            AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                completion(speechGranted && micGranted)
            }
        }
    }

    private func buildUtterance(for word: String, style: SpeakingStyle, accent: AccentOption) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: accent.rawValue)
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0

        switch style {
        case .normal:
            utterance.rate = 0.44
            utterance.preUtteranceDelay = 0.08
            utterance.postUtteranceDelay = 0.22
        case .slow:
            utterance.rate = 0.34
            utterance.preUtteranceDelay = 0.10
            utterance.postUtteranceDelay = 0.30
        }

        return utterance
    }
}

#Preview {
    ContentView()
}
