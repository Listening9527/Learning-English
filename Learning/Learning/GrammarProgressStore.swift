import Combine
import Foundation

enum GrammarLessonStatus: String, Equatable {
    case notStarted
    case inProgress
    case mastered
}

struct GrammarLessonProgress: Equatable {
    let lessonID: String
    var status: GrammarLessonStatus
    var lastScore: Int?
    var completedAt: Date?
    var lastViewedAt: Date?
    var attemptCount: Int
}

@MainActor
final class GrammarProgressStore: ObservableObject {
    @Published private(set) var progressByLessonID: [String: GrammarLessonProgress] = [:]
    @Published private(set) var continueLessonID: String?

    private let passingScore = 80

    func markLessonViewed(lessonID: String) {
        var progress = progressByLessonID[lessonID] ?? GrammarLessonProgress(
            lessonID: lessonID,
            status: .notStarted,
            lastScore: nil,
            completedAt: nil,
            lastViewedAt: nil,
            attemptCount: 0
        )

        if progress.status == .notStarted {
            progress.status = .inProgress
        }

        progress.lastViewedAt = Date()
        progressByLessonID[lessonID] = progress
        continueLessonID = lessonID
    }

    func completeQuiz(lessonID: String, score: Int) {
        var progress = progressByLessonID[lessonID] ?? GrammarLessonProgress(
            lessonID: lessonID,
            status: .inProgress,
            lastScore: nil,
            completedAt: nil,
            lastViewedAt: nil,
            attemptCount: 0
        )

        progress.lastScore = score
        progress.attemptCount += 1
        progress.lastViewedAt = Date()

        if score >= passingScore {
            progress.status = .mastered
            progress.completedAt = Date()
        } else {
            progress.status = .inProgress
        }

        progressByLessonID[lessonID] = progress
        continueLessonID = lessonID
    }
}
