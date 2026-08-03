import SwiftUI

struct ProfilePage: View {
    @ObservedObject var preferencesStore: PreferencesStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var scorer: PronunciationScorer
    @State private var showResetScoresConfirm = false

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

                        Toggle("语音降噪增强（系统语音处理）", isOn: $scorer.enableVoiceProcessing)
                    }
                    .padding(.vertical, 4)
                }

                Section("更多") {
                    NavigationLink("今日练习报告") {
                        PracticeReportView(
                            latestScores: scorer.latestScores,
                            threshold: scorer.autoReplayThreshold,
                            averageScoreText: scorer.averageScoreText,
                            scoredWordCount: scorer.scoredWordCount,
                            lowScoreWordCount: scorer.lowScoreWordCount
                        )
                    }

                    Button("重置错题记录", role: .destructive) {
                        showResetScoresConfirm = true
                    }

                    NavigationLink("搜索") {
                        SearchPage(dashboardStore: dashboardStore)
                    }

                    NavigationLink("设置") {
                        SettingsPage(preferencesStore: preferencesStore, dashboardStore: dashboardStore, scorer: scorer)
                    }
                }
            }
            .navigationTitle("我的")
            .task {
                await preferencesStore.reload()
            }
            .alert("重置错题记录", isPresented: $showResetScoresConfirm) {
                Button("取消", role: .cancel) {
                }
                Button("确认重置", role: .destructive) {
                    scorer.resetAllLatestScores()
                }
            } message: {
                Text("将清空全部单词的得分与错题记录。")
            }
        }
    }
}
