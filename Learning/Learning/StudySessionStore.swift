import Combine
import Foundation

enum StudyMode: String {
    case standard
    case review
    case simple
}

@MainActor
final class StudySessionStore: ObservableObject {
    @Published private(set) var cachedWordCount: Int = 0
    @Published private(set) var cachedCurrentIndex: Int = 0
    @Published private(set) var cachedMode: StudyMode = .standard

    func cacheProgress(words: [String], currentIndex: Int, mode: StudyMode) {
        cachedWordCount = words.count
        cachedCurrentIndex = max(0, min(currentIndex, max(words.count - 1, 0)))
        cachedMode = mode
    }

    func handleSubmissionFailureForTesting() {
        // Keep cached progress unchanged for retry flows.
    }
}
