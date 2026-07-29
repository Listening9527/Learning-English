import XCTest
@testable import Learning

final class GrammarContentTests: XCTestCase {
    func test_grammarContentLoader_returns_topics_with_lessons_and_quiz_items() {
        let topics = GrammarContentLoader.loadTopics()

        XCTAssertFalse(topics.isEmpty)
        XCTAssertTrue(topics.allSatisfy { !$0.lessons.isEmpty })
        XCTAssertTrue(topics.flatMap(\.lessons).allSatisfy { !$0.explanationSections.isEmpty })
        XCTAssertTrue(topics.flatMap(\.lessons).allSatisfy { !$0.quizItems.isEmpty })
    }

    func test_seed_lessons_include_example_pairs() {
        let lessons = GrammarContentLoader.loadTopics().flatMap(\.lessons)

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertTrue(lessons.allSatisfy { !$0.examplePairs.isEmpty })
    }
}
