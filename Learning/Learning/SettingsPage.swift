import SwiftUI

struct SettingsPage: View {
    @ObservedObject var preferencesStore: PreferencesStore

    @State private var notificationsEnabled = false
    @State private var notificationHour = 20
    @State private var notificationMinute = 0
    @State private var dailyGoal = 20
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
