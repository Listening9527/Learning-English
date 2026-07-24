import Combine
import Foundation

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var summary: DashboardSummary = .empty

    func refresh() async {
        do {
            summary = try DatabaseManager.shared.fetchDashboardSummary()
        } catch {
            summary = .empty
        }
    }

    func reload() async {
        await refresh()
    }
}