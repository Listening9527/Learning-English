import SwiftUI

struct HomePage: View {
    enum QuickActionDestination {
        case practiceReport
        case grammarHub
    }

    static let reportQuickActionDestination: QuickActionDestination = .practiceReport
    static let grammarEntryDestination: QuickActionDestination = .grammarHub

    @ObservedObject var dashboardStore: DashboardStore
    let scorer: PronunciationScorer
    @StateObject private var grammarProgressStore = GrammarProgressStore()
    @StateObject private var grammarReviewStore = GrammarReviewStore()
    @State private var showResetScoresConfirm = false
    @State private var selectedAccent: AccentOption = .american

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryHeader
                    accentSelectionSection

                    NavigationLink {
                        StudyPage(scorer: scorer, initialAccent: selectedAccent)
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

                    practiceQuickActionsSection

                    recentWordsSection
                }
                .padding()
            }
            .navigationTitle("首页")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("搜索") {
                        SearchPage(dashboardStore: dashboardStore)
                    }
                }
            }
            .task {
                await dashboardStore.reload()
            }
            .alert("重置错题记录", isPresented: $showResetScoresConfirm) {
                Button("取消", role: .cancel) {
                }
                Button("确认重置", role: .destructive) {
                    scorer.resetAllLatestScores()
                }
            } message: {
                Text("将清空全部单词的得分与错题记录。")
            }
        }
    }

    private var practiceQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习快捷操作")
                .font(.headline)

            NavigationLink {
                StudyPage(scorer: scorer, startInWrongWordsMode: true, initialAccent: selectedAccent)
            } label: {
                quickActionCard(
                    title: "错题本练习",
                    subtitle: "只练当前批次里低于达标线的单词",
                    color: .red,
                    icon: "exclamationmark.bubble"
                )
            }
            .buttonStyle(.plain)

            Button {
                showResetScoresConfirm = true
            } label: {
                quickActionCard(
                    title: "重置错题记录",
                    subtitle: "清空全部得分与错题状态",
                    color: .gray,
                    icon: "arrow.counterclockwise"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                reportQuickActionDestinationView()
            } label: {
                quickActionCard(
                    title: "今日练习报告",
                    subtitle: "查看得分统计与达标情况",
                    color: .green,
                    icon: "chart.bar"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                grammarQuickActionDestinationView()
            } label: {
                quickActionCard(
                    title: "语法学习",
                    subtitle: "按专题系统学习英语语法",
                    color: .blue,
                    icon: "text.book.closed"
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func reportQuickActionDestinationView() -> some View {
        switch Self.reportQuickActionDestination {
        case .practiceReport:
            PracticeReportView(
                latestScores: scorer.latestScores,
                threshold: scorer.autoReplayThreshold,
                averageScoreText: scorer.averageScoreText,
                scoredWordCount: scorer.scoredWordCount,
                lowScoreWordCount: scorer.lowScoreWordCount
            )
        case .grammarHub:
            EmptyView()
        }
    }

    @ViewBuilder
    private func grammarQuickActionDestinationView() -> some View {
        switch Self.grammarEntryDestination {
        case .grammarHub:
            GrammarHubPage(
                topics: GrammarContentLoader.loadTopics(),
                progressStore: grammarProgressStore,
                reviewStore: grammarReviewStore
            )
        case .practiceReport:
            EmptyView()
        }
    }

    private func quickActionCard(title: String, subtitle: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var accentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("发音口音")
                .font(.headline)

            Picker("发音口音", selection: $selectedAccent) {
                ForEach(AccentOption.allCases) { accent in
                    Text(accent.title).tag(accent)
                }
            }
            .pickerStyle(.segmented)
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
                            dashboardStore: dashboardStore
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

                            HStack(spacing: 8) {
                                if let part = word.partOfSpeech, !part.isEmpty {
                                    Text(part)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let frequency = word.frequency {
                                    Text(String(format: "频率 %.3f", frequency))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            if let translation = word.translation, !translation.isEmpty {
                                Text(translation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
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
    @State private var quizIndex = 0
    @State private var selectedChoice = ""
    @State private var didSubmitQuizAnswer = false
    @State private var correctAnswerCount = 0

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
                spellingPatternSection(title: "元音拼写规律（核心）", items: vowelSpellingPatterns)
                spellingPatternSection(title: "双元音拼写规律（核心）", items: diphthongSpellingPatterns)
                spellingPatternSection(title: "辅音拼写规律（核心）", items: consonantSpellingPatterns)
                endingRulesSection
                multiSoundReminderSection
                ipaQuizSection

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
                        scorer.speakPhoneme(symbol: item.symbol, slowMode: false, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)

                    Button("慢速") {
                        scorer.speakPhoneme(symbol: item.symbol, slowMode: true, accent: selectedAccent)
                    }
                    .buttonStyle(.bordered)

                    Button("对比") {
                        scorer.speakPhonemeWithExample(symbol: item.symbol, exampleWord: item.playbackText, accent: selectedAccent)
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

    private func spellingPatternSection(title: String, items: [IPASpellingPatternItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.symbol)
                            .font(.headline.monospaced())
                        Text(item.graphemes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Text(item.examples)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("播放") {
                            scorer.speakPhoneme(symbol: item.symbol, slowMode: false, accent: selectedAccent)
                        }
                        .buttonStyle(.bordered)

                        Button("慢速") {
                            scorer.speakPhoneme(symbol: item.symbol, slowMode: true, accent: selectedAccent)
                        }
                        .buttonStyle(.bordered)

                        Button("对比") {
                            scorer.speakPhonemeWithExample(symbol: item.symbol, exampleWord: item.playbackText, accent: selectedAccent)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var endingRulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("词尾发音规则（高频）")
                .font(.headline)

            ForEach(endingRules) { rule in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(rule.pattern)：\(rule.pronunciation)")
                        .font(.subheadline.weight(.semibold))
                    Text(rule.rule)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(rule.examples)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("播放") {
                            scorer.speak(word: rule.playbackText, slowMode: false, accent: selectedAccent)
                        }
                        .buttonStyle(.bordered)

                        Button("慢速") {
                            scorer.speak(word: rule.playbackText, slowMode: true, accent: selectedAccent)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var multiSoundReminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("同拼写多发音提醒")
                .font(.headline)

            ForEach(multiSoundSpellings) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.spelling) -> \(item.mappings)")
                        .font(.subheadline.weight(.semibold))
                    Text(item.examples)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var vowelSpellingPatterns: [IPASpellingPatternItem] {
        IPASeedContent.vowelSpellingPatterns
    }

    private var diphthongSpellingPatterns: [IPASpellingPatternItem] {
        IPASeedContent.diphthongSpellingPatterns
    }

    private var consonantSpellingPatterns: [IPASpellingPatternItem] {
        IPASeedContent.consonantSpellingPatterns
    }

    private var endingRules: [IPAEndingRuleItem] {
        IPASeedContent.endingRules
    }

    private var multiSoundSpellings: [IPAMultiSoundItem] {
        IPASeedContent.multiSoundSpellings
    }

    private var quizItems: [IPAQuizItem] {
        IPASeedContent.quizItems
    }

    private var currentQuizItem: IPAQuizItem {
        quizItems[quizIndex]
    }

    private var isLastQuizQuestion: Bool {
        quizIndex == quizItems.count - 1
    }

    private var ipaQuizSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("音标小测")
                .font(.headline)

            Text("第 \(quizIndex + 1) / \(quizItems.count) 题")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(currentQuizItem.prompt)
                .font(.subheadline)

            ForEach(currentQuizItem.choices, id: \.self) { choice in
                Button {
                    guard !didSubmitQuizAnswer else { return }
                    selectedChoice = choice
                } label: {
                    HStack {
                        Image(systemName: selectedChoice == choice ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedChoice == choice ? .blue : .secondary)
                        Text(choice)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }

            if didSubmitQuizAnswer {
                Text(currentQuizItem.analysis)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("提交") {
                    submitQuizAnswer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedChoice.isEmpty || didSubmitQuizAnswer)

                if didSubmitQuizAnswer {
                    if isLastQuizQuestion {
                        Button("重新开始") {
                            resetQuiz()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("下一题") {
                            goToNextQuizItem()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            if didSubmitQuizAnswer && isLastQuizQuestion {
                Text("本轮得分：\(correctAnswerCount) / \(quizItems.count)")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func submitQuizAnswer() {
        guard !didSubmitQuizAnswer else { return }
        didSubmitQuizAnswer = true
        if selectedChoice == currentQuizItem.correctAnswer {
            correctAnswerCount += 1
        }
    }

    private func goToNextQuizItem() {
        guard !isLastQuizQuestion else { return }
        quizIndex += 1
        selectedChoice = ""
        didSubmitQuizAnswer = false
    }

    private func resetQuiz() {
        quizIndex = 0
        selectedChoice = ""
        didSubmitQuizAnswer = false
        correctAnswerCount = 0
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