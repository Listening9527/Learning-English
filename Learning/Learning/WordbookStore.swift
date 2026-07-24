import Combine
import Foundation

struct WordbookOption: Identifiable, Equatable {
    let id: Int64
    let name: String
}

@MainActor
final class WordbookStore: ObservableObject {
    @Published private(set) var wordbookOptions: [WordbookOption] = []
    @Published private(set) var memberships: [Int64: Set<Int64>] = [:]

    func reload() async {
        do {
            let options = try DatabaseManager.shared.fetchWordbookOptions()
            wordbookOptions = options.map { WordbookOption(id: $0.id, name: $0.name) }
        } catch {
            wordbookOptions = []
        }
    }

    func loadMembership(for wordID: Int64) async {
        do {
            let wordMembership = try DatabaseManager.shared.fetchWordbookMembership(wordID: wordID)
            memberships[wordID] = wordMembership
        } catch {
            memberships[wordID] = []
        }
    }

    func isMember(wordID: Int64, wordbookID: Int64) -> Bool {
        memberships[wordID]?.contains(wordbookID) ?? false
    }

    func setMembership(wordID: Int64, wordbookID: Int64, isMember: Bool) async throws {
        try DatabaseManager.shared.setWordbookMembership(wordID: wordID, wordbookID: wordbookID, isMember: isMember)
        await loadMembership(for: wordID)
    }

    func markForgotten(wordID: Int64) async throws {
        try DatabaseManager.shared.markWordAsForgotten(wordID: wordID)
    }
}
