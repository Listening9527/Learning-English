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
                    if let syllableDivision = word.syllableDivision, !syllableDivision.isEmpty {
                        Text("音节：\(syllableDivision)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let wordRoot = word.wordRoot, !wordRoot.isEmpty {
                        Text("词根：\(wordRoot)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let frequency = word.frequency {
                        Text(String(format: "出现频率：%.3f", frequency))
                            .font(.footnote)
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

                if let translation = word.translation, !translation.isEmpty {
                    Divider()
                    Text(translation)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Section("例句") {
                if hasAnyExample {
                    examplesContent
                } else {
                    Text("暂无例句")
                        .foregroundStyle(.secondary)
                }
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

    private var hasAnyExample: Bool {
        [word.example1, word.example2, word.example3].contains { value in
            if let value {
                return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        }
    }

    @ViewBuilder
    private var examplesContent: some View {
        if let example1 = word.example1, !example1.isEmpty {
            exampleRow(title: "例句1", english: example1, chinese: word.example1Translation)
        }
        if let example2 = word.example2, !example2.isEmpty {
            exampleRow(title: "例句2", english: example2, chinese: word.example2Translation)
        }
        if let example3 = word.example3, !example3.isEmpty {
            exampleRow(title: "例句3", english: example3, chinese: word.example3Translation)
        }
    }

    @ViewBuilder
    private func exampleRow(title: String, english: String, chinese: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(english)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let chinese, !chinese.isEmpty {
                Text(chinese)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 2)
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
