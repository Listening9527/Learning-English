import SwiftUI

struct SettingsPage: View {
    @ObservedObject var preferencesStore: PreferencesStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var scorer: PronunciationScorer

    @State private var notificationsEnabled = false
    @State private var notificationHour = 20
    @State private var notificationMinute = 0
    @State private var dailyGoal = 20
    @State private var replaceExistingWords = true
    @State private var importAsCustomWords = false
    @State private var importResultMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("学习目标") {
                Stepper("每日目标：\(dailyGoal) 个词", value: $dailyGoal, in: 1...200)
            }

            Section("提醒") {
                Toggle("开启提醒", isOn: $notificationsEnabled)

                if notificationsEnabled {
                    HStack {
                        Stepper("小时：\(notificationHour)", value: $notificationHour, in: 0...23)
                        Stepper("分钟：\(notificationMinute)", value: $notificationMinute, in: 0...59)
                    }
                }
            }

            Section("词库导入") {
                Toggle("清空现有词库后导入", isOn: $replaceExistingWords)
                Toggle("导入为自定义词", isOn: $importAsCustomWords)

                Button("从 Bundle 导入 words.md") {
                    Task {
                        await importWordsFromBundle()
                    }
                }

                if let importResultMessage, !importResultMessage.isEmpty {
                    Text(importResultMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("更多") {
                NavigationLink("练习统计与达标线设置") {
                    PracticeStatsSettingsView(scorer: scorer)
                }
            }

            Section {
                Button("保存设置") {
                    Task {
                        await saveSettings()
                    }
                }
            }
        }
        .navigationTitle("设置")
        .task {
            await preferencesStore.reload()
            syncFromStore()
        }
        .alert("保存失败", isPresented: errorAlertBinding) {
            Button("知道了", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { show in
                if !show {
                    errorMessage = nil
                }
            }
        )
    }

    private func syncFromStore() {
        let preferences = preferencesStore.preferences
        dailyGoal = preferences.dailyGoal
        notificationsEnabled = preferences.notificationsEnabled
        notificationHour = preferences.notificationHour
        notificationMinute = preferences.notificationMinute
    }

    private func importWordsFromBundle() async {
        do {
            let bundle = Bundle.main
            let bundledWordsURL =
                bundle.url(forResource: "words", withExtension: "md")
                ?? bundle.url(forResource: "words", withExtension: "md", subdirectory: "Learning")
            guard let bundledWordsURL else {
                errorMessage = "未在应用包中找到 words.md，请先将文件加入 Target 的 Copy Bundle Resources。"
                return
            }

            let summary = try DatabaseManager.shared.importWordsFromMarkdown(
                fileURL: bundledWordsURL,
                replaceExisting: replaceExistingWords,
                isCustom: importAsCustomWords
            )

            StudySessionStore.resetAllBatchProgress()
            importResultMessage = "解析 \(summary.parsed) 条，新增 \(summary.imported) 条，更新 \(summary.updated) 条，跳过 \(summary.skipped) 条。"
            await dashboardStore.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveSettings() async {
        do {
            try await preferencesStore.save(
                UserPreferences(
                    dailyGoal: dailyGoal,
                    notificationsEnabled: notificationsEnabled,
                    notificationHour: notificationHour,
                    notificationMinute: notificationMinute
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
