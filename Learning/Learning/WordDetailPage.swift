import SwiftUI

struct WordDetailPage: View {
    let word: RecentWordSummary
    @ObservedObject var dashboardStore: DashboardStore

    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("单词") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.word)
                        .font(.largeTitle.weight(.bold))
                    if let phonetic = word.phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let part = word.partOfSpeech, !part.isEmpty {
                        Text(part)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }

            Section("释义") {
                Text(word.definition)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("操作") {
                Button("标记为遗忘") {
                    Task {
                        await markForgotten()
                    }
                }
            }
        }
        .navigationTitle("单词详情")
        .alert("操作失败", isPresented: errorAlertBinding) {
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

    private func markForgotten() async {
        do {
            try DatabaseManager.shared.markWordAsForgotten(wordID: word.id)
            await dashboardStore.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
