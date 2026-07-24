# Task 4 Brief

Task: Build HomePage and ProfilePage on shared state.

Files:
- Create: learning/Learning/Learning/HomePage.swift
- Create: learning/Learning/Learning/ProfilePage.swift
- Modify: learning/Learning/Learning/MainPage.swift
- Modify: learning/Learning/Learning/DashboardStore.swift only if required to expose data already produced by Task 3
- Create: learning/Learning/Learning/PreferencesStore.swift
- Update test: learning/Learning/LearningTests/NavigationShellTests.swift

Consumes:
- MainTab
- DashboardStore
- StudyPage

Produces:
- struct HomePage: View
- struct ProfilePage: View
- extension MainPage { static let tabTitles: [String] }
- final class PreferencesStore: ObservableObject with:
  - func reload() async
  - func saveDailyGoal(_ goal: Int) async throws

Required failing test:
```swift
func test_mainPage_renders_three_top_level_tabs() {
    XCTAssertEqual(MainPage.tabTitles, ["首页", "日历", "我的"])
    XCTAssertEqual(Set(MainTab.allCases), Set([.home, .calendar, .profile]))
}
```

Required fail command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_renders_three_top_level_tabs

Expected fail reason:
- MainPage.tabTitles does not exist yet.

Implementation requirements:
- HomePage should use DashboardStore and keep Task 3 data consumption minimal.
- HomePage must provide at least a lightweight structure matching plan intent: header context + primary CTA + recent words rendering.
- For Task 4 scope, the HomePage primary CTA can navigate to StudyPage via NavigationLink.
- ProfilePage should include entry links to WordbookPage and SettingsPage; if those pages do not exist yet in this task boundary, provide compile-safe placeholder destinations and keep TODO comments out.
- MainPage should replace placeholder tab bodies with HomePage and ProfilePage for their tabs, while preserving existing transitional behavior to current study flow.
- Add MainPage.tabTitles and keep existing MainTab enum values.
- Keep task focused on Home/Profile shell work only. Do not implement CalendarPage, SearchPage, WordDetailPage, or Wordbook detail logic here.

Required pass command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_renders_three_top_level_tabs
