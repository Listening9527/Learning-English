# 语法学习模块实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Learning iOS 应用中落地一个课程化语法学习模块，包含首页入口、课程内容加载、课时进度、短测验和错题复习的完整首版闭环。

**Architecture:** 采用独立语法学习域的方式实现，不复用现有发音 scorer 作为语法状态容器。先新增语法内容模型、内容加载器、进度与复习 store，再在首页接入新的二级导航入口和一组独立 SwiftUI 页面，最后补齐针对内容解析、状态流转和导航行为的 XCTest 覆盖。

**Tech Stack:** SwiftUI、Combine、SQLite 已有基础设施、应用内本地静态内容资源、XCTest。

## 全局约束

- 保持当前三标签根结构不变。
- 第一阶段从首页接入语法模块。
- 第一版聚焦本地内容与本地持久化。
- 优先使用稳定、可预测的页面模板，而不是动态排版。
- 将语法模块视为一个边界清晰的独立学习域。
- 第一版不应新增第四个顶层 tab。
- 第一版仅支持选择题和填空题。
- 第一版不应包含金币、徽章或更完整的游戏化系统。
- 第一版不应把语法内容直接迁入 SQLite。
- 不要复用 `PronunciationScorer` 来承载语法逻辑。

---

## 文件结构

计划中的生产文件与职责：

- Modify: `learning/Learning/Learning/HomePage.swift`，新增“语法学习”入口和首页跳转。
- Create: `learning/Learning/Learning/GrammarModels.swift`，定义课程内容、进度与复习相关值类型。
- Create: `learning/Learning/Learning/GrammarContentLoader.swift`，加载本地语法课程静态内容。
- Create: `learning/Learning/Learning/GrammarProgressStore.swift`，管理课时进度、继续学习目标与掌握状态。
- Create: `learning/Learning/Learning/GrammarReviewStore.swift`，管理错题聚合与复习列表状态。
- Create: `learning/Learning/Learning/GrammarHubPage.swift`，展示语法模块首页、进度摘要与下一步动作。
- Create: `learning/Learning/Learning/GrammarTopicPage.swift`，展示专题说明和课时列表。
- Create: `learning/Learning/Learning/GrammarLessonPage.swift`，展示规则讲解、正误对比、例句和开始测验入口。
- Create: `learning/Learning/Learning/GrammarQuizPage.swift`，执行单题逐步测验与即时反馈。
- Create: `learning/Learning/Learning/GrammarReviewPage.swift`，展示错题原因、返回原课时和重试入口。
- Create: `learning/Learning/Learning/GrammarSeedContent.swift`，以 Swift 静态数据形式提供首版 1 到 2 个专题内容，避免资源文件接入复杂度。

计划中的测试文件与职责：

- Create: `learning/Learning/LearningTests/GrammarContentTests.swift`，验证课程内容完整性与加载行为。
- Create: `learning/Learning/LearningTests/GrammarProgressStoreTests.swift`，验证课时状态流转与继续学习快照。
- Create: `learning/Learning/LearningTests/GrammarReviewStoreTests.swift`，验证错题去重与复习状态变化。
- Modify: `learning/Learning/LearningTests/NavigationShellTests.swift`，补充首页语法入口的导航契约测试。

## Task 1: 建立语法内容模型与首批内容加载

**Files:**
- Create: `learning/Learning/Learning/GrammarModels.swift`
- Create: `learning/Learning/Learning/GrammarSeedContent.swift`
- Create: `learning/Learning/Learning/GrammarContentLoader.swift`
- Create: `learning/Learning/LearningTests/GrammarContentTests.swift`

**Interfaces:**
- Consumes: 无。
- Produces: `GrammarTopic`、`GrammarLesson`、`GrammarQuizItem`、`GrammarContentLoader.loadTopics() -> [GrammarTopic]`。

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import Learning

final class GrammarContentTests: XCTestCase {
    func test_grammarContentLoader_returns_topics_with_lessons_and_quiz_items() {
        let topics = GrammarContentLoader.loadTopics()

        XCTAssertFalse(topics.isEmpty)
        XCTAssertTrue(topics.allSatisfy { !$0.lessons.isEmpty })
        XCTAssertTrue(topics.flatMap(\ .lessons).allSatisfy { !$0.explanationSections.isEmpty })
        XCTAssertTrue(topics.flatMap(\ .lessons).allSatisfy { !$0.quizItems.isEmpty })
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarContentTests/test_grammarContentLoader_returns_topics_with_lessons_and_quiz_items`
Expected: FAIL，提示 `GrammarContentLoader` 或相关类型不存在。

- [ ] **Step 3: 写最小实现**

```swift
import Foundation

enum GrammarQuizItemType: String {
    case multipleChoice
    case fillInBlank
}

struct GrammarExplanationSection: Equatable {
    let title: String
    let body: String
    let highlightRule: String?
}

struct GrammarExamplePair: Equatable {
    let correctSentence: String
    let wrongSentence: String
    let explanation: String
}

struct GrammarQuizItem: Identifiable, Equatable {
    let id: String
    let type: GrammarQuizItemType
    let prompt: String
    let choices: [String]
    let correctAnswer: String
    let analysis: String
}

struct GrammarLesson: Identifiable, Equatable {
    let id: String
    let topicID: String
    let title: String
    let goal: String
    let explanationSections: [GrammarExplanationSection]
    let examplePairs: [GrammarExamplePair]
    let quizItems: [GrammarQuizItem]
    let order: Int
}

struct GrammarTopic: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let summary: String
    let order: Int
    let lessons: [GrammarLesson]
}

enum GrammarSeedContent {
    static let topics: [GrammarTopic] = [
        GrammarTopic(
            id: "tenses",
            title: "时态与语态",
            subtitle: "先掌握英语句子的时间表达",
            summary: "覆盖一般时、进行时和完成时的首批课时。",
            order: 1,
            lessons: [
                GrammarLesson(
                    id: "tenses-present-simple",
                    topicID: "tenses",
                    title: "一般现在时",
                    goal: "理解一般现在时的基本用法。",
                    explanationSections: [
                        .init(title: "规则", body: "一般现在时用于描述习惯、事实和普遍规律。", highlightRule: "主语为第三人称单数时，动词通常加 s 或 es。")
                    ],
                    examplePairs: [
                        .init(correctSentence: "She goes to school by bus.", wrongSentence: "She go to school by bus.", explanation: "第三人称单数作主语时，谓语动词需要加 s。")
                    ],
                    quizItems: [
                        .init(id: "tenses-present-simple-q1", type: .multipleChoice, prompt: "He ___ to work every day.", choices: ["go", "goes", "going"], correctAnswer: "goes", analysis: "第三人称单数 he 对应 goes。")
                    ],
                    order: 1
                )
            ]
        ),
        GrammarTopic(
            id: "relative-clauses",
            title: "定语从句",
            subtitle: "先掌握关系词与句子修饰结构",
            summary: "覆盖 who、which、that 的首批课时。",
            order: 2,
            lessons: [
                GrammarLesson(
                    id: "relative-clauses-basic",
                    topicID: "relative-clauses",
                    title: "关系代词基础",
                    goal: "理解 who、which、that 的基本作用。",
                    explanationSections: [
                        .init(title: "规则", body: "关系代词连接先行词与从句，并在从句中充当成分。", highlightRule: "人通常用 who，物通常用 which，that 可在部分场景中通用。")
                    ],
                    examplePairs: [
                        .init(correctSentence: "The boy who is running is my brother.", wrongSentence: "The boy which is running is my brother.", explanation: "先行词是人时，通常使用 who。")
                    ],
                    quizItems: [
                        .init(id: "relative-clauses-basic-q1", type: .fillInBlank, prompt: "The book ___ is on the desk is mine.", choices: [], correctAnswer: "that", analysis: "先行词是物，此处可用 that。")
                    ],
                    order: 1
                )
            ]
        )
    ]
}

enum GrammarContentLoader {
    static func loadTopics() -> [GrammarTopic] {
        GrammarSeedContent.topics.sorted { $0.order < $1.order }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarContentTests/test_grammarContentLoader_returns_topics_with_lessons_and_quiz_items`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/GrammarModels.swift Learning/Learning/GrammarSeedContent.swift Learning/Learning/GrammarContentLoader.swift LearningTests/GrammarContentTests.swift
git commit -m "feat: add grammar content models and seed loader"
```

## Task 2: 建立课时进度 store

**Files:**
- Create: `learning/Learning/Learning/GrammarProgressStore.swift`
- Create: `learning/Learning/LearningTests/GrammarProgressStoreTests.swift`

**Interfaces:**
- Consumes: `GrammarTopic`、`GrammarLesson`。
- Produces: `GrammarLessonStatus`、`GrammarLessonProgress`、`GrammarProgressStore.markLessonViewed(lessonID:)`、`GrammarProgressStore.completeQuiz(lessonID:score:)`、`GrammarProgressStore.continueLessonID`。

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import Learning

@MainActor
final class GrammarProgressStoreTests: XCTestCase {
    func test_markLessonViewed_sets_status_to_inProgress_and_updates_continue_target() {
        let store = GrammarProgressStore()

        store.markLessonViewed(lessonID: "tenses-present-simple")

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .inProgress)
        XCTAssertEqual(store.continueLessonID, "tenses-present-simple")
    }

    func test_completeQuiz_with_passing_score_marks_lesson_mastered() {
        let store = GrammarProgressStore()

        store.completeQuiz(lessonID: "tenses-present-simple", score: 100)

        XCTAssertEqual(store.progressByLessonID["tenses-present-simple"]?.status, .mastered)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarProgressStoreTests`
Expected: FAIL，提示 `GrammarProgressStore` 或状态类型不存在。

- [ ] **Step 3: 写最小实现**

```swift
import Combine
import Foundation

enum GrammarLessonStatus: String, Equatable {
    case notStarted
    case inProgress
    case mastered
}

struct GrammarLessonProgress: Equatable {
    let lessonID: String
    var status: GrammarLessonStatus
    var lastScore: Int?
    var completedAt: Date?
    var lastViewedAt: Date?
    var attemptCount: Int
}

@MainActor
final class GrammarProgressStore: ObservableObject {
    @Published private(set) var progressByLessonID: [String: GrammarLessonProgress] = [:]
    @Published private(set) var continueLessonID: String?

    private let passingScore = 80

    func markLessonViewed(lessonID: String) {
        var progress = progressByLessonID[lessonID] ?? GrammarLessonProgress(
            lessonID: lessonID,
            status: .notStarted,
            lastScore: nil,
            completedAt: nil,
            lastViewedAt: nil,
            attemptCount: 0
        )

        if progress.status == .notStarted {
            progress.status = .inProgress
        }
        progress.lastViewedAt = Date()
        progressByLessonID[lessonID] = progress
        continueLessonID = lessonID
    }

    func completeQuiz(lessonID: String, score: Int) {
        var progress = progressByLessonID[lessonID] ?? GrammarLessonProgress(
            lessonID: lessonID,
            status: .inProgress,
            lastScore: nil,
            completedAt: nil,
            lastViewedAt: nil,
            attemptCount: 0
        )

        progress.lastScore = score
        progress.attemptCount += 1
        progress.lastViewedAt = Date()

        if score >= passingScore {
            progress.status = .mastered
            progress.completedAt = Date()
        } else {
            progress.status = .inProgress
        }

        progressByLessonID[lessonID] = progress
        continueLessonID = lessonID
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarProgressStoreTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/GrammarProgressStore.swift LearningTests/GrammarProgressStoreTests.swift
git commit -m "feat: add grammar progress store"
```

## Task 3: 建立错题复习 store

**Files:**
- Create: `learning/Learning/Learning/GrammarReviewStore.swift`
- Create: `learning/Learning/LearningTests/GrammarReviewStoreTests.swift`

**Interfaces:**
- Consumes: `GrammarQuizItem`。
- Produces: `GrammarReviewItem`、`GrammarReviewStore.recordWrongAnswer(lessonID:quizItemID:)`、`GrammarReviewStore.markResolved(quizItemID:)`、`GrammarReviewStore.pendingItems`。

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import Learning

@MainActor
final class GrammarReviewStoreTests: XCTestCase {
    func test_recordWrongAnswer_deduplicates_same_quiz_item() {
        let store = GrammarReviewStore()

        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")
        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")

        XCTAssertEqual(store.pendingItems.count, 1)
        XCTAssertEqual(store.pendingItems.first?.wrongCount, 2)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarReviewStoreTests`
Expected: FAIL，提示 `GrammarReviewStore` 不存在。

- [ ] **Step 3: 写最小实现**

```swift
import Combine
import Foundation

struct GrammarReviewItem: Identifiable, Equatable {
    var id: String { quizItemID }
    let lessonID: String
    let quizItemID: String
    var wrongCount: Int
    var lastWrongAt: Date
    var isResolved: Bool
}

@MainActor
final class GrammarReviewStore: ObservableObject {
    @Published private(set) var pendingItems: [GrammarReviewItem] = []

    func recordWrongAnswer(lessonID: String, quizItemID: String) {
        if let index = pendingItems.firstIndex(where: { $0.quizItemID == quizItemID }) {
            pendingItems[index].wrongCount += 1
            pendingItems[index].lastWrongAt = Date()
            pendingItems[index].isResolved = false
            return
        }

        pendingItems.append(
            GrammarReviewItem(
                lessonID: lessonID,
                quizItemID: quizItemID,
                wrongCount: 1,
                lastWrongAt: Date(),
                isResolved: false
            )
        )
    }

    func markResolved(quizItemID: String) {
        guard let index = pendingItems.firstIndex(where: { $0.quizItemID == quizItemID }) else {
            return
        }
        pendingItems[index].isResolved = true
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarReviewStoreTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/GrammarReviewStore.swift LearningTests/GrammarReviewStoreTests.swift
git commit -m "feat: add grammar review store"
```

## Task 4: 接入首页语法入口与模块首页

**Files:**
- Modify: `learning/Learning/Learning/HomePage.swift`
- Create: `learning/Learning/Learning/GrammarHubPage.swift`
- Modify: `learning/Learning/LearningTests/NavigationShellTests.swift`

**Interfaces:**
- Consumes: `GrammarContentLoader.loadTopics()`、`GrammarProgressStore`、`GrammarReviewStore`。
- Produces: `HomePage` 新的语法入口导航、`GrammarHubPage` 页面。

- [ ] **Step 1: 写失败测试**

```swift
func test_homePage_exposes_grammar_entry_destination() {
    XCTAssertEqual(HomePage.grammarEntryDestination, .grammarHub)
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/NavigationShellTests/test_homePage_exposes_grammar_entry_destination`
Expected: FAIL，提示 `grammarEntryDestination` 不存在。

- [ ] **Step 3: 写最小实现**

```swift
enum HomeQuickEntryDestination {
    case practiceReport
    case grammarHub
}
```

在 `HomePage` 中新增：

```swift
static let grammarEntryDestination: HomeQuickEntryDestination = .grammarHub
```

并新增一个语法学习卡片：

```swift
NavigationLink {
    GrammarHubPage(
        topics: GrammarContentLoader.loadTopics(),
        progressStore: GrammarProgressStore(),
        reviewStore: GrammarReviewStore()
    )
} label: {
    quickActionCard(
        title: "语法学习",
        subtitle: "按专题系统学习英语语法",
        color: .blue,
        icon: "text.book.closed"
    )
}
.buttonStyle(.plain)
```

`GrammarHubPage` 最小实现：

```swift
import SwiftUI

struct GrammarHubPage: View {
    let topics: [GrammarTopic]
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            Section("继续学习") {
                Text(progressStore.continueLessonID ?? "先选择一个专题开始")
            }

            Section("专题") {
                ForEach(topics) { topic in
                    NavigationLink(topic.title) {
                        GrammarTopicPage(topic: topic, progressStore: progressStore, reviewStore: reviewStore)
                    }
                }
            }

            Section("待复习") {
                Text("待复习题数：\(reviewStore.pendingItems.filter { !$0.isResolved }.count)")
            }
        }
        .navigationTitle("语法学习")
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/NavigationShellTests/test_homePage_exposes_grammar_entry_destination`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/HomePage.swift Learning/Learning/GrammarHubPage.swift LearningTests/NavigationShellTests.swift
git commit -m "feat: add grammar hub entry from home"
```

## Task 5: 实现专题页与课时页

**Files:**
- Create: `learning/Learning/Learning/GrammarTopicPage.swift`
- Create: `learning/Learning/Learning/GrammarLessonPage.swift`

**Interfaces:**
- Consumes: `GrammarTopic`、`GrammarLesson`、`GrammarProgressStore`、`GrammarReviewStore`。
- Produces: 课时列表页和课时内容页。

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import Learning

final class GrammarContentTests: XCTestCase {
    func test_seed_lessons_include_example_pairs() {
        let lessons = GrammarContentLoader.loadTopics().flatMap(\ .lessons)
        XCTAssertTrue(lessons.allSatisfy { !$0.examplePairs.isEmpty })
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarContentTests/test_seed_lessons_include_example_pairs`
Expected: FAIL，如果内容或页面契约还未满足。

- [ ] **Step 3: 写最小实现**

`GrammarTopicPage.swift` 最小实现：

```swift
import SwiftUI

struct GrammarTopicPage: View {
    let topic: GrammarTopic
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            Section {
                Text(topic.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("课时") {
                ForEach(topic.lessons) { lesson in
                    NavigationLink {
                        GrammarLessonPage(lesson: lesson, progressStore: progressStore, reviewStore: reviewStore)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(.headline)
                            Text(lesson.goal)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(topic.title)
    }
}
```

`GrammarLessonPage.swift` 最小实现：

```swift
import SwiftUI

struct GrammarLessonPage: View {
    let lesson: GrammarLesson
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            Section("本课目标") {
                Text(lesson.goal)
            }

            Section("规则讲解") {
                ForEach(Array(lesson.explanationSections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                        if let highlightRule = section.highlightRule {
                            Text(highlightRule)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section("正误对比") {
                ForEach(Array(lesson.examplePairs.enumerated()), id: \.offset) { _, pair in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("正确：\(pair.correctSentence)")
                            .foregroundStyle(.green)
                        Text("错误：\(pair.wrongSentence)")
                            .foregroundStyle(.red)
                        Text(pair.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink("开始小测") {
                    GrammarQuizPage(lesson: lesson, progressStore: progressStore, reviewStore: reviewStore)
                }
            }
        }
        .navigationTitle(lesson.title)
        .onAppear {
            progressStore.markLessonViewed(lessonID: lesson.id)
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarContentTests/test_seed_lessons_include_example_pairs`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/GrammarTopicPage.swift Learning/Learning/GrammarLessonPage.swift LearningTests/GrammarContentTests.swift
git commit -m "feat: add grammar topic and lesson pages"
```

## Task 6: 实现测验页与错题复习页

**Files:**
- Create: `learning/Learning/Learning/GrammarQuizPage.swift`
- Create: `learning/Learning/Learning/GrammarReviewPage.swift`

**Interfaces:**
- Consumes: `GrammarLesson`、`GrammarProgressStore`、`GrammarReviewStore`。
- Produces: 测验交互页、复习列表页。

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import Learning

@MainActor
final class GrammarReviewStoreTests: XCTestCase {
    func test_markResolved_sets_review_item_to_resolved() {
        let store = GrammarReviewStore()
        store.recordWrongAnswer(lessonID: "tenses-present-simple", quizItemID: "tenses-present-simple-q1")

        store.markResolved(quizItemID: "tenses-present-simple-q1")

        XCTAssertEqual(store.pendingItems.first?.isResolved, true)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarReviewStoreTests/test_markResolved_sets_review_item_to_resolved`
Expected: FAIL，如果 `markResolved` 尚未满足页面需求。

- [ ] **Step 3: 写最小实现**

`GrammarQuizPage.swift` 最小实现：

```swift
import SwiftUI

struct GrammarQuizPage: View {
    let lesson: GrammarLesson
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    @State private var currentIndex = 0
    @State private var selectedAnswer = ""
    @State private var didSubmit = false

    private var currentItem: GrammarQuizItem {
        lesson.quizItems[currentIndex]
    }

    var body: some View {
        List {
            Section("题目") {
                Text(currentItem.prompt)
                if currentItem.type == .multipleChoice {
                    ForEach(currentItem.choices, id: \.self) { choice in
                        Button(choice) {
                            selectedAnswer = choice
                        }
                    }
                } else {
                    TextField("请输入答案", text: $selectedAnswer)
                }
            }

            Section {
                Button("提交答案") {
                    didSubmit = true
                    if selectedAnswer != currentItem.correctAnswer {
                        reviewStore.recordWrongAnswer(lessonID: lesson.id, quizItemID: currentItem.id)
                    }
                    if currentIndex == lesson.quizItems.count - 1 {
                        let correctCount = lesson.quizItems.filter { item in
                            item.id != currentItem.id ? true : selectedAnswer == item.correctAnswer
                        }.count
                        let score = Int((Double(correctCount) / Double(lesson.quizItems.count)) * 100)
                        progressStore.completeQuiz(lessonID: lesson.id, score: score)
                    }
                }
                .disabled(selectedAnswer.isEmpty)
            }

            if didSubmit {
                Section("解析") {
                    Text(currentItem.analysis)
                    if currentIndex < lesson.quizItems.count - 1 {
                        Button("下一题") {
                            currentIndex += 1
                            selectedAnswer = ""
                            didSubmit = false
                        }
                    }
                }
            }
        }
        .navigationTitle("小测")
    }
}
```

`GrammarReviewPage.swift` 最小实现：

```swift
import SwiftUI

struct GrammarReviewPage: View {
    let topics: [GrammarTopic]
    @ObservedObject var reviewStore: GrammarReviewStore

    var body: some View {
        List {
            ForEach(reviewStore.pendingItems.filter { !$0.isResolved }) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.quizItemID)
                        .font(.headline)
                    Text("错误次数：\(item.wrongCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("标记已解决") {
                        reviewStore.markResolved(quizItemID: item.quizItemID)
                    }
                }
            }
        }
        .navigationTitle("错题复习")
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/GrammarReviewStoreTests/test_markResolved_sets_review_item_to_resolved`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/GrammarQuizPage.swift Learning/Learning/GrammarReviewPage.swift LearningTests/GrammarReviewStoreTests.swift
git commit -m "feat: add grammar quiz and review pages"
```

## Task 7: 收尾导航与模块连通验证

**Files:**
- Modify: `learning/Learning/Learning/GrammarHubPage.swift`
- Modify: `learning/Learning/Learning/GrammarLessonPage.swift`
- Modify: `learning/Learning/Learning/GrammarQuizPage.swift`
- Modify: `learning/Learning/Learning/GrammarReviewPage.swift`
- Modify: `learning/Learning/LearningTests/NavigationShellTests.swift`

**Interfaces:**
- Consumes: 前面所有任务产物。
- Produces: 从首页到 Hub、专题、课时、测验、复习页的完整首版连通行为。

- [ ] **Step 1: 写失败测试**

```swift
func test_homePage_grammar_entry_targets_grammarHub() {
    XCTAssertEqual(HomePage.grammarEntryDestination, .grammarHub)
}
```

- [ ] **Step 2: 运行测试确认失败或锁定缺口**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/NavigationShellTests/test_homePage_grammar_entry_targets_grammarHub`
Expected: 如果路由契约未稳定则 FAIL，否则根据结果补齐最小差口。

- [ ] **Step 3: 写最小实现**

补齐以下行为：

```swift
// GrammarHubPage 增加复习入口
NavigationLink("去复习") {
    GrammarReviewPage(topics: topics, reviewStore: reviewStore)
}

// GrammarLessonPage 保持课时查看时更新 continue 目标
.onAppear {
    progressStore.markLessonViewed(lessonID: lesson.id)
}
```

并确保首页语法入口使用统一的 `HomeQuickEntryDestination.grammarHub` 契约。

- [ ] **Step 4: 运行聚焦测试确认通过**

Run: `cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'id=00008110-000445D0210A401E' -only-testing:LearningTests/NavigationShellTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Learning/Learning/HomePage.swift Learning/Learning/GrammarHubPage.swift Learning/Learning/GrammarLessonPage.swift Learning/Learning/GrammarQuizPage.swift Learning/Learning/GrammarReviewPage.swift LearningTests/NavigationShellTests.swift
git commit -m "feat: connect grammar learning flow"
```

## 自审

### Spec 覆盖检查

- 首页接入语法学习入口：由 Task 4 和 Task 7 覆盖。
- 五级页面结构：Task 4、Task 5、Task 6、Task 7 覆盖。
- 本地静态课程内容：Task 1 覆盖。
- 课时进度、继续学习和掌握状态：Task 2 覆盖。
- 错题去重与复习闭环：Task 3 与 Task 6 覆盖。
- 单题测验、即时反馈和解析：Task 6 覆盖。
- 首版只发 1 到 2 个专题真实内容：Task 1 中种子内容只提供两个专题。
- 导航与状态验证：Task 1 到 Task 7 全部提供聚焦测试命令。

### 占位词检查

本计划未保留 TBD、TODO、implement later、add appropriate error handling 这类空洞占位。每个任务都给出了具体文件、测试代码、执行命令和最小实现骨架。

### 类型一致性检查

- 课程内容始终使用 `GrammarTopic`、`GrammarLesson`、`GrammarQuizItem`。
- 进度始终使用 `GrammarProgressStore` 和 `GrammarLessonProgress`。
- 复习始终使用 `GrammarReviewStore` 和 `GrammarReviewItem`。
- 首页语法入口统一使用 `HomeQuickEntryDestination.grammarHub` 契约。
