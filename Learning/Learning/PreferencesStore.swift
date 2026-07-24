import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published private(set) var preferences: UserPreferences = .default

    var dailyGoal: Int {
        preferences.dailyGoal
    }

    func reload() async {
        do {
            preferences = try DatabaseManager.shared.fetchUserPreferences()
        } catch {
            preferences = .default
        }
    }

    func saveDailyGoal(_ goal: Int) async throws {
        var updated = preferences
        updated.dailyGoal = max(goal, 1)
        try DatabaseManager.shared.saveUserPreferences(updated)
        preferences = updated
    }

    func save(_ preferences: UserPreferences) async throws {
        var sanitized = preferences
        sanitized.dailyGoal = max(sanitized.dailyGoal, 1)
        sanitized.notificationHour = max(0, min(sanitized.notificationHour, 23))
        sanitized.notificationMinute = max(0, min(sanitized.notificationMinute, 59))

        try DatabaseManager.shared.saveUserPreferences(sanitized)
        self.preferences = sanitized
    }
}