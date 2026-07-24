# Task 5 Brief

Task: Build CalendarPage with backfill flow and dashboard refresh.

Files:
- Create: learning/Learning/Learning/CalendarPage.swift
- Modify: learning/Learning/Learning/DatabaseManager.swift
- Modify: learning/Learning/Learning/DashboardStore.swift
- Update or create: learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift
- Modify: learning/Learning/Learning/MainPage.swift (only to wire calendar tab to CalendarPage)

Consumes:
- DashboardStore
- date summaries from daily_records
- backfill write method in DatabaseManager

Produces:
- struct DailyCompletionSummary: Identifiable, Equatable
- struct CalendarPage: View
- DatabaseManager methods:
  - fetchMonthlyCompletionSummary(for month: Date) throws -> [DailyCompletionSummary]
  - backfillPractice(on day: Date) throws

Required failing test:
```swift
func test_backfillPractice_creates_completion_for_selected_day() throws {
    let database = DatabaseManager.shared
    try database.resetTestingFixturesForTesting()

    let day = Date(timeIntervalSince1970: 1_722_384_000)

    try database.backfillPractice(on: day)

    let summary = try database.fetchMonthlyCompletionSummary(for: day)
    XCTAssertTrue(summary.contains(where: { $0.dateKey == "2024-08-01" }))
}
```

Required fail command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_backfillPractice_creates_completion_for_selected_day

Expected fail reason:
- backfillPractice and/or fetchMonthlyCompletionSummary do not exist yet.

Implementation requirements:
- CalendarPage should include a minimal month summary UI and backfill interaction (sheet + confirm) within Task 5 scope.
- Backfill success must refresh DashboardStore state through a single refresh path.
- Keep implementation focused; do not implement Search/Wordbook/Settings details in this task.
- Preserve prior task behavior and tests.

Required pass command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_backfillPractice_creates_completion_for_selected_day
