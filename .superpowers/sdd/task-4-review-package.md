# Task 4 Review Package

## Status
?? Learning/Learning/HomePage.swift
?? Learning/Learning/MainPage.swift
?? Learning/Learning/PreferencesStore.swift
?? Learning/Learning/ProfilePage.swift
?? Learning/LearningTests/NavigationShellTests.swift

## Current File: Learning/Learning/MainPage.swift
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
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomePage(dashboardStore: dashboardStore, scorer: scorer)
            .tabItem {
                Label(Self.tabTitles[0], systemImage: "house.fill")
            }
            .tag(MainTab.home)

            NavigationStack {
                Text("Calendar")
            }
            .tabItem {
                Label(Self.tabTitles[1], systemImage: "calendar")
            }
            .tag(MainTab.calendar)

            ProfilePage(preferencesStore: preferencesStore)
            .tabItem {
                Label(Self.tabTitles[2], systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
    }
}
## Current File: Learning/Learning/HomePage.swift
import SwiftUI

struct HomePage: View {
    @ObservedObject var dashboardStore: DashboardStore
    let scorer: PronunciationScorer

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryHeader

                    NavigationLink {
                        StudyPage(scorer: scorer)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("开始今日练习")
                                    .font(.headline)
                                Text("继续当前学习流并完成发音练习")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    recentWordsSection
                }
                .padding()
            }
            .navigationTitle("首页")
            .task {
                await dashboardStore.reload()
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习概览")
                .font(.title2.weight(.semibold))
            Text("已收录 \(dashboardStore.summary.totalWordCount) 个单词，已掌握 \(dashboardStore.summary.masteredWordCount) 个")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近单词")
                .font(.headline)

            if dashboardStore.summary.recentWords.isEmpty {
                Text("最近还没有新增单词，先去开始练习。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(dashboardStore.summary.recentWords) { word in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(word.word)
                                .font(.headline)
                            if let phonetic = word.phonetic, !phonetic.isEmpty {
                                Text(phonetic)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(word.definition)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
## Current File: Learning/Learning/ProfilePage.swift
import SwiftUI

struct ProfilePage: View {
    @ObservedObject var preferencesStore: PreferencesStore

    var body: some View {
        NavigationStack {
            List {
                Section("学习偏好") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("每日目标")
                            .font(.headline)
                        Text("当前目标：\(preferencesStore.dailyGoal) 个单词")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("每日目标 +5") {
                            Task {
                                try? await preferencesStore.saveDailyGoal(preferencesStore.dailyGoal + 5)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }

                Section("更多") {
                    NavigationLink("生词本") {
                        WordbookPlaceholderPage()
                    }

                    NavigationLink("设置") {
                        SettingsPlaceholderPage()
                    }
                }
            }
            .navigationTitle("我的")
            .task {
                await preferencesStore.reload()
            }
        }
    }
}

private struct WordbookPlaceholderPage: View {
    var body: some View {
        Text("生词本页面待接入")
            .navigationTitle("生词本")
    }
}

private struct SettingsPlaceholderPage: View {
    var body: some View {
        Text("设置页面待接入")
            .navigationTitle("设置")
    }
}
## Current File: Learning/Learning/PreferencesStore.swift
import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published private(set) var dailyGoal: Int = 20

    private let dailyGoalKey = "learning.preferences.dailyGoal"

    func reload() async {
        let savedGoal = UserDefaults.standard.object(forKey: dailyGoalKey) as? Int
        dailyGoal = savedGoal ?? 20
    }

    func saveDailyGoal(_ goal: Int) async throws {
        let sanitizedGoal = max(goal, 1)
        UserDefaults.standard.set(sanitizedGoal, forKey: dailyGoalKey)
        dailyGoal = sanitizedGoal
    }
}
## Current File: Learning/LearningTests/NavigationShellTests.swift
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