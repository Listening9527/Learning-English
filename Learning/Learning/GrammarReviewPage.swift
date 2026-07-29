import SwiftUI

struct GrammarReviewPage: View {
    let topics: [GrammarTopic]
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    private var allLessons: [GrammarLesson] {
        topics.flatMap(\.lessons)
    }

    private func lesson(for quizItemID: String) -> GrammarLesson? {
        allLessons.first(where: { lesson in
            lesson.quizItems.contains(where: { $0.id == quizItemID })
        })
    }

    private func quizItem(for quizItemID: String) -> GrammarQuizItem? {
        allLessons
            .flatMap(\.quizItems)
            .first(where: { $0.id == quizItemID })
    }

    var body: some View {
        List {
            ForEach(reviewStore.pendingItems.filter { !$0.isResolved }) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.quizItemID)
                        .font(.headline)
                    if let quizItem = quizItem(for: item.quizItemID) {
                        Text(quizItem.prompt)
                            .font(.subheadline)
                    }
                    Text("错误次数：\(item.wrongCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let quizItem = quizItem(for: item.quizItemID) {
                        Text("原因：\(quizItem.analysis)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let sourceLesson = lesson(for: item.quizItemID) {
                        NavigationLink("返回原课时重练") {
                            GrammarLessonPage(
                                lesson: sourceLesson,
                                progressStore: progressStore,
                                reviewStore: reviewStore
                            )
                        }
                    }
                    Button("标记已解决") {
                        reviewStore.markResolved(quizItemID: item.quizItemID)
                    }
                }
            }
        }
        .navigationTitle("错题复习")
    }
}
