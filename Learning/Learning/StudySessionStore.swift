import Combine
import Foundation

enum StudyMode: String {
    case standard
    case review
    case simple
}

@MainActor
final class StudySessionStore: ObservableObject {
    private let defaults: UserDefaults
    private let wordbookNextBatchOffsetsKey = "learning.wordbookNextBatchOffsets"

    @Published private(set) var cachedWordCount: Int = 0
    @Published private(set) var cachedCurrentIndex: Int = 0
    @Published private(set) var cachedMode: StudyMode = .standard

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cacheProgress(words: [String], currentIndex: Int, mode: StudyMode) {
        cachedWordCount = words.count
        cachedCurrentIndex = max(0, min(currentIndex, max(words.count - 1, 0)))
        cachedMode = mode
    }

    func handleSubmissionFailureForTesting() {
        // Keep cached progress unchanged for retry flows.
    }

    func nextBatchOffset(for wordbookID: Int64) -> Int {
        max(0, storedWordbookNextBatchOffsets()[storageKey(for: wordbookID)] ?? 0)
    }

    func markBatchCompleted(wordbookID: Int64, batchStart: Int, batchSize: Int) {
        var offsets = storedWordbookNextBatchOffsets()
        offsets[storageKey(for: wordbookID)] = max(0, batchStart + max(batchSize, 1))
        persistWordbookNextBatchOffsets(offsets)
    }

    func resetBatchProgress(for wordbookID: Int64) {
        var offsets = storedWordbookNextBatchOffsets()
        offsets[storageKey(for: wordbookID)] = 0
        persistWordbookNextBatchOffsets(offsets)
    }

    private func storageKey(for wordbookID: Int64) -> String {
        String(wordbookID)
    }

    private func storedWordbookNextBatchOffsets() -> [String: Int] {
        defaults.dictionary(forKey: wordbookNextBatchOffsetsKey) as? [String: Int] ?? [:]
    }

    private func persistWordbookNextBatchOffsets(_ offsets: [String: Int]) {
        defaults.set(offsets, forKey: wordbookNextBatchOffsetsKey)
    }
}
