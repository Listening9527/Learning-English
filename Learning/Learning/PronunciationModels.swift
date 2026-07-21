import Foundation

enum AccentOption: String, CaseIterable, Identifiable {
    case american = "en-US"
    case british = "en-GB"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .american: return "美音"
        case .british: return "英音"
        }
    }
}
