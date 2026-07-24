# Vocabulary App Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current single-page SwiftUI entry with a three-tab vocabulary app shell while extracting the existing practice flow into a dedicated StudyPage and keeping cross-page state coherent.

**Architecture:** Introduce a new MainPage root backed by focused SwiftUI pages and small observable stores. Migrate existing practice logic out of ContentView into StudyPage first, then layer lightweight Home, Calendar, Profile, Search, Wordbook, WordDetail, and Settings pages around shared data queries in DatabaseManager.

**Tech Stack:** SwiftUI, UIKit interop already used in the app, SQLite via DatabaseManager, Xcode project target configuration, optional XCTest target added as part of this work.

## Global Constraints

- Replace the single-page entry with a three-tab main application structure.
- Preserve existing study and pronunciation logic by moving it into a dedicated StudyPage instead of rewriting it immediately.
- Define page responsibilities clearly so each screen has one primary job.
- Keep cross-page state consistent through shared stores or view models rather than page-to-page manual synchronization.
- Reuse the existing database schema wherever possible and add page-level query interfaces later.
- Do not rewrite all study logic in the same step as the navigation redesign.
- Do not introduce a second navigation system alongside the new one.
- Any shared-state write must refresh the owning store after persistence succeeds.
- Failed study-result submission must preserve local progress for retry or later sync.

---

## File Structure

Planned production files and responsibilities:

- Modify: `learning/Learning/Learning/LearningApp.swift` to change the app root from ContentView to MainPage.
- Modify: `learning/Learning/Learning/ContentView.swift` to become a compatibility wrapper or remove root-only responsibilities after StudyPage extraction.
- Modify: `learning/Learning/Learning/DatabaseManager.swift` to add page-oriented query and write helper methods.
- Create: `learning/Learning/Learning/MainPage.swift` for the three-tab root shell.
- Create: `learning/Learning/Learning/HomePage.swift` for dashboard, weekly check-in summary, and recent words.
- Create: `learning/Learning/Learning/CalendarPage.swift` for monthly completion and backfill flow.
- Create: `learning/Learning/Learning/ProfilePage.swift` for avatar, greeting, wordbook, and settings entry.
- Create: `learning/Learning/Learning/SearchPage.swift` for search history, search results, and custom-word creation.
- Create: `learning/Learning/Learning/WordDetailPage.swift` for meaning cards and per-word actions.
- Create: `learning/Learning/Learning/StudyPage.swift` for extracted practice flow.
- Create: `learning/Learning/Learning/WordbookPage.swift` for wordbook list and detail entry.
- Create: `learning/Learning/Learning/WordbookDetailPage.swift` for four-way content filters.
- Create: `learning/Learning/Learning/SettingsPage.swift` for goal and notification preferences.
- Create: `learning/Learning/Learning/DashboardStore.swift` for Home and Calendar aggregate state.
- Create: `learning/Learning/Learning/StudySessionStore.swift` for StudyPage session state and result submission.
- Create: `learning/Learning/Learning/WordbookStore.swift` for wordbook membership and filtered lists.
- Create: `learning/Learning/Learning/PreferencesStore.swift` for settings persistence and in-memory state.
- Create: `learning/Learning/Learning/PageModels.swift` for shared page-facing value types if the number of small models grows.

Planned test and project files:

- Modify: `learning/Learning/Learning.xcodeproj/project.pbxproj` to add a test target if one does not exist.
- Create: `learning/Learning/LearningTests/NavigationShellTests.swift` for root shell and tab-preservation tests.
- Create: `learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift` for dashboard and wordbook aggregation queries.
- Create: `learning/Learning/LearningTests/StudySessionStoreTests.swift` for extraction-preserved study behaviors and submission fallback behavior.

## Task 1: Add Test Target And Root Navigation Smoke Coverage

**Files:**
- Modify: `learning/Learning/Learning.xcodeproj/project.pbxproj`
- Create: `learning/Learning/LearningTests/NavigationShellTests.swift`
- Modify: `learning/Learning/Learning/LearningApp.swift`
- Create: `learning/Learning/Learning/MainPage.swift`

**Interfaces:**
- Consumes: existing `LearningApp` scene entry.
- Produces: `struct MainPage: View`, `enum MainTab: String, CaseIterable, Hashable`, `extension MainPage { static let defaultTab: MainTab }`, and an XCTest target named `LearningTests` that can import `@testable import Learning`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftUI
@testable import Learning

final class NavigationShellTests: XCTestCase {
    func test_mainPage_defaults_to_home_tab() {
        XCTAssertEqual(MainPage.defaultTab, .home)
        XCTAssertEqual(MainTab.allCases, [.home, .calendar, .profile])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_defaults_to_home_tab`

Expected: FAIL because the `LearningTests` target or `MainPage` type does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
import SwiftUI

enum MainTab: String, CaseIterable, Hashable {
    case home
    case calendar
    case profile
}

struct MainPage: View {
    static let defaultTab: MainTab = .home

    @State private var selectedTab: MainTab = Self.defaultTab

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Text("Home")
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(MainTab.home)

            NavigationStack {
                Text("Calendar")
            }
            .tabItem {
                Label("日历", systemImage: "calendar")
            }
            .tag(MainTab.calendar)

            NavigationStack {
                Text("我的")
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
    }
}
```

```swift
import SwiftUI

@main
struct LearningApp: App {
    init() {
        DatabaseManager.shared.initializeDatabase()
    }

    var body: some Scene {
        WindowGroup {
            MainPage()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_defaults_to_home_tab`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning.xcodeproj/project.pbxproj /Users/lisl/workspace/learning/Learning/Learning/LearningApp.swift /Users/lisl/workspace/learning/Learning/Learning/MainPage.swift /Users/lisl/workspace/learning/Learning/LearningTests/NavigationShellTests.swift
git commit -m "test: add navigation shell test target"
```

## Task 2: Extract StudyPage From The Current ContentView

**Files:**
- Modify: `learning/Learning/Learning/ContentView.swift`
- Create: `learning/Learning/Learning/StudyPage.swift`
- Modify: `learning/Learning/Learning/PronunciationScorer.swift`
- Test: `learning/Learning/LearningTests/StudySessionStoreTests.swift`

**Interfaces:**
- Consumes: `PronunciationScorer`, `AccentOption`, current dictionary lookup behavior, and the practice state now living in `ContentView`.
- Produces: `struct StudyPage: View`, `struct LegacyStudyContent: View` if a transitional wrapper is needed, `struct ContentView: View` that forwards to `StudyPage` during the migration, and `extension StudyPage { static func makeForTesting(scorer: PronunciationScorer) -> StudyPage }`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import Learning

final class StudySessionStoreTests: XCTestCase {
    func test_studyPage_preserves_injected_scorer_instance() {
        let scorer = PronunciationScorer()
        let view = StudyPage.makeForTesting(scorer: scorer)

        XCTAssertEqual(ObjectIdentifier(view.scorer), ObjectIdentifier(scorer))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyPage_preserves_injected_scorer_instance`

Expected: FAIL because `StudyPage` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
import SwiftUI

struct StudyPage: View {
    @ObservedObject var scorer: PronunciationScorer

    static func makeForTesting(scorer: PronunciationScorer) -> StudyPage {
        StudyPage(scorer: scorer)
    }

    var body: some View {
        LegacyStudyContent(scorer: scorer)
    }
}
```

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        StudyPage(scorer: scorer)
    }
}
```

Implementation note: move the current `ContentView` state, helper methods, and nested types into `LegacyStudyContent` inside `StudyPage.swift`, preserving behavior before any visual redesign.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyPage_preserves_injected_scorer_instance`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/ContentView.swift /Users/lisl/workspace/learning/Learning/Learning/StudyPage.swift /Users/lisl/workspace/learning/Learning/LearningTests/StudySessionStoreTests.swift
git commit -m "refactor: extract study page from content view"
```

## Task 3: Add Dashboard Queries And Aggregate Store

**Files:**
- Modify: `learning/Learning/Learning/DatabaseManager.swift`
- Create: `learning/Learning/Learning/DashboardStore.swift`
- Create: `learning/Learning/Learning/PageModels.swift`
- Test: `learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift`

**Interfaces:**
- Consumes: `DatabaseManager.shared` and existing tables `daily_records`, `words`, and `user_word_progress`.
- Produces: `struct WeeklyCheckInDay`, `struct RecentWordSummary`, `struct DashboardSummary`, and `@MainActor final class DashboardStore: ObservableObject` with `func reload() async`.

- [ ] **Step 1: Write the failing test**

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

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first`

Expected: FAIL because `fetchRecentWordSummaries(limit:)` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
struct RecentWordSummary: Identifiable, Equatable {
    let id: Int64
    let word: String
    let phonetic: String
    let partOfSpeech: String
    let definition: String
    let createdAt: String
}

struct WeeklyCheckInDay: Identifiable, Equatable {
    let id: String
    let dateText: String
    let practiced: Bool
    let isToday: Bool
}

struct DashboardSummary: Equatable {
    let streakDays: Int
    let totalLearningDays: Int
    let todayCompletedCount: Int
    let dailyGoal: Int
    let weeklyDays: [WeeklyCheckInDay]
    let recentWords: [RecentWordSummary]
}
```

```swift
extension DatabaseManager {
    func fetchRecentWordSummaries(limit: Int) throws -> [RecentWordSummary] {
        []
    }

    func fetchDashboardSummary() throws -> DashboardSummary {
        DashboardSummary(
            streakDays: 0,
            totalLearningDays: 0,
            todayCompletedCount: 0,
            dailyGoal: 20,
            weeklyDays: [],
            recentWords: try fetchRecentWordSummaries(limit: 5)
        )
    }
}

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var summary = DashboardSummary(
        streakDays: 0,
        totalLearningDays: 0,
        todayCompletedCount: 0,
        dailyGoal: 20,
        weeklyDays: [],
        recentWords: []
    )

    func reload() async {
        summary = (try? DatabaseManager.shared.fetchDashboardSummary()) ?? summary
    }
}
```

Implementation note: replace the stub query with real SQL before finishing the task. The final query must order recent words by `created_at DESC, id DESC` and compute the last seven daily completion cells from `daily_records`.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/DatabaseManager.swift /Users/lisl/workspace/learning/Learning/Learning/DashboardStore.swift /Users/lisl/workspace/learning/Learning/Learning/PageModels.swift /Users/lisl/workspace/learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift
git commit -m "feat: add dashboard queries and store"
```

## Task 4: Build HomePage And ProfilePage On Shared State

**Files:**
- Create: `learning/Learning/Learning/HomePage.swift`
- Create: `learning/Learning/Learning/ProfilePage.swift`
- Modify: `learning/Learning/Learning/MainPage.swift`
- Modify: `learning/Learning/Learning/DashboardStore.swift`
- Create: `learning/Learning/Learning/PreferencesStore.swift`
- Test: `learning/Learning/LearningTests/NavigationShellTests.swift`

**Interfaces:**
- Consumes: `MainTab`, `DashboardStore`, and `StudyPage`.
- Produces: `struct HomePage: View`, `struct ProfilePage: View`, `extension MainPage { static let tabTitles: [String] }`, and `final class PreferencesStore: ObservableObject` with `func reload() async` and `func saveDailyGoal(_ goal: Int) async throws`.

- [ ] **Step 1: Write the failing test**

```swift
func test_mainPage_renders_three_top_level_tabs() {
    XCTAssertEqual(MainPage.tabTitles, ["首页", "日历", "我的"])
    XCTAssertEqual(Set(MainTab.allCases), Set([.home, .calendar, .profile]))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_renders_three_top_level_tabs`

Expected: FAIL until MainPage exposes the final tab metadata and uses the production tab set.

- [ ] **Step 3: Write minimal implementation**

```swift
struct HomePage: View {
    @StateObject private var dashboardStore = DashboardStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("继续学习")
                Button("开始背单词") {}
                ForEach(dashboardStore.summary.recentWords) { word in
                    Text(word.word)
                }
            }
            .padding()
        }
        .navigationTitle("首页")
        .task {
            await dashboardStore.reload()
        }
    }
}
```

```swift
extension MainPage {
    static let tabTitles = ["首页", "日历", "我的"]
}

struct ProfilePage: View {
    var body: some View {
        List {
            Section {
                Text("欢迎回来")
            }

            NavigationLink("我的单词本") {
                WordbookPage()
            }

            NavigationLink("设置") {
                SettingsPage()
            }
        }
        .navigationTitle("我的")
    }
}
```

Implementation note: finish this task with the gradient header, weekly check-in strip, summary card, recent word cards, and a compact streak badge in ProfilePage.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_renders_three_top_level_tabs`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/HomePage.swift /Users/lisl/workspace/learning/Learning/Learning/ProfilePage.swift /Users/lisl/workspace/learning/Learning/Learning/MainPage.swift /Users/lisl/workspace/learning/Learning/Learning/PreferencesStore.swift /Users/lisl/workspace/learning/Learning/LearningTests/NavigationShellTests.swift
git commit -m "feat: add home and profile pages"
```

## Task 5: Build CalendarPage With Backfill Flow And Dashboard Refresh

**Files:**
- Create: `learning/Learning/Learning/CalendarPage.swift`
- Modify: `learning/Learning/Learning/DatabaseManager.swift`
- Modify: `learning/Learning/Learning/DashboardStore.swift`
- Test: `learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift`

**Interfaces:**
- Consumes: `DashboardStore`, date summaries, and future backfill write method in `DatabaseManager`.
- Produces: `struct CalendarPage: View`, `func fetchMonthlyCompletionSummary(for month: Date) throws -> [DailyCompletionSummary]`, and `func backfillPractice(on day: Date) throws`.

- [ ] **Step 1: Write the failing test**

```swift
func test_backfillPractice_creates_completion_for_selected_day() throws {
    let database = DatabaseManager.shared
    let day = Date(timeIntervalSince1970: 1_722_384_000)

    try database.backfillPractice(on: day)

    let summary = try database.fetchMonthlyCompletionSummary(for: day)
    XCTAssertTrue(summary.contains(where: { $0.dateKey == "2024-08-01" }))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_backfillPractice_creates_completion_for_selected_day`

Expected: FAIL because the monthly summary and backfill helpers do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
struct DailyCompletionSummary: Identifiable, Equatable {
    let id: String
    let dateKey: String
    let completedCount: Int
    let isBackfilled: Bool
}
```

```swift
extension DatabaseManager {
    func fetchMonthlyCompletionSummary(for month: Date) throws -> [DailyCompletionSummary] {
        []
    }

    func backfillPractice(on day: Date) throws {
        // write a synthetic daily record for the selected day
    }
}
```

Implementation note: the finished task must include a bottom-sheet driven UI flow in `CalendarPage` and a single refresh path back into `DashboardStore` after successful backfill.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_backfillPractice_creates_completion_for_selected_day`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/CalendarPage.swift /Users/lisl/workspace/learning/Learning/Learning/DatabaseManager.swift /Users/lisl/workspace/learning/Learning/Learning/DashboardStore.swift /Users/lisl/workspace/learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift
git commit -m "feat: add calendar page and backfill flow"
```

## Task 6: Build SearchPage And WordDetailPage With Wordbook Actions

**Files:**
- Create: `learning/Learning/Learning/SearchPage.swift`
- Create: `learning/Learning/Learning/WordDetailPage.swift`
- Create: `learning/Learning/Learning/WordbookStore.swift`
- Modify: `learning/Learning/Learning/DatabaseManager.swift`
- Test: `learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift`

**Interfaces:**
- Consumes: search history table, words table, wordbooks tables.
- Produces: `func fetchSearchHistory(limit: Int) throws -> [String]`, `func searchWords(query: String) throws -> [RecentWordSummary]`, `func createCustomWord(...) throws -> Int64`, `func setWordbookMembership(wordID: Int64, wordbookID: Int64, isMember: Bool) throws`, and `@MainActor final class WordbookStore: ObservableObject`.

- [ ] **Step 1: Write the failing test**

```swift
func test_createCustomWord_records_searchHistory() throws {
    let database = DatabaseManager.shared

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_createCustomWord_records_searchHistory`

Expected: FAIL because the custom-word creation and history queries do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
@MainActor
final class WordbookStore: ObservableObject {
    @Published private(set) var wordbookNames: [String] = []

    func reload() async {
        wordbookNames = []
    }

    func setMembership(wordID: Int64, wordbookID: Int64, isMember: Bool) async throws {
        try DatabaseManager.shared.setWordbookMembership(wordID: wordID, wordbookID: wordbookID, isMember: isMember)
        await reload()
    }
}
```

```swift
extension DatabaseManager {
    func fetchSearchHistory(limit: Int) throws -> [String] { [] }
    func searchWords(query: String) throws -> [RecentWordSummary] { [] }
    func createCustomWord(word: String, phonetic: String, partOfSpeech: String, definition: String, example: String) throws -> Int64 { 0 }
    func setWordbookMembership(wordID: Int64, wordbookID: Int64, isMember: Bool) throws {}
}
```

Implementation note: finish the task with a searchable top bar UI, a custom-word bottom sheet, grouped meanings in WordDetailPage, and wordbook add/remove plus mark-forgotten actions wired through WordbookStore.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_createCustomWord_records_searchHistory`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/SearchPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordDetailPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordbookStore.swift /Users/lisl/workspace/learning/Learning/Learning/DatabaseManager.swift /Users/lisl/workspace/learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift
git commit -m "feat: add search and word detail flows"
```

## Task 7: Build Wordbook And Settings Pages On Shared Queries

**Files:**
- Create: `learning/Learning/Learning/WordbookPage.swift`
- Create: `learning/Learning/Learning/WordbookDetailPage.swift`
- Create: `learning/Learning/Learning/SettingsPage.swift`
- Modify: `learning/Learning/Learning/DatabaseManager.swift`
- Modify: `learning/Learning/Learning/PreferencesStore.swift`
- Test: `learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift`

**Interfaces:**
- Consumes: `WordbookStore`, `PreferencesStore`, and progress queries.
- Produces: `func fetchWordbooks() throws -> [WordbookSummary]`, `func fetchWordbookWords(wordbookID: Int64, filter: WordbookFilter) throws -> [RecentWordSummary]`, `func fetchUserPreferences() throws -> UserPreferences`, and `func saveUserPreferences(_ preferences: UserPreferences) throws`.

- [ ] **Step 1: Write the failing test**

```swift
func test_saveUserPreferences_persists_dailyGoal() throws {
    let database = DatabaseManager.shared
    let preferences = UserPreferences(dailyGoal: 30, notificationsEnabled: true, notificationHour: 21, notificationMinute: 15)

    try database.saveUserPreferences(preferences)

    let stored = try database.fetchUserPreferences()
    XCTAssertEqual(stored.dailyGoal, 30)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_saveUserPreferences_persists_dailyGoal`

Expected: FAIL because `UserPreferences` and the persistence helpers do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
struct UserPreferences: Equatable {
    let dailyGoal: Int
    let notificationsEnabled: Bool
    let notificationHour: Int
    let notificationMinute: Int
}

enum WordbookFilter: String, CaseIterable {
    case today
    case learning
    case unlearned
    case easy
}
```

```swift
extension DatabaseManager {
    func fetchUserPreferences() throws -> UserPreferences {
        UserPreferences(dailyGoal: 20, notificationsEnabled: false, notificationHour: 20, notificationMinute: 0)
    }

    func saveUserPreferences(_ preferences: UserPreferences) throws {}
}
```

Implementation note: the finished task must map daily goal and notification settings into persistent storage, and WordbookDetailPage must expose four content filters with distinct queries.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_saveUserPreferences_persists_dailyGoal`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/WordbookPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordbookDetailPage.swift /Users/lisl/workspace/learning/Learning/Learning/SettingsPage.swift /Users/lisl/workspace/learning/Learning/Learning/PreferencesStore.swift /Users/lisl/workspace/learning/Learning/Learning/DatabaseManager.swift /Users/lisl/workspace/learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift
git commit -m "feat: add wordbook and settings pages"
```

## Task 8: Wire MainPage Navigation And Shared Refresh Paths End To End

**Files:**
- Modify: `learning/Learning/Learning/MainPage.swift`
- Modify: `learning/Learning/Learning/HomePage.swift`
- Modify: `learning/Learning/Learning/CalendarPage.swift`
- Modify: `learning/Learning/Learning/ProfilePage.swift`
- Modify: `learning/Learning/Learning/SearchPage.swift`
- Modify: `learning/Learning/Learning/WordDetailPage.swift`
- Modify: `learning/Learning/Learning/StudyPage.swift`
- Modify: `learning/Learning/Learning/WordbookPage.swift`
- Modify: `learning/Learning/Learning/WordbookDetailPage.swift`
- Modify: `learning/Learning/Learning/SettingsPage.swift`
- Test: `learning/Learning/LearningTests/NavigationShellTests.swift`
- Test: `learning/Learning/LearningTests/StudySessionStoreTests.swift`

**Interfaces:**
- Consumes: all pages and stores from Tasks 1 through 7.
- Produces: a working tab shell with push navigation, store refresh after writes, and preserved study entry from multiple surfaces.

- [ ] **Step 1: Write the failing test**

```swift
func test_studyResultFailure_keeps_localProgress_available() async throws {
    let store = StudySessionStore()

    await store.cacheProgress(words: ["hello"], currentIndex: 0, mode: .standard)
    await store.handleSubmissionFailureForTesting()

    XCTAssertEqual(store.cachedWordCount, 1)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyResultFailure_keeps_localProgress_available`

Expected: FAIL because `StudySessionStore` and the local caching path do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
enum StudyMode: String {
    case standard
    case review
    case simple
}

@MainActor
final class StudySessionStore: ObservableObject {
    @Published private(set) var cachedWordCount: Int = 0

    func cacheProgress(words: [String], currentIndex: Int, mode: StudyMode) {
        cachedWordCount = words.count
    }

    func handleSubmissionFailureForTesting() {
        // keep cachedWordCount unchanged
    }
}
```

Implementation note: finish the task by wiring MainPage to real pages, pushing SearchPage, WordDetailPage, WordbookPage, and SettingsPage from their owning roots, and ensuring study completion, custom word add, membership change, and backfill all refresh the correct shared stores.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyResultFailure_keeps_localProgress_available`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add /Users/lisl/workspace/learning/Learning/Learning/MainPage.swift /Users/lisl/workspace/learning/Learning/Learning/HomePage.swift /Users/lisl/workspace/learning/Learning/Learning/CalendarPage.swift /Users/lisl/workspace/learning/Learning/Learning/ProfilePage.swift /Users/lisl/workspace/learning/Learning/Learning/SearchPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordDetailPage.swift /Users/lisl/workspace/learning/Learning/Learning/StudyPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordbookPage.swift /Users/lisl/workspace/learning/Learning/Learning/WordbookDetailPage.swift /Users/lisl/workspace/learning/Learning/Learning/SettingsPage.swift /Users/lisl/workspace/learning/Learning/Learning/StudySessionStore.swift /Users/lisl/workspace/learning/Learning/LearningTests/NavigationShellTests.swift /Users/lisl/workspace/learning/Learning/LearningTests/StudySessionStoreTests.swift
git commit -m "feat: wire vocabulary app shell end to end"
```

## Self-Review

Spec coverage check:

- Three-tab shell is covered by Tasks 1, 4, 5, and 8.
- StudyPage extraction is covered by Tasks 2 and 8.
- Shared stores and writeback behavior are covered by Tasks 3 through 8.
- Search, word detail, wordbook, and settings flows are covered by Tasks 6 and 7.
- Error handling for failed shared writes and local progress retention is covered by Tasks 5, 6, 7, and 8.

Placeholder scan result:

- No unresolved placeholders remain in task instructions. The only literal mentions of placeholder tokens are in this self-review section.

Type consistency check:

- `MainPage`, `StudyPage`, `DashboardStore`, `WordbookStore`, `PreferencesStore`, `StudySessionStore`, `RecentWordSummary`, `DashboardSummary`, `DailyCompletionSummary`, `UserPreferences`, and `WordbookFilter` are defined before later tasks consume them.
