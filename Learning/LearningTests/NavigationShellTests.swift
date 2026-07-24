import XCTest
import SwiftUI
@testable import Learning

final class NavigationShellTests: XCTestCase {
    func test_mainPage_defaults_to_home_tab() {
        XCTAssertEqual(MainPage.defaultTab, .home)
        XCTAssertEqual(MainTab.allCases, [.home, .calendar, .profile])
    }

    func test_mainPage_renders_three_top_level_tabs() {
        XCTAssertEqual(MainPage.tabTitles, ["首页", "日历", "我的"])
        XCTAssertEqual(Set(MainTab.allCases), Set([.home, .calendar, .profile]))
    }
}