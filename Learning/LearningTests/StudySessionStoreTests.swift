import XCTest
@testable import Learning

@MainActor
final class StudySessionStoreTests: XCTestCase {
    private static let sharedScorer = PronunciationScorer()
    private var defaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        defaultsSuiteName = "StudySessionStoreTests.\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults(suiteName: defaultsSuiteName)?.removePersistentDomain(forName: defaultsSuiteName)
        defaultsSuiteName = nil
        super.tearDown()
    }

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

    func test_markBatchCompleted_persistsNextBatchOffset_perWordbook() {
        let defaults = try! XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        let store = StudySessionStore(defaults: defaults)

        store.markBatchCompleted(wordbookID: 42, batchStart: 10, batchSize: 10)

        XCTAssertEqual(store.nextBatchOffset(for: 42), 20)
        XCTAssertEqual(store.nextBatchOffset(for: 99), 0)
    }

    func test_resetBatchProgress_clearsStoredOffset() {
        let defaults = try! XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        let store = StudySessionStore(defaults: defaults)

        store.markBatchCompleted(wordbookID: 42, batchStart: 20, batchSize: 10)
        store.resetBatchProgress(for: 42)

        XCTAssertEqual(store.nextBatchOffset(for: 42), 0)
    }
}