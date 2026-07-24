# SM-2 Progress Model Design

## Context

The current SQLite schema defines user_word_progress with a legacy progress model based on mastery_level, last_score, and last_practiced_at. The project will replace that model with a single spaced-repetition progress record built around SM-2 style scheduling.

This design assumes the current project is still in a development phase and may rebuild the user_word_progress table when an old schema is detected. Existing data in other tables must remain untouched.

## Goals

- Replace the old user_word_progress fields with the requested SM-2 core fields.
- Keep the schema compatible with SQLite types and constraints.
- Use one progress model only, rather than running legacy and SM-2 fields in parallel.
- Support lightweight adaptive scheduling without introducing a full score-based grading system.
- Rebuild only user_word_progress when an old schema is found.

## Non-Goals

- Migrating legacy user_word_progress records into the new format.
- Implementing the full review service or UI flow in the same change.
- Refactoring unrelated database tables or application layers.

## Schema Design

The user_word_progress table will keep its primary key, user_id, word_id, foreign keys, and unique constraint on (user_id, word_id). The progress payload will be replaced with the following fields:

- easiness_factor: REAL NOT NULL DEFAULT 2.5
- correct_streak: INTEGER NOT NULL DEFAULT 0
- review_count: INTEGER NOT NULL DEFAULT 0
- next_review_at: TEXT
- last_interval_days: INTEGER NOT NULL DEFAULT 0
- status: INTEGER NOT NULL DEFAULT 0
- source: TEXT NOT NULL DEFAULT 'new'
- updated_at: TEXT NOT NULL DEFAULT (datetime('now'))

SQLite storage types will be REAL, INTEGER, and TEXT. The requested decimal(3,2) and tinyint types are treated as semantic requirements, not literal SQLite column types.

### Status Semantics

- 0 = not learned
- 1 = learning
- 2 = mastered

The status column should be guarded with a CHECK constraint allowing only 0, 1, and 2.

### Source Semantics

- new
- review
- simple

The source column should be guarded with a CHECK constraint allowing only the values above.

## Review State Rules

The table represents a single source of truth for scheduling.

### Record Creation

When a user first encounters a word, create a user_word_progress record with these initial values:

- easiness_factor = 2.5
- correct_streak = 0
- review_count = 0
- next_review_at = NULL
- last_interval_days = 0
- status = 0
- source = 'new'

### First Learning and Review Writes

Each answer attempt increments review_count, including wrong answers.

Whenever a word enters a formal practice flow, source is updated to the current entry mode:

- new for first learning
- review for scheduled review
- simple for simple mode

### Correct Answer Path

When the user answers correctly:

- review_count has already been incremented for this attempt
- increment correct_streak by 1
- keep or raise status to 1
- compute the next interval in days from the current streak and easiness_factor
- store that value in last_interval_days
- set next_review_at to the current time plus the computed interval
- adjust easiness_factor upward slightly

Once correct_streak reaches 5, status becomes 2 to mark the word as mastered.

### Wrong Answer Path

When the user answers incorrectly:

- review_count has already been incremented for this attempt
- reset correct_streak to 0
- set status to 1
- set last_interval_days to 0 or the chosen immediate-repeat interval baseline
- move next_review_at to the same day or next day
- adjust easiness_factor downward, but never below 1.3

This keeps failed reviews from inheriting an over-optimistic schedule.

### Simple Mode

Simple mode is not a separate scheduling algorithm. It reuses the same streak, interval, and next_review_at logic as other review flows. Its only distinct persisted signal is source = 'simple'.

## Scheduling Guidance

The implementation should stay close to lightweight SM-2 behavior without introducing multiple answer grades. A binary correct or incorrect result is enough for this project.

Recommended behavior:

- correct answers raise easiness_factor by a small bounded amount
- wrong answers reduce easiness_factor by a small bounded amount
- easiness_factor has a hard lower bound of 1.3
- interval growth is driven by correct_streak and easiness_factor together

The exact interval formula can remain in the implementation plan, but it must preserve the meaning of the persisted fields defined here.

## Database Initialization and Rebuild Strategy

CREATE TABLE IF NOT EXISTS is not enough to replace an existing old-schema table. Initialization must explicitly detect the installed shape of user_word_progress.

### Upgrade Rule

At startup, before applying the standard create-table statements:

1. inspect the columns of user_word_progress
2. if the table matches the old schema, drop only user_word_progress
3. recreate user_word_progress using the new schema
4. recreate related indexes

Other tables such as users, words, daily_records, and user_settings must not be rebuilt as part of this change.

### Schema Versioning

The database should use PRAGMA user_version to make this upgrade explicit.

- version 1 = legacy schema
- version 2 = SM-2 progress schema

If user_version is less than 2, initialization upgrades the schema by rebuilding user_word_progress and then sets user_version to 2.

## Validation Requirements

The minimum verification scope for this design is:

1. a fresh database initializes user_word_progress with the expected columns, defaults, and constraints
2. a legacy database is upgraded so that user_word_progress matches the new schema after initializeDatabase runs

These checks are sufficient for the schema change itself. Full review-flow testing can be planned separately.

## Files Expected To Change Later

- Learning/Learning/Learning/DatabaseManager.swift for schema definition and upgrade logic
- test files to validate fresh initialization and old-schema rebuild behavior

## Risks and Tradeoffs

- Rebuilding user_word_progress discards existing progress rows in that table, which is accepted for this development-phase change.
- Introducing a version gate now adds a small amount of setup logic, but it prevents future schema changes from relying on implicit detection only.
- Using a binary correct or incorrect review result simplifies the model and leaves less room for nuanced scheduling, but matches the current product scope.