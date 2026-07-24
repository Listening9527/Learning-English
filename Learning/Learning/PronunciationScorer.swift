import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class PronunciationScorer: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var score: Int?
    @Published var statusMessage: String = ""
    @Published var isRecording: Bool = false
    @Published var autoReplayLowScore: Bool = true
    @Published var latestScores: [String: Int] = [:]
    @Published var autoReplayThreshold: Int = 60 {
        didSet {
            persistThreshold()
        }
    }

    private lazy var synthesizer = AVSpeechSynthesizer()
    private lazy var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentTargetWord: String = ""
    private var currentAccent: AccentOption = .american
    private let latestScoresStorageKey = "learning.latestScores"
    private let thresholdStorageKey = "learning.autoReplayThreshold"

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
        guard prepareForSpeechPlayback() else { return }
        let hasExactAccentVoice = hasInstalledVoice(for: accent)

        let utterance = buildUtterance(for: cleaned, style: slowMode ? .slow : .normal, accent: accent)
        synthesizer.speak(utterance)
        let modeText = slowMode ? "慢速发音" : "标准发音"
        if hasExactAccentVoice {
            statusMessage = "正在播放\(accent.title)\(modeText)：\(cleaned)"
        } else {
            statusMessage = "未安装\(accent.title)语音资源，已回退到可用英语语音：\(cleaned)"
        }
    }

    func speakTeachingSequence(word: String, accent: AccentOption) {
        let cleaned = normalizeWord(word)
        guard !cleaned.isEmpty else {
            statusMessage = "请先输入英文单词。"
            return
        }

        currentAccent = accent
        guard prepareForSpeechPlayback() else { return }
        let hasExactAccentVoice = hasInstalledVoice(for: accent)

        let normal = buildUtterance(for: cleaned, style: .normal, accent: accent)
        let slow = buildUtterance(for: cleaned, style: .slow, accent: accent)
        synthesizer.speak(normal)
        synthesizer.speak(slow)
        if hasExactAccentVoice {
            statusMessage = "正在教学连播：\(accent.title)标准 + 慢速（\(cleaned)）"
        } else {
            statusMessage = "未安装\(accent.title)语音资源，教学连播已回退到可用英语语音（\(cleaned)）"
        }
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

    func resetRecognitionOnly() {
        stopRecognitionPipeline()
        recognizedText = ""
        score = nil
        statusMessage = "已清空本次识别结果，请重新录音。"
    }

    func setAccent(_ accent: AccentOption) {
        currentAccent = accent
    }

    func loadPersistedScores() {
        guard let data = UserDefaults.standard.data(forKey: latestScoresStorageKey),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            autoReplayThreshold = UserDefaults.standard.object(forKey: thresholdStorageKey) as? Int ?? autoReplayThreshold
            return
        }
        latestScores = decoded
        autoReplayThreshold = UserDefaults.standard.object(forKey: thresholdStorageKey) as? Int ?? autoReplayThreshold
    }

    func resetLatestScores(for currentWords: [String]) {
        let currentWordSet = Set(currentWords)
        latestScores = latestScores.filter { !currentWordSet.contains($0.key) }
        persistLatestScores()
        statusMessage = "已重置当前词表的错题与得分记录。"
    }

    var scoredWordCount: Int {
        latestScores.count
    }

    var lowScoreWordCount: Int {
        latestScores.values.filter { $0 < autoReplayThreshold }.count
    }

    var averageScoreText: String {
        guard !latestScores.isEmpty else { return "-" }
        let sum = latestScores.values.reduce(0, +)
        let average = Double(sum) / Double(latestScores.count)
        return String(format: "%.1f / 100", average)
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
        latestScores[expected] = score
        persistLatestScores()
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
        utterance.voice = resolveInstalledVoice(for: accent)
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

    private func hasInstalledVoice(for accent: AccentOption) -> Bool {
        AVSpeechSynthesisVoice.speechVoices().contains {
            $0.language.caseInsensitiveCompare(accent.rawValue) == .orderedSame
        }
    }

    private func resolveInstalledVoice(for accent: AccentOption) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        if let exact = voices.first(where: {
            $0.language.caseInsensitiveCompare(accent.rawValue) == .orderedSame
        }) {
            return exact
        }

        if let englishFallback = voices.first(where: { $0.language.lowercased().hasPrefix("en") }) {
            return englishFallback
        }

        return nil
    }

    private func prepareForSpeechPlayback() -> Bool {
        if isRecording || audioEngine.isRunning {
            stopRecognitionPipeline()
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            return true
        } catch {
            statusMessage = "启动发音失败：\(error.localizedDescription)"
            return false
        }
    }

    private func persistLatestScores() {
        guard let data = try? JSONEncoder().encode(latestScores) else { return }
        UserDefaults.standard.set(data, forKey: latestScoresStorageKey)
    }

    private func persistThreshold() {
        UserDefaults.standard.set(autoReplayThreshold, forKey: thresholdStorageKey)
    }
}
