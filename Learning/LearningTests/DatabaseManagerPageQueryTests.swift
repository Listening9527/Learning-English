import XCTest
@testable import Learning

final class DatabaseManagerPageQueryTests: XCTestCase {
    func test_recentWordsQuery_returns_latest_words_first() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        _ = try database.insertWordForTesting(
            word: "alpha",
            phonetic: "/a/",
            partOfSpeech: "noun",
            definition: "first",
            createdAt: "2026-07-20 10:00:00"
        )
        _ = try database.insertWordForTesting(
            word: "beta",
            phonetic: "/b/",
            partOfSpeech: "noun",
            definition: "second",
            createdAt: "2026-07-21 10:00:00"
        )

        let words = try database.fetchRecentWordSummaries(limit: 3)

        XCTAssertEqual(words.prefix(2).map(\.word), ["beta", "alpha"])
    }

    func test_recentWordsQuery_uses_id_desc_when_createdAt_matches() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let firstID = try database.insertWordForTesting(
            word: "orbit",
            phonetic: "/ˈɔːrbɪt/",
            partOfSpeech: "noun",
            definition: "path around an object",
            createdAt: "2026-07-21 10:00:00"
        )
        let secondID = try database.insertWordForTesting(
            word: "radar",
            phonetic: "/ˈreɪdɑːr/",
            partOfSpeech: "noun",
            definition: "radio detection system",
            createdAt: "2026-07-21 10:00:00"
        )

        XCTAssertEqual(firstID, 1)
        XCTAssertEqual(secondID, 2)

        let words = try database.fetchRecentWordSummaries(limit: 2)

        XCTAssertEqual(words.map(\.word), ["radar", "orbit"])
    }

    func test_backfillPractice_creates_completion_for_selected_day() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let day = Calendar.current.date(
            from: DateComponents(year: 2024, month: 8, day: 1, hour: 12)
        )!

        try database.backfillPractice(on: day)

        let summary = try database.fetchMonthlyCompletionSummary(for: day)
        XCTAssertTrue(summary.contains(where: { $0.dateKey == "2024-08-01" }))
    }

    func test_backfillPractice_does_not_change_dashboard_word_count() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let before = try database.fetchDashboardSummary()
        XCTAssertEqual(before.totalWordCount, 0)

        let day = Calendar.current.date(
            from: DateComponents(year: 2024, month: 8, day: 1, hour: 12)
        )!
        try database.backfillPractice(on: day)

        let after = try database.fetchDashboardSummary()
        XCTAssertEqual(after.totalWordCount, 0)
    }

    func test_dashboardSummary_counts_words_with_nil_part_of_speech() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        _ = try database.insertWordForTesting(
            word: "plain",
            phonetic: "/pleɪn/",
            partOfSpeech: nil,
            definition: "simple",
            createdAt: "2026-07-21 10:00:00"
        )

        let summary = try database.fetchDashboardSummary()

        XCTAssertEqual(summary.totalWordCount, 1)
        XCTAssertEqual(summary.recentWords.first?.word, "plain")
    }

    func test_createCustomWord_records_searchHistory() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        _ = try database.createCustomWord(
            word: "resurface",
            phonetic: "/ˌriːˈsɜːrfəs/",
            partOfSpeech: "verb",
            definition: "to appear again",
            example: "The topic resurfaced in class."
        )

        let history = try database.fetchSearchHistory(limit: 10)
        XCTAssertTrue(history.contains("resurface"))
    }

    func test_searchWords_records_searchHistory() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        _ = try database.insertWordForTesting(
            word: "orchid",
            phonetic: "/ˈɔːrkɪd/",
            partOfSpeech: "noun",
            definition: "a flower",
            createdAt: "2026-07-21 10:00:00"
        )

        _ = try database.searchWords(query: "orch")

        let history = try database.fetchSearchHistory(limit: 10)
        XCTAssertEqual(history.first, "orch")
    }

    func test_saveUserPreferences_persists_dailyGoal() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let preferences = UserPreferences(
            dailyGoal: 30,
            notificationsEnabled: true,
            notificationHour: 21,
            notificationMinute: 15
        )

        try database.saveUserPreferences(preferences)

        let stored = try database.fetchUserPreferences()
        XCTAssertEqual(stored.dailyGoal, 30)
        XCTAssertEqual(stored.notificationsEnabled, true)
        XCTAssertEqual(stored.notificationHour, 21)
        XCTAssertEqual(stored.notificationMinute, 15)
    }
}