import SwiftUI

enum MainTab: String, CaseIterable, Hashable {
    case home
    case calendar
    case profile
}

struct MainPage: View {
    static let defaultTab: MainTab = .home

    static let tabTitles: [String] = ["首页", "日历", "我的"]

    @State private var selectedTab: MainTab = Self.defaultTab
    @StateObject private var dashboardStore = DashboardStore()
    @StateObject private var preferencesStore = PreferencesStore()
    @StateObject private var wordbookStore = WordbookStore()
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomePage(dashboardStore: dashboardStore, wordbookStore: wordbookStore, scorer: scorer)
            .tabItem {
                Label(Self.tabTitles[0], systemImage: "house.fill")
            }
            .tag(MainTab.home)

            CalendarPage(dashboardStore: dashboardStore)
            .tabItem {
                Label(Self.tabTitles[1], systemImage: "calendar")
            }
            .tag(MainTab.calendar)

            ProfilePage(
                preferencesStore: preferencesStore,
                dashboardStore: dashboardStore,
                wordbookStore: wordbookStore
            )
            .tabItem {
                Label(Self.tabTitles[2], systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
    }
}