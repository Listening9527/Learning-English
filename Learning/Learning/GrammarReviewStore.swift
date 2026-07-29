import Combine
import Foundation

struct GrammarReviewItem: Identifiable, Equatable {
    var id: String { quizItemID }
    let lessonID: String
    let quizItemID: String
    var wrongCount: Int
    var lastWrongAt: Date
    var isResolved: Bool
}

@MainActor
final class GrammarReviewStore: ObservableObject {
    @Published private(set) var pendingItems: [GrammarReviewItem] = []

    func recordWrongAnswer(lessonID: String, quizItemID: String) {
        if let index = pendingItems.firstIndex(where: { $0.quizItemID == quizItemID }) {
            pendingItems[index].wrongCount += 1
            pendingItems[index].lastWrongAt = Date()
            pendingItems[index].isResolved = false
            return
        }

        pendingItems.append(
            GrammarReviewItem(
                lessonID: lessonID,
                quizItemID: quizItemID,
                wrongCount: 1,
                lastWrongAt: Date(),
                isResolved: false
            )
        )
    }

    func markResolved(quizItemID: String) {
        guard let index = pendingItems.firstIndex(where: { $0.quizItemID == quizItemID }) else {
            return
        }

        pendingItems[index].isResolved = true
    }
}
