import SwiftUI

struct ProfilePage: View {
    @ObservedObject var preferencesStore: PreferencesStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var wordbookStore: WordbookStore

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
                    NavigationLink("搜索") {
                        SearchPage(dashboardStore: dashboardStore, wordbookStore: wordbookStore)
                    }

                    NavigationLink("生词本") {
                        WordbookPage()
                    }

                    NavigationLink("设置") {
                        SettingsPage(preferencesStore: preferencesStore)
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