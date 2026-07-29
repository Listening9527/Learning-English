import Foundation

enum GrammarContentLoader {
    static func loadTopics() -> [GrammarTopic] {
        GrammarSeedContent.topics.sorted { $0.order < $1.order }
    }
}
