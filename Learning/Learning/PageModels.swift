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
    let syllableDivision: String? = nil
    let frequency: Double? = nil
    let wordRoot: String? = nil
    let partOfSpeech: String?
    let definition: String
    let translation: String? = nil
    let example1: String? = nil
    let example1Translation: String? = nil
    let example2: String? = nil
    let example2Translation: String? = nil
    let example3: String? = nil
    let example3Translation: String? = nil
    let createdAt: String
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
