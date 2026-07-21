import SwiftUI

struct PracticeReportView: View {
    let latestScores: [String: Int]
    let threshold: Int
    let averageScoreText: String
    let scoredWordCount: Int
    let lowScoreWordCount: Int

    private var sortedScores: [(word: String, score: Int)] {
        latestScores
            .map { (word: $0.key, score: $0.value) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.word < rhs.word
                }
                return lhs.score < rhs.score
            }
    }

    private var wrongWords: [(word: String, score: Int)] {
        sortedScores.filter { $0.score < threshold }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("概览") {
                    reportRow(title: "已评分单词", value: "\(scoredWordCount)")
                    reportRow(title: "平均分", value: averageScoreText)
                    reportRow(title: "错题数", value: "\(lowScoreWordCount)")
                    reportRow(title: "当前错题线", value: "< \(threshold)")
                }

                Section("错题词") {
                    if wrongWords.isEmpty {
                        Text("当前没有错题，继续保持。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(wrongWords, id: \.word) { item in
                            reportRow(title: item.word, value: "\(item.score)")
                        }
                    }
                }

                Section("全部得分") {
                    if sortedScores.isEmpty {
                        Text("还没有任何评分记录。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedScores, id: \.word) { item in
                            reportRow(title: item.word, value: "\(item.score)")
                        }
                    }
                }
            }
            .navigationTitle("今日练习报告")
        }
    }

    @ViewBuilder
    private func reportRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
