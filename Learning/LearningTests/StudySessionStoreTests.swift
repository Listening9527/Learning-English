import XCTest
@testable import Learning

@MainActor
final class StudySessionStoreTests: XCTestCase {
    private static let sharedScorer = PronunciationScorer()

    func test_studyPage_preserves_injected_scorer_instance() {
        let scorer = Self.sharedScorer
        let view = StudyPage.makeForTesting(scorer: scorer)

        XCTAssertTrue(view.scorer === scorer)
    }

    func test_studyResultFailure_keeps_localProgress_available() async throws {
        let store = StudySessionStore()

        store.cacheProgress(words: ["hello", "world"], currentIndex: 1, mode: .review)
        store.handleSubmissionFailureForTesting()

        XCTAssertEqual(store.cachedWordCount, 2)
        XCTAssertEqual(store.cachedCurrentIndex, 1)
        XCTAssertEqual(store.cachedMode, .review)
    }
}