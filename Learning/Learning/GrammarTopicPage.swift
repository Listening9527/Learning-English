import SwiftUI

struct GrammarTopicPage: View {
    let topic: GrammarTopic
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore
    @State private var selectedLevelFilter: LessonLevelFilter = .all

    private enum LessonLevelFilter: String, CaseIterable, Identifiable {
        case all
        case foundation
        case intermediate
        case advanced

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "全部"
            case .foundation:
                return "初级"
            case .intermediate:
                return "中级"
            case .advanced:
                return "冲刺"
            }
        }

        func includes(_ lesson: GrammarLesson) -> Bool {
            switch self {
            case .all:
                return true
            case .foundation:
                return lesson.level == .foundation
            case .intermediate:
                return lesson.level == .intermediate
            case .advanced:
                return lesson.level == .advanced
            }
        }
    }

    private var filteredLessons: [GrammarLesson] {
        topic.lessons.filter { selectedLevelFilter.includes($0) }
    }

    var body: some View {
        List {
            Section {
                Text(topic.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("难度") {
                Picker("难度", selection: $selectedLevelFilter) {
                    ForEach(LessonLevelFilter.allCases) { levelFilter in
                        Text(levelFilter.title)
                            .tag(levelFilter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("课时") {
                if filteredLessons.isEmpty {
                    Text("当前筛选下暂无课时")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLessons) { lesson in
                        NavigationLink {
                            GrammarLessonPage(lesson: lesson, progressStore: progressStore, reviewStore: reviewStore)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(lesson.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(lesson.level.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Text(lesson.goal)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(topic.title)
    }
}
