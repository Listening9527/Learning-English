# Task 1 Brief

Task: Add test target and root navigation smoke coverage.

Files:
- Modify: learning/Learning/Learning.xcodeproj/project.pbxproj
- Create: learning/Learning/LearningTests/NavigationShellTests.swift
- Modify: learning/Learning/Learning/LearningApp.swift
- Create: learning/Learning/Learning/MainPage.swift

Consumes:
- Existing LearningApp scene entry.

Produces:
- struct MainPage: View
- enum MainTab: String, CaseIterable, Hashable
- extension MainPage { static let defaultTab: MainTab }
- XCTest target named LearningTests that can import @testable import Learning

Required failing test:
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

Required fail command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_defaults_to_home_tab

Expected fail reason:
- LearningTests target or MainPage type does not exist yet.

Required minimal implementation:
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

Required pass command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_defaults_to_home_tab

Constraints:
- Preserve the existing DatabaseManager initialization already added in LearningApp.
- Do not overwrite unrelated local changes in the repo.
- Keep the solution minimal and focused on Task 1 only.
- Use TDD: test first, observe failure, then implement minimal code, then rerun the same focused test.
- Update the Xcode project so the new test file builds in LearningTests.
