import XCTest
@testable import Learning

@MainActor
final class GrammarProgressStoreTests: XCTestCase {
    func test_markLessonViewed_sets_status_to_inProgress_and_updates_continue_target() {
        let store = GrammarProgressStore()

        store.markLessonViewed(lessonID: "tenses-present-simple")

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .inProgress)
        XCTAssertEqual(store.continueLessonID, "tenses-present-simple")
    }

    func test_completeQuiz_with_passing_score_marks_lesson_mastered() {
        let store = GrammarProgressStore()

        store.completeQuiz(lessonID: "tenses-present-simple", score: 100)

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .mastered)
    }

    func test_completeQuiz_with_failing_score_keeps_lesson_inProgress() {
        let store = GrammarProgressStore()

        store.completeQuiz(lessonID: "tenses-present-simple", score: 60)

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .inProgress)
        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.lastScore, 60)
        XCTAssertEqual(store.continueLessonID, "tenses-present-simple")
    }

    func test_completeQuiz_increments_attemptCount_across_multiple_attempts() {
        let store = GrammarProgressStore()

        store.completeQuiz(lessonID: "tenses-present-simple", score: 60)
        store.completeQuiz(lessonID: "tenses-present-simple", score: 85)

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.attemptCount, 2)
        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .mastered)
    }
}
