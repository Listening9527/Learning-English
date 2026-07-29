import SwiftUI

struct GrammarTopicPage: View {
    let topic: GrammarTopic
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            Section {
                Text(topic.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("课时") {
                ForEach(topic.lessons) { lesson in
                    NavigationLink {
                        GrammarLessonPage(lesson: lesson, progressStore: progressStore, reviewStore: reviewStore)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(.headline)
                            Text(lesson.goal)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(topic.title)
    }
}
