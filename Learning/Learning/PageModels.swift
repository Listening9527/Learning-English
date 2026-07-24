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
    let partOfSpeech: String?
    let definition: String
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

struct WordbookSummary: Identifiable, Equatable {
    let id: Int64
    let name: String
    let description: String?
    let wordCount: Int
}

enum WordbookFilter: String, CaseIterable, Identifiable {
    case today
    case learning
    case unlearned
    case easy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "今天"
        case .learning:
            return "学习中"
        case .unlearned:
            return "未掌握"
        case .easy:
            return "已掌握"
        }
    }
}