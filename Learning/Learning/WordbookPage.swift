import SwiftUI

struct WordbookPage: View {
    @State private var wordbooks: [WordbookSummary] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if wordbooks.isEmpty {
                Text("暂无生词本")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(wordbooks) { wordbook in
                    NavigationLink {
                        WordbookDetailPage(wordbook: wordbook)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wordbook.name)
                                    .font(.headline)
                                if let description = wordbook.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(wordbook.wordCount)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("生词本")
        .task {
            await reload()
        }
        .alert("加载失败", isPresented: errorAlertBinding) {
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

    private func reload() async {
        do {
            wordbooks = try DatabaseManager.shared.fetchWordbooks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
