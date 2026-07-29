import SwiftUI

struct GrammarHubPage: View {
    let topics: [GrammarTopic]
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    private var allLessons: [GrammarLesson] {
        topics.flatMap(\.lessons)
    }

    private var continueLesson: GrammarLesson? {
        guard let continueLessonID = progressStore.continueLessonID else {
            return nil
        }
        return allLessons.first(where: { $0.id == continueLessonID })
    }

    var body: some View {
        List {
            Section("继续学习") {
                if let continueLesson {
                    NavigationLink("继续：\(continueLesson.title)") {
                        GrammarLessonPage(
                            lesson: continueLesson,
                            progressStore: progressStore,
                            reviewStore: reviewStore
                        )
                    }
                } else {
                    Text("先选择一个专题开始")
                        .foregroundStyle(.secondary)
                }
            }

            Section("专题") {
                ForEach(topics) { topic in
                    NavigationLink(topic.title) {
                        GrammarTopicPage(topic: topic, progressStore: progressStore, reviewStore: reviewStore)
                    }
                }
            }

            Section("待复习") {
                NavigationLink("去复习") {
                    GrammarReviewPage(
                        topics: topics,
                        progressStore: progressStore,
                        reviewStore: reviewStore
                    )
                }
                Text("待复习题数：\(reviewStore.pendingItems.filter { !$0.isResolved }.count)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("语法学习")
    }
}
