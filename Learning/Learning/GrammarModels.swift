import Foundation

enum GrammarQuizItemType: String {
    case multipleChoice
    case fillInBlank
}

enum GrammarLessonLevel: String, CaseIterable, Equatable {
    case foundation
    case intermediate
    case advanced

    var title: String {
        switch self {
        case .foundation:
            return "初级"
        case .intermediate:
            return "中级"
        case .advanced:
            return "冲刺"
        }
    }
}

struct GrammarExplanationSection: Equatable {
    let title: String
    let body: String
    let highlightRule: String?
}

struct GrammarExamplePair: Equatable {
    let correctSentence: String
    let wrongSentence: String
    let explanation: String
}

struct GrammarQuizItem: Identifiable, Equatable {
    let id: String
    let type: GrammarQuizItemType
    let prompt: String
    let choices: [String]
    let correctAnswer: String
    let analysis: String
}

struct GrammarLesson: Identifiable, Equatable {
    let id: String
    let topicID: String
    let title: String
    let goal: String
    let level: GrammarLessonLevel
    let explanationSections: [GrammarExplanationSection]
    let examplePairs: [GrammarExamplePair]
    let quizItems: [GrammarQuizItem]
    let order: Int
}

struct GrammarTopic: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let summary: String
    let order: Int
    let lessons: [GrammarLesson]
}
