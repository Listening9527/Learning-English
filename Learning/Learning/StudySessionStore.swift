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
    private let studyListNextBatchOffsetsKey = "learning.studyListNextBatchOffsets"

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

    func nextBatchOffset(for studyListID: Int64) -> Int {
        max(0, storedStudyListNextBatchOffsets()[storageKey(for: studyListID)] ?? 0)
    }

    func markBatchCompleted(studyListID: Int64, batchStart: Int, batchSize: Int) {
        var offsets = storedStudyListNextBatchOffsets()
        offsets[storageKey(for: studyListID)] = max(0, batchStart + max(batchSize, 1))
        persistStudyListNextBatchOffsets(offsets)
    }

    func resetBatchProgress(for studyListID: Int64) {
        var offsets = storedStudyListNextBatchOffsets()
        offsets[storageKey(for: studyListID)] = 0
        persistStudyListNextBatchOffsets(offsets)
    }

    static func resetAllBatchProgress(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "learning.studyListNextBatchOffsets")
    }

    private func storageKey(for studyListID: Int64) -> String {
        String(studyListID)
    }

    private func storedStudyListNextBatchOffsets() -> [String: Int] {
        defaults.dictionary(forKey: studyListNextBatchOffsetsKey) as? [String: Int] ?? [:]
    }

    private func persistStudyListNextBatchOffsets(_ offsets: [String: Int]) {
        defaults.set(offsets, forKey: studyListNextBatchOffsetsKey)
    }
}
