import Foundation

struct WeeklyCheckInDay: Identifiable, Equatable {
    let date: String
    let practiced: Bool

    var id: String { date }
}

struct DailyCompletionSummary: Identifiable, Equatable {
    let dateKey: String
    let practiced: Bool

    var id: String { dateKey }
}

struct RecentWordSummary: Identifiable, Equatable {
    let id: Int64
    let word: String
    let phonetic: String?
    let syllableDivision: String?
    let frequency: Double?
    let wordRoot: String?
    let partOfSpeech: String?
    let definition: String
    let translation: String?
    let example1: String?
    let example1Translation: String?
    let example2: String?
    let example2Translation: String?
    let example3: String?
    let example3Translation: String?
    let createdAt: String

    init(
        id: Int64,
        word: String,
        phonetic: String?,
        syllableDivision: String? = nil,
        frequency: Double? = nil,
        wordRoot: String? = nil,
        partOfSpeech: String?,
        definition: String,
        translation: String? = nil,
        example1: String? = nil,
        example1Translation: String? = nil,
        example2: String? = nil,
        example2Translation: String? = nil,
        example3: String? = nil,
        example3Translation: String? = nil,
        createdAt: String
    ) {
        self.id = id
        self.word = word
        self.phonetic = phonetic
        self.syllableDivision = syllableDivision
        self.frequency = frequency
        self.wordRoot = wordRoot
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.translation = translation
        self.example1 = example1
        self.example1Translation = example1Translation
        self.example2 = example2
        self.example2Translation = example2Translation
        self.example3 = example3
        self.example3Translation = example3Translation
        self.createdAt = createdAt
    }
}

struct DashboardSummary: Equatable {
    let weeklyCheckIns: [WeeklyCheckInDay]
    let recentWords: [RecentWordSummary]
    let totalWordCount: Int
    let masteredWordCount: Int

    static let empty = DashboardSummary(
        weeklyCheckIns: [],
        recentWords: [],
        totalWordCount: 0,
        masteredWordCount: 0
    )
}

struct UserPreferences: Equatable {
    var dailyGoal: Int
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int

    static let `default` = UserPreferences(
        dailyGoal: 20,
        notificationsEnabled: false,
        notificationHour: 20,
        notificationMinute: 0
    )
}
