import SwiftUI
import UniformTypeIdentifiers

struct SettingsPage: View {
    @ObservedObject var preferencesStore: PreferencesStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var scorer: PronunciationScorer

    @State private var notificationsEnabled = false
    @State private var notificationHour = 20
    @State private var notificationMinute = 0
    @State private var dailyGoal = 20
    @State private var isShowingFileImporter = false
    @State private var replaceExistingWords = false
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
                Toggle("覆盖已存在词条", isOn: $replaceExistingWords)
                Toggle("导入为自定义词", isOn: $importAsCustomWords)

                Button("从文件导入 words.md") {
                    isShowingFileImporter = true
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
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.plainText, .utf8PlainText, .text],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await importWordsFromSelectedFile(result)
            }
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

    private func importWordsFromSelectedFile(_ result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                return
            }

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let summary = try DatabaseManager.shared.importWordsFromMarkdown(
                fileURL: url,
                replaceExisting: replaceExistingWords,
                isCustom: importAsCustomWords
            )

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
