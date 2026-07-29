import XCTest
@testable import Learning

@MainActor
final class GrammarReviewStoreTests: XCTestCase {
    func test_recordWrongAnswer_deduplicates_same_quiz_item() {
        let store = GrammarReviewStore()

        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")
        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")

        XCTAssertEqual(store.pendingItems.count, 1)
        XCTAssertEqual(store.pendingItems.first?.wrongCount, 2)
    }

    func test_markResolved_sets_review_item_to_resolved() {
        let store = GrammarReviewStore()

        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")
        store.markResolved(quizItemID: "tenses-present-simple-q1")

        XCTAssertEqual(store.pendingItems.first?.isResolved, true)
    }

    func test_recordWrongAnswer_afterResolved_reopens_item_and_increments_wrongCount() {
        let store = GrammarReviewStore()

        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")
        store.markResolved(quizItemID: "tenses-present-simple-q1")

        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")

        XCTAssertEqual(store.pendingItems.count, 1)
        XCTAssertEqual(store.pendingItems.first?.wrongCount, 2)
        XCTAssertEqual(store.pendingItems.first?.isResolved, false)
    }
}
