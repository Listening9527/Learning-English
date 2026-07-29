import SwiftUI

struct GrammarLessonPage: View {
    let lesson: GrammarLesson
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            Section("本课目标") {
                Text(lesson.goal)
            }

            Section("规则讲解") {
                ForEach(Array(lesson.explanationSections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                        if let highlightRule = section.highlightRule {
                            Text(highlightRule)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section("正误对比") {
                ForEach(Array(lesson.examplePairs.enumerated()), id: \.offset) { _, pair in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("正确：\(pair.correctSentence)")
                            .foregroundStyle(.green)
                        Text("错误：\(pair.wrongSentence)")
                            .foregroundStyle(.red)
                        Text(pair.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink("开始小测") {
                    GrammarQuizPage(lesson: lesson, progressStore: progressStore, reviewStore: reviewStore)
                }
            }
        }
        .navigationTitle(lesson.title)
        .onAppear {
            progressStore.markLessonViewed(lessonID: lesson.id)
        }
    }
}
