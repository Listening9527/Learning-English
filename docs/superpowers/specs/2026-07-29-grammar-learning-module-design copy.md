# 语法学习模块设计

**目标：** 为 Learning iOS 应用新增一个课程化的语法学习模块，面向高中到 CET-4 / CET-6 用户，核心围绕规则讲解、例句对比、短小测验与错题复习展开。

**状态：** 设计已在对话中确认，尚未开始实现。

## 产品方向

- 语法模块是与当前发音和词汇流程并列的独立学习域。
- 模块整体应更像课程，而不是纯语法手册。
- 第一版应优化短反馈学习回路：读规则、看对比、做几题、复习错误、继续下一课。
- 第一版不应新增第四个顶层 tab。

## 推荐产品形态

一共考虑了三种产品形态：

1. 课程树式语法学习。
2. 语法参考手册。
3. 课程树 + 大题库。

推荐采用方案 1，并为后续扩展到方案 3 预留空间。

### 推荐原因

- 它与目标用户和学习诉求匹配：高中到 CET-4 / CET-6 用户需要明确的规则讲解。
- 它契合当前应用结构，因为首页已经承担学习入口聚合功能。
- 它能让第一版在不过早构建完整考试题库的前提下落地。

## 导航落点

- 保留 [learning/Learning/Learning/MainPage.swift](learning/Learning/Learning/MainPage.swift) 现有的三标签外壳。
- 在 [learning/Learning/Learning/HomePage.swift](learning/Learning/Learning/HomePage.swift) 新增“语法学习”入口。
- 通过独立的二级 Hub 页进入语法模块，而不是新增一个 tab。

这样可以保持导航稳定，并避免把语法特有状态混入无关标签页。

## 信息架构

模块应使用五级页面结构。

### 1. GrammarHubPage

作用：
展示模块级进度，并提供最快返回学习或复习的入口。

核心内容：

- 已完成课时数
- 待复习题目数
- 继续学习 CTA
- 专题列表
- 最近错题入口 CTA

### 2. GrammarTopicPage

作用：
解释一个大型语法专题，并列出其下的课时。

核心内容：

- 专题摘要
- 课时列表
- 每课状态
- 最近一次得分（若有）
- 推荐继续学习的下一课高亮

### 3. GrammarLessonPage

作用：
用一套可复用的课时模板讲清一个语法点。

必须包含的区块：

- 本课目标
- 规则讲解
- 结构模板或公式
- 正误对比
- 例句
- 开始小测 CTA

### 4. GrammarQuizPage

作用：
在读完课时后立刻验证理解程度。

约束：

- 一次只显示一道题
- 第一版仅支持选择题和填空题
- 每次提交后立即给出对错反馈
- 在继续下一题之前必须能查看解析

### 5. GrammarReviewPage

作用：
把错误答案转化为引导式纠错，而不是被动列表。

核心内容：

- 题目摘要
- 用户上次答案
- 正确答案
- 一句错误原因说明
- 跳回原课时
- 重试动作

## 用户学习流程

1. 用户打开首页。
2. 用户进入语法学习。
3. 用户到达 `GrammarHubPage`。
4. 用户选择一个专题，或点击“继续学习”。
5. 用户阅读一节课。
6. 用户开始一个短测验。
7. 如果分数达到阈值，该课标记为已掌握，并推荐下一课。
8. 如果分数未达阈值，则记录错题并引导用户进入复习。

## 内容结构

完整语法体系应被组织为八个大专题。

1. 时态与语态。
2. 情态动词。
3. 非谓语动词。
4. 名词性从句。
5. 定语从句。
6. 状语从句。
7. 虚拟语气。
8. 特殊句式。

每个专题都应采用相同的教学结构：

- 一节专题导入课
- 若干节单点课
- 一节专题总结课

### 课时模板

每一节单点课都应包含：

1. 一句本课目标
2. 中文规则讲解
3. 结构模板
4. 正误对比
5. 高频例句
6. 3 到 5 题的小测

“正误对比”是强制项，因为它最能直接体现这类用户群的学习收益。

## 数据模型

第一版应把模块数据分为三层。

### 静态课程内容

推荐模型类型：

- `GrammarTopic`：`id`、`title`、`subtitle`、`summary`、`order`、`lessons`
- `GrammarLesson`：`id`、`topicID`、`title`、`goal`、`explanationSections`、`examplePairs`、`quizItems`、`order`
- `GrammarExplanationSection`：`title`、`body`、`highlightRule`
- `GrammarExamplePair`：`correctSentence`、`wrongSentence`、`explanation`
- `GrammarQuizItem`：`id`、`type`、`prompt`、`choices`、`correctAnswer`、`analysis`

### 用户学习进度

推荐 store：

- `GrammarProgressStore`

推荐模型类型：

- `GrammarLessonProgress`：`lessonID`、`status`、`lastScore`、`completedAt`、`lastViewedAt`、`attemptCount`
- `GrammarTopicProgress`：`topicID`、`completedLessonCount`、`totalLessonCount`、`masteryRate`
- `GrammarLearningSnapshot`：`currentTopicID`、`currentLessonID`、`completedLessonCount`、`reviewCount`

第一版课时状态仅使用三种：

- `notStarted`
- `inProgress`
- `mastered`

### 测验与复习数据

推荐附加 store：

- `GrammarReviewStore`

推荐模型类型：

- `GrammarQuizAttempt`：`lessonID`、`quizItemID`、`selectedAnswer`、`isCorrect`、`answeredAt`
- `GrammarReviewItem`：`lessonID`、`quizItemID`、`wrongCount`、`lastWrongAt`、`isResolved`

## 存储策略

第一版不应把语法内容直接迁入 SQLite。

- 课程内容以本地 JSON 或静态 Swift 数据文件存储。
- 进度和复习记录以本地持久化用户数据存储。

原因：

- 内容是应用侧拥有的数据，变动频率较低
- 进度是用户侧拥有的数据，必须稳定持久化
- 在学习闭环尚未验证完之前，这样可以减少迁移与内容管理成本

## 状态流转

课时状态应按如下方式流转：

- 第一次打开课时：`notStarted` -> `inProgress`
- 测验分数达到阈值：`inProgress` -> `mastered`
- 测验分数低于阈值：保持 `inProgress`，并新增或更新复习项

复习状态应独立于课时完成状态追踪。一个已经掌握的课时，不应仅因为用户后来在某道复习题上出错，就自动回退为未掌握。

## 交互设计

### GrammarHubPage

必须包含的动作：

- 继续学习
- 去复习

这个页面应始终暴露一个清晰的下一步动作，避免用户每次都从头做决策。

### GrammarTopicPage

该页面应将简短专题说明与课时列表组合起来。用户可以直接进入任意课，但推荐继续学习的那一课应有更强的视觉强调。

### GrammarLessonPage

页面应同时支持：

- 先阅读，再测验
- 标记已读，稍后继续

视觉上最重要的区块是“正误对比”，它应使用明显区分的正向与负向样式。

### GrammarQuizPage

每一道题都应遵循如下交互顺序：

1. 作答
2. 提交
3. 看到对错反馈
4. 按需查看解析
5. 继续下一题

提交后页面不能立刻自动跳到下一题，因为用户需要先理解自己错在哪里。

### GrammarReviewPage

该页面应更像纠错导航器，而不是第二个题库。每条复习项都应解释错误点，并提供回到原课时的路径。

## 反馈规则

- 课时掌握阈值：80%。
- 通过时：显示该课已掌握，并推荐下一课。
- 未通过时：建议先复习，再重做测验。

第一版不应包含金币、徽章或更完整的游戏化系统。

## 视觉语言

模块应延续当前 SwiftUI 应用风格，而不是刻意模仿完全不同的产品。

建议的颜色语义：

- 蓝色用于规则与继续学习动作
- 绿色用于通过与已掌握状态
- 橙色用于提醒与易错提示
- 红色仅用于错误示例和错误反馈

## 错误处理

第一版应明确处理以下情况。

### 内容缺失

如果某个专题或课时内容不完整，应显示轻量回退状态和返回路径，而不是白屏。

### 进度数据损坏

如果进度数据无法解码，应用应回退到“内容可见、状态重置”的模式，而不是阻断浏览。

### 测验中断

如果用户在测验做到一半退出，课时应保持 `inProgress`，但重新进入后测验从头开始。第一版不支持中途续答。

### 重复错题

同一道题多次答错时，应更新同一条复习记录，而不是反复创建重复项。

### 本地数据后续演进

设计必须容忍带默认值的新字段，避免未来 schema 演进时破坏旧的本地记录。

## 测试策略

测试应优先覆盖学习流正确性，而不是重投入在 UI 快照上。

### 模型与内容测试

验证语法专题、课时和题目可以被正确解析，并满足最小完整性规则。

例如：

- 每节课都有讲解内容
- 每节课都有题目
- 选择题包含正确答案
- 填空题包含标准答案

### 状态流转测试

验证 `GrammarProgressStore` 和 `GrammarReviewStore` 的行为。

例如：

- 第一次进入课时后状态变为 `inProgress`
- 通过测验后课时变为 `mastered`
- 未通过测验时会创建或更新复习项
- 同一道题重复答错不会生成重复复习记录

### 导航测试

为语法入口和页面路由添加聚焦的 XCTest 覆盖。

例如：

- 首页能打开 `GrammarHubPage`
- 专题页能打开课时页
- 课时页能打开测验页
- 复习项能返回原课时

### 最小 UI 断言

UI 断言应保持窄且面向行为。

例如：

- `GrammarHubPage` 显示“继续学习”
- `GrammarLessonPage` 显示“开始小测”
- `GrammarQuizPage` 提交后可以查看解析

## 首版范围建议

第一版应包含：

- 首页语法学习入口
- 完整的页面与状态管理框架
- 八大专题目录结构
- 其中一到两个专题的真实内容首发
- 短测验与错题复习闭环
- 基础语法进度摘要

第一版不应承诺八个专题全部内容一次性完整上线。框架和学习闭环才是首要交付物。

## 集成边界

- 不要复用 [learning/Learning/Learning/PronunciationScorer.swift](learning/Learning/Learning/PronunciationScorer.swift) 来承载语法逻辑。
- 语法状态应放在专属 store 中。
- 后续可以把语法摘要聚合到 dashboard 类统计中，但第一版应保持语法域独立。

## 实现约束

- 保持当前三标签根结构不变。
- 第一阶段从首页接入语法模块。
- 第一版聚焦本地内容与本地持久化。
- 优先使用稳定、可预测的页面模板，而不是动态排版。
- 将语法模块视为一个边界清晰的独立学习域。

## 延后工作

以下内容明确不在第一版范围内：

- 大型考试题库
- 翻译题、排序题、改错题等更多题型
- 八大专题全部内容一次性完整撰写
- 高级游戏化系统
- 与发音练习流的紧耦合
- 测验中途续答