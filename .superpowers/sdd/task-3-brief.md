# Task 3 Brief

Task: Add dashboard queries and aggregate store.

Files:
- Modify: learning/Learning/Learning/DatabaseManager.swift
- Create: learning/Learning/Learning/DashboardStore.swift
- Create: learning/Learning/Learning/PageModels.swift
- Create: learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift

Consumes:
- DatabaseManager.shared
- existing tables daily_records, words, user_word_progress

Produces:
- struct WeeklyCheckInDay
- struct RecentWordSummary
- struct DashboardSummary
- @MainActor final class DashboardStore: ObservableObject with func reload() async
- query methods:
  - fetchRecentWordSummaries(limit: Int) throws -> [RecentWordSummary]
  - fetchDashboardSummary() throws -> DashboardSummary
- testing helper for deterministic query order verification:
  - insertWordForTesting(word:phonetic:partOfSpeech:definition:createdAt:) throws -> Int64

Required failing test:
```swift
import XCTest
@testable import Learning

final class DatabaseManagerPageQueryTests: XCTestCase {
    func test_recentWordsQuery_returns_latest_words_first() throws {
        let database = DatabaseManager.shared

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
}
```

Required fail command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first

Expected fail reason:
- fetchRecentWordSummaries(limit:) and/or insertWordForTesting(...) do not exist yet.

Implementation requirements:
- Add minimal page-facing models in PageModels.swift.
- Add SQL-backed implementations in DatabaseManager extension. Final recent words query must order by created_at DESC, id DESC.
- Implement DashboardStore.reload() using DatabaseManager.shared.fetchDashboardSummary().
- Keep task focused. Do not add calendar/backfill/search/wordbook features yet.
- If DatabaseManager currently appears as an untracked file in working tree, preserve existing local content and append focused changes only.

Required pass command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first
