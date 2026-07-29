# 词汇应用导航与页面设计

## 背景

当前 SwiftUI 应用直接从 [learning/Learning/Learning/ContentView.swift](learning/Learning/Learning/ContentView.swift) 这个以练习为中心的单页视图启动。这个视图已经承载了发音练习、自定义单词输入、分数显示、词典查询以及练习统计入口。

SQLite schema 也已经具备扩展为更完整词汇学习产品所需的核心数据面：`wordbooks`、单词本成员关系、用户进度、每日练习记录、搜索历史以及用户设置，定义位置在 [learning/Learning/Learning/DatabaseManager.swift](learning/Learning/Learning/DatabaseManager.swift)。

本设计的目标是在保留现有练习逻辑的前提下，将应用重构为三标签的产品外壳，并把当前练习流提炼为独立的 `StudyPage`。

## 目标

- 用三标签主结构替换当前单页入口。
- 保留现有学习与发音逻辑，并将其迁移到独立的 `StudyPage`，而不是立刻重写。
- 明确各页面职责，让每个页面只有一个主任务。
- 通过共享 store 或 view model 保持跨页面状态一致，而不是靠页面之间手动同步。
- 尽量复用现有数据库 schema，后续再补充面向页面的查询接口。

## 非目标

- 在导航改造的同一步里重写全部学习逻辑。
- 一次性敲定所有页面动作的后端 API 契约。
- 在新导航之外再引入第二套导航系统。
- 对这些页面所需数据之外的 schema 做无关重构。

## 推荐方案

考虑过三种结构方案：

- 渐进式外壳迁移：新增一个三标签主容器，把当前练习界面迁移到 `StudyPage`，再逐步在外层补齐其余产品页面。
- 全量页面重写：一次性重建所有页面与状态边界。
- 最小增强：保留当前单页入口，只在外层拼接几个次级页面。

推荐采用渐进式外壳迁移。它既符合目标产品结构，又能把实现风险控制在可接受范围内，并且能复用当前已可工作的学习界面，而不是把现有逻辑直接丢弃。

## 主导航设计

应用根页面应变为 `MainPage`，由 SwiftUI `TabView` 实现三个标签：

- `HomePage`
- `CalendarPage`
- `ProfilePage`

每个标签页内部都应承载自己的 `NavigationStack`，这样 push 导航会在各自标签内隔离，用户切换标签后返回时也不会丢失该标签原有的导航上下文。

以下页面应从这些标签根页面中 push 进入，而不是作为底部 tab：

- `SearchPage`
- `WordDetailPage`
- `StudyPage`
- `WordbookPage`
- `WordbookDetailPage`
- `SettingsPage`

这个结构在 SwiftUI 里相当于 Flutter 中用 `IndexedStack` 承载三标签壳。产品目标是保留有状态的 tab，不是追求跨框架部件的字面对齐。

## 页面职责

### HomePage

`HomePage` 是默认落地页，应快速回答两个问题：用户今天该做什么，以及他应该从哪里继续。

页面包含：

- 带问候语、轻量进度摘要和搜索入口的渐变头部
- 一个七天签到网格，用火焰式完成标记表示学习状态
- 一个摘要卡片，展示连续天数、总学习天数以及今日进度与目标的对比
- 一个推入 `StudyPage` 的主按钮
- 一个以 `WordCard` 形式展示的最近单词列表

搜索不应该长期内嵌在 `HomePage`。头部按钮应跳转到 `SearchPage`，让 `HomePage` 保持在“发现与继续学习”这一核心职责上。

点击最近单词卡片应跳转到 `WordDetailPage`。

### CalendarPage

`CalendarPage` 是复习与补录入口。

页面包含：

- 一个月视图日历网格，展示学习日期、学习强度以及补录标记
- 一个统计卡片，展示总单词数、学习天数与连续天数
- 一个针对漏学日期的补录交互流程

补录流程应为：

1. 用户选择某个漏学日期
2. 一个底部 sheet 解释该操作及其影响
3. 一个确认对话框做最终确认
4. 写操作落到 API 或持久层
5. `DashboardStore` 和日历状态从事实来源重新刷新

`CalendarPage` 可以提供一个“继续今日学习”的次级动作，但不应与 `HomePage` 的主学习入口竞争。

### ProfilePage

`ProfilePage` 是个人入口页，不是第二个仪表盘。

页面包含：

- 头像与欢迎内容
- 一个可选的紧凑学习徽章或轻量摘要
- 一个进入 `WordbookPage` 的主入口
- 一个进入 `SettingsPage` 的主入口

`ProfilePage` 不应重复 `CalendarPage` 的主统计卡片，也不应复制 `HomePage` 的学习议程。

### SearchPage

`SearchPage` 使用嵌在顶部栏中的搜索框。

页面包含：

- 从搜索历史数据源加载的初始搜索历史
- 实时搜索或提交后驱动的结果列表
- 一个用于自定义单词创建的底部 sheet 表单

创建自定义单词后，应更新搜索历史、单词数据源，以及 `HomePage` 可能依赖的最近新增列表。

### WordDetailPage

`WordDetailPage` 是单个单词的信息与动作页面。

页面包含：

- 单词本身、音标与发音播放
- 按词性分组的释义卡片
- 将单词加入或移出单词本的动作
- 将单词标记为“已忘记”的动作
- 立即开始学习该单词的动作

### StudyPage

`StudyPage` 是主学习流程，仍然会是最复杂的页面。

它的职责包括：

- 在三种学习模式之间切换
- 恢复并缓存本地学习进度
- 管理发音或学习流状态
- 提交学习结果

当前的 `ContentView` 应被视为 `StudyPage` 的第一批抽取来源，而不是可以直接丢弃的原型页。

### WordbookPage 与 WordbookDetailPage

`WordbookPage` 展示用户的单词本列表。

`WordbookDetailPage` 包含四个内容过滤标签：

- 今日任务
- 学习中单词
- 未学单词
- 简单单词

这些标签属于详情页内部的内容过滤，不属于全局导航。

### SettingsPage

`SettingsPage` 只应包含能够立即生效的设置项：

- 通过数字输入对话框设置每日目标
- 通过开关控制通知启用状态
- 通过时间选择器设置通知时间

设置应原地保存，不要再跳转到额外的确认页。

## 状态设计

状态应拆分为两类：

- 跨页面共享的持久业务状态
- 仅作用于单页的本地 UI 状态

持久业务状态包括：

- 连续学习天数和汇总学习计数
- 最近单词
- 日历完成状态
- 单词本成员关系状态
- 搜索历史
- 已保存的偏好设置

本地 UI 状态包括：

- 当前搜索框文本
- 当前底部 sheet 是否显示
- 当前选中的日期
- 当前会话中的学习模式
- `WordDetailPage` 中释义区块的展开状态

页面负责触发动作，但不应自行计算或维持业务真相。

## 共享 Store 边界

页面层应由聚焦职责的 store 或 view model 支撑：

- `DashboardStore`：承载 `HomePage` 与 `CalendarPage` 的聚合状态
- `StudySessionStore`：承载 `StudyPage` 的学习状态与提交流程
- `WordbookStore`：承载单词本成员关系与详情页过滤列表
- `PreferencesStore`：承载每日目标与通知设置

Store 负责在写操作成功后刷新数据，让其他页面从共享事实来源更新，而不是依靠手工回调链同步。

## 跨页面写回规则

跨页面一致性应遵循一条规则：任何会改变共享真相的动作，只写一次事实来源，然后刷新受影响的 store。

例如：

- 完成一次学习动作后，更新每日记录与用户进度，然后刷新 `DashboardStore`
- 补录某个日期后，更新持久层，再刷新日历与摘要状态
- 添加自定义单词后，更新单词表和搜索历史，再刷新最近新增与相关列表
- 增减单词本成员关系后，更新 `WordbookStore`，让订阅页面自动反映变化

写操作完成后，页面不应手动修补多个兄弟 view state。

## 与现有 Schema 的映射

当前 schema 已经支持大部分所需产品模型：

- `daily_records` 支撑日历完成态与每日摘要
- `user_word_progress` 支撑学习状态分段与调度相关视图
- `search_history` 支撑 `SearchPage` 历史记录
- `user_settings` 支撑设置持久化
- `wordbooks` 与 `wordbook_words` 支撑单词本组织

当前主要欠缺的不是 schema 本身，而是面向页面的查询与聚合方法，例如：

- 最近七天完成情况摘要
- 最近新增单词列表
- 月级别日历摘要
- 按进度状态过滤的单词本详情查询

## 从当前应用迁移的策略

这次改造应按“抽取”来做，而不是按“重写”来做。

推荐迁移顺序：

1. 引入 `MainPage` 作为新根页面
2. 将当前以练习为中心的 `ContentView` 责任迁移到 `StudyPage`
3. 在迁移过程中保留当前 `PronunciationScorer` 和练习状态
4. 接入由共享 store 驱动的轻量版 `HomePage`、`CalendarPage` 和 `ProfilePage`
5. 逐步把旧页面中的直接状态拥有权替换为页面专属 store

这样能在外围产品结构逐步建立的同时，继续保留已有可工作的学习行为。

## 错误处理规则

任何共享状态写操作都应遵循一致的结果模式：

- 在发起页面显示 loading
- 将写操作提交到持久层或 API
- 成功后刷新归属 store
- 失败时恢复到可继续操作的页面状态，并展示清晰错误

具体要求：

- 补录失败时保留所选日期并允许重试
- 单词本成员变更失败时，按钮状态不能表现出错误的成功结果
- 学习结果提交失败时，应保留本地进度以供重试或后续同步

## 验证要求

后续实现的最小验证范围应包括：

1. 根导航进入三标签外壳，而不是旧的单页根视图
2. 每个标签都能保留自己的导航状态，并且 push 页面返回正确
3. 学习、搜索新增、单词本成员变更与补录写入后，共享摘要状态能够刷新
4. 从当前 `ContentView` 抽出 `StudyPage` 后，不会让现有练习行为回归错误

## 后续预期会变更的文件

- [learning/Learning/Learning/LearningApp.swift](learning/Learning/Learning/LearningApp.swift)
- [learning/Learning/Learning/ContentView.swift](learning/Learning/Learning/ContentView.swift)
- [learning/Learning/Learning/DatabaseManager.swift](learning/Learning/Learning/DatabaseManager.swift)
- 新增的 SwiftUI 页面文件：`MainPage`、`HomePage`、`CalendarPage`、`ProfilePage`、`SearchPage`、`WordDetailPage`、`StudyPage`、`WordbookPage`、`WordbookDetailPage`、`SettingsPage`
- 新增的 store 或 view model 文件：用于 dashboard、study session、wordbook 与 preferences 状态管理

## 风险与权衡

- 将 `StudyPage` 作为抽取目标可以降低重写风险，但也意味着第一阶段实现仍可能携带当前 `ContentView` 的部分旧布局或旧状态形态。
- 以 store 为中心的共享状态模型会带来少量结构性开销，但在页面变多之后，它可以避免跨页面状态更新不一致。
- 复用当前 schema 能加快交付，但页面级查询 API 需要认真设计，避免把聚合逻辑重新推回 view 层。