import SwiftUI

struct HomePage: View {
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var wordbookStore: WordbookStore
    let scorer: PronunciationScorer

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryHeader

                    NavigationLink {
                        StudyPage(scorer: scorer)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("开始今日练习")
                                    .font(.headline)
                                Text("继续当前学习流并完成发音练习")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    recentWordsSection
                }
                .padding()
            }
            .navigationTitle("首页")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("搜索") {
                        SearchPage(dashboardStore: dashboardStore, wordbookStore: wordbookStore)
                    }
                }
            }
            .task {
                await dashboardStore.reload()
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习概览")
                .font(.title2.weight(.semibold))
            Text("已收录 \(dashboardStore.summary.totalWordCount) 个单词，已掌握 \(dashboardStore.summary.masteredWordCount) 个")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近单词")
                .font(.headline)

            if dashboardStore.summary.recentWords.isEmpty {
                Text("最近还没有新增单词，先去开始练习。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(dashboardStore.summary.recentWords) { word in
                    NavigationLink {
                        WordDetailPage(
                            word: word,
                            dashboardStore: dashboardStore,
                            wordbookStore: wordbookStore
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(word.word)
                                    .font(.headline)
                                if let phonetic = word.phonetic, !phonetic.isEmpty {
                                    Text(phonetic)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}