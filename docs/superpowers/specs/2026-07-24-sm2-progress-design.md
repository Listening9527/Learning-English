# SM-2 进度模型设计

## 背景

当前 SQLite schema 中的 `user_word_progress` 使用的是旧版进度模型，核心字段是 `mastery_level`、`last_score` 和 `last_practiced_at`。本项目将把它替换为单一的间隔重复进度记录，围绕 SM-2 风格的调度方式组织。

这个设计假设当前项目仍处于开发阶段，因此在检测到旧 schema 时，可以重建 `user_word_progress` 表；其他表中的已有数据必须保持不变。

## 目标

- 用请求中的 SM-2 核心字段替换旧版 `user_word_progress` 字段。
- 保持 schema 与 SQLite 类型和约束兼容。
- 只保留一种进度模型，而不是让旧字段与 SM-2 字段并存。
- 支持轻量级自适应调度，但不引入完整的分档评分体系。
- 仅在发现旧 schema 时重建 `user_word_progress`。

## 非目标

- 将旧版 `user_word_progress` 记录迁移到新格式。
- 在同一次改动里实现完整的复习服务或 UI 流程。
- 重构与本次任务无关的数据库表或应用层。

## Schema 设计

`user_word_progress` 表保留主键、`user_id`、`word_id`、外键以及 `(user_id, word_id)` 上的唯一约束。进度负载替换为以下字段：

- `easiness_factor`: REAL NOT NULL DEFAULT 2.5
- `correct_streak`: INTEGER NOT NULL DEFAULT 0
- `review_count`: INTEGER NOT NULL DEFAULT 0
- `next_review_at`: TEXT
- `last_interval_days`: INTEGER NOT NULL DEFAULT 0
- `status`: INTEGER NOT NULL DEFAULT 0
- `source`: TEXT NOT NULL DEFAULT 'new'
- `updated_at`: TEXT NOT NULL DEFAULT (datetime('now'))

SQLite 的存储类型使用 REAL、INTEGER 和 TEXT。需求中提到的 `decimal(3,2)` 和 `tinyint` 视为语义要求，而不是 SQLite 中必须逐字使用的列类型。

### 状态语义

- `0` = 未学习
- `1` = 学习中
- `2` = 已掌握

`status` 列应通过 `CHECK` 约束限制为仅允许 `0`、`1`、`2`。

### 来源语义

- `new`
- `review`
- `simple`

`source` 列应通过 `CHECK` 约束限制为仅允许上述值。

## 复习状态规则

这张表是调度状态的单一事实来源。

### 记录创建

当用户第一次遇到某个单词时，创建一条 `user_word_progress` 记录，并使用以下初始值：

- `easiness_factor = 2.5`
- `correct_streak = 0`
- `review_count = 0`
- `next_review_at = NULL`
- `last_interval_days = 0`
- `status = 0`
- `source = 'new'`

### 首次学习与复习写入

每次作答都会递增 `review_count`，包括答错的情况。

当单词进入正式练习流程时，`source` 更新为当前入口模式：

- 首次学习使用 `new`
- 计划复习使用 `review`
- 简单模式使用 `simple`

### 答对路径

当用户回答正确时：

- 本次作答的 `review_count` 已经先行递增
- `correct_streak` 加 1
- `status` 保持或提升为 `1`
- 根据当前 `correct_streak` 和 `easiness_factor` 计算下一次间隔天数
- 将该值写入 `last_interval_days`
- 将 `next_review_at` 设为当前时间加上计算出的间隔
- 略微上调 `easiness_factor`

当 `correct_streak` 达到 `5` 时，`status` 变为 `2`，表示该词已掌握。

### 答错路径

当用户回答错误时：

- 本次作答的 `review_count` 已经先行递增
- 将 `correct_streak` 重置为 `0`
- 将 `status` 设为 `1`
- 将 `last_interval_days` 设为 `0`，或设为所选的即时重复基线间隔
- 将 `next_review_at` 推到当天稍后或次日
- 下调 `easiness_factor`，但不得低于 `1.3`

这样可以避免失败复习继承过于乐观的调度结果。

### 简单模式

简单模式不是一套独立的调度算法。它沿用与其他复习流程相同的 streak、interval 和 `next_review_at` 逻辑；唯一单独落库的标记是 `source = 'simple'`。

## 调度指导

实现应尽量贴近轻量级 SM-2 行为，但不要引入多档答案评分。对于本项目，二元的“正确 / 错误”结果已经足够。

建议行为：

- 答对时对 `easiness_factor` 做小幅且有上界的提升
- 答错时对 `easiness_factor` 做小幅下降
- `easiness_factor` 的硬下限为 `1.3`
- 间隔增长由 `correct_streak` 和 `easiness_factor` 共同驱动

具体的间隔公式可以放到实现计划里确定，但必须保持这里定义的持久化字段含义不变。

## 数据库初始化与重建策略

仅靠 `CREATE TABLE IF NOT EXISTS` 不足以替换已存在的旧 schema 表。初始化过程必须显式检测当前安装的 `user_word_progress` 表结构。

### 升级规则

在启动时、执行常规 `create-table` 语句之前：

1. 检查 `user_word_progress` 的列定义
2. 如果该表仍是旧 schema，则仅删除 `user_word_progress`
3. 使用新 schema 重新创建 `user_word_progress`
4. 重新创建相关索引

`users`、`words`、`daily_records`、`user_settings` 等其他表不得因为这次改动被一并重建。

### Schema 版本控制

数据库应使用 `PRAGMA user_version` 来显式表示这次升级。

- `version 1` = 旧版 schema
- `version 2` = SM-2 进度 schema

如果 `user_version` 小于 `2`，初始化流程应通过重建 `user_word_progress` 完成升级，并在结束后将 `user_version` 设为 `2`。

## 验证要求

本设计的最小验证范围为：

1. 新数据库初始化后，`user_word_progress` 具有预期的列、默认值和约束
2. 旧数据库在执行 `initializeDatabase` 后，`user_word_progress` 会被升级为新 schema

对于这次 schema 变更，这两项检查已经足够；完整的复习流程测试可以单独规划。

## 后续预期会变更的文件

- `Learning/Learning/Learning/DatabaseManager.swift`，用于 schema 定义和升级逻辑
- 用于验证全新初始化和旧 schema 重建行为的测试文件

## 风险与权衡

- 重建 `user_word_progress` 会丢弃该表中的历史进度记录；在当前开发阶段，这个代价是可接受的。
- 现在就引入版本门槛会增加少量初始化逻辑，但可以避免后续 schema 变更继续依赖隐式检测。
- 使用二元“正确 / 错误”结果简化了模型，牺牲了一部分细腻调度能力，但符合当前产品范围。