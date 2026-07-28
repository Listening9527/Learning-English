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

                    ipaTutorialSection

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

    private var ipaTutorialSection: some View {
        NavigationLink {
            IPAStudyPage(scorer: scorer)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("国际音标学习教程")
                        .font(.headline)
                    Text("查看完整音标并点击播放发音")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func ipaRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(content)
                .font(.footnote)
                .foregroundStyle(.secondary)
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

struct IPAStudyPage: View {
    @ObservedObject var scorer: PronunciationScorer
    @State private var selectedAccent: AccentOption = .american

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("英语音标总表（44）")
                    .font(.title2.weight(.semibold))

                Picker("发音口音", selection: $selectedAccent) {
                    ForEach(AccentOption.allCases) { accent in
                        Text(accent.title).tag(accent)
                    }
                }
                .pickerStyle(.segmented)

                NavigationLink {
                    StudyPage(scorer: scorer)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("去跟读练习")
                                .font(.headline)
                            Text("把刚学的音标直接带入发音练习")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "mic.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                phonemeSection(title: "单元音（12）", items: monophthongs)
                phonemeSection(title: "双元音（8）", items: diphthongs)
                phonemeSection(title: "辅音（24）", items: consonants)

                Text(scorer.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("国际音标教程")
    }

    private func phonemeSection(title: String, items: [PhonemeItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items) { item in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.symbol)
                            .font(.headline.monospaced())
                        Text(item.examples)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("播放") {
                        scorer.speak(word: item.playbackText, slowMode: false, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)

                    Button("慢速") {
                        scorer.speak(word: item.playbackText, slowMode: true, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var monophthongs: [PhonemeItem] {
        [
            .init(symbol: "/i:/", examples: "see, green, sheep", playbackText: "see"),
            .init(symbol: "/ɪ/", examples: "sit, milk, ship", playbackText: "ship"),
            .init(symbol: "/e/", examples: "bed, pen, desk", playbackText: "bed"),
            .init(symbol: "/æ/", examples: "cat, map, back", playbackText: "cat"),
            .init(symbol: "/ɑː/", examples: "car, father, heart", playbackText: "father"),
            .init(symbol: "/ɒ/", examples: "hot, box, clock", playbackText: "hot"),
            .init(symbol: "/ɔː/", examples: "door, law, talk", playbackText: "door"),
            .init(symbol: "/ʊ/", examples: "book, good, look", playbackText: "book"),
            .init(symbol: "/uː/", examples: "blue, food, school", playbackText: "food"),
            .init(symbol: "/ʌ/", examples: "cup, love, lucky", playbackText: "cup"),
            .init(symbol: "/ɜː/", examples: "bird, nurse, word", playbackText: "bird"),
            .init(symbol: "/ə/", examples: "about, teacher, sofa", playbackText: "about")
        ]
    }

    private var diphthongs: [PhonemeItem] {
        [
            .init(symbol: "/eɪ/", examples: "name, day, face", playbackText: "name"),
            .init(symbol: "/aɪ/", examples: "time, my, like", playbackText: "time"),
            .init(symbol: "/ɔɪ/", examples: "boy, toy, voice", playbackText: "boy"),
            .init(symbol: "/aʊ/", examples: "now, house, out", playbackText: "house"),
            .init(symbol: "/əʊ/", examples: "go, home, open", playbackText: "home"),
            .init(symbol: "/ɪə/", examples: "ear, here, idea", playbackText: "here"),
            .init(symbol: "/eə/", examples: "air, care, where", playbackText: "care"),
            .init(symbol: "/ʊə/", examples: "tour, poor, cure", playbackText: "tour")
        ]
    }

    private var consonants: [PhonemeItem] {
        [
            .init(symbol: "/p/", examples: "pen, map, apple", playbackText: "pen"),
            .init(symbol: "/b/", examples: "book, job, bag", playbackText: "book"),
            .init(symbol: "/t/", examples: "tea, cat, water", playbackText: "tea"),
            .init(symbol: "/d/", examples: "dog, red, day", playbackText: "dog"),
            .init(symbol: "/k/", examples: "key, book, cat", playbackText: "key"),
            .init(symbol: "/g/", examples: "go, bag, game", playbackText: "go"),
            .init(symbol: "/f/", examples: "fish, life, phone", playbackText: "fish"),
            .init(symbol: "/v/", examples: "very, love, move", playbackText: "very"),
            .init(symbol: "/θ/", examples: "think, bath, thank", playbackText: "think"),
            .init(symbol: "/ð/", examples: "this, mother, breathe", playbackText: "this"),
            .init(symbol: "/s/", examples: "sun, bus, class", playbackText: "sun"),
            .init(symbol: "/z/", examples: "zoo, nose, easy", playbackText: "zoo"),
            .init(symbol: "/ʃ/", examples: "she, push, nation", playbackText: "she"),
            .init(symbol: "/ʒ/", examples: "vision, genre, measure", playbackText: "vision"),
            .init(symbol: "/h/", examples: "hat, home, ahead", playbackText: "hat"),
            .init(symbol: "/m/", examples: "man, room, summer", playbackText: "man"),
            .init(symbol: "/n/", examples: "name, run, night", playbackText: "name"),
            .init(symbol: "/ŋ/", examples: "sing, long, thanks", playbackText: "sing"),
            .init(symbol: "/l/", examples: "light, tell, play", playbackText: "light"),
            .init(symbol: "/r/", examples: "red, around, carry", playbackText: "red"),
            .init(symbol: "/j/", examples: "yes, use, young", playbackText: "yes"),
            .init(symbol: "/w/", examples: "we, window, quick", playbackText: "we"),
            .init(symbol: "/tʃ/", examples: "chair, watch, teacher", playbackText: "chair"),
            .init(symbol: "/dʒ/", examples: "job, age, giant", playbackText: "job")
        ]
    }
}

private struct PhonemeItem: Identifiable {
    let symbol: String
    let examples: String
    let playbackText: String

    var id: String { symbol }
}