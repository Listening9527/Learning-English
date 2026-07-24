# Task 5 Review Package

## Status
?? Learning/Learning/CalendarPage.swift
?? Learning/Learning/DashboardStore.swift
?? Learning/Learning/DatabaseManager.swift
?? Learning/Learning/MainPage.swift
?? Learning/Learning/PageModels.swift
?? Learning/LearningTests/DatabaseManagerPageQueryTests.swift

## Current File: Learning/Learning/CalendarPage.swift
import SwiftUI

struct CalendarPage: View {
    @ObservedObject var dashboardStore: DashboardStore

    @State private var displayedMonth = calendarUTC.startOfDay(for: Date())
    @State private var selectedBackfillDate = calendarUTC.startOfDay(for: Date())
    @State private var dailySummaries: [DailyCompletionSummary] = []
    @State private var isShowingBackfillSheet = false
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    monthSummaryGrid
                }
                .padding()
            }
            .navigationTitle("日历")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("补录") {
                        selectedBackfillDate = calendarUTC.startOfDay(for: displayedMonth)
                        isShowingBackfillSheet = true
                    }
                }
            }
            .task(id: monthAnchorID) {
                await loadMonthlySummary()
            }
            .sheet(isPresented: $isShowingBackfillSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        DatePicker(
                            "选择补录日期",
                            selection: $selectedBackfillDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)

                        Button("确认补录") {
                            Task {
                                await confirmBackfill()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("补录练习")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("取消") {
                                isShowingBackfillSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .alert("操作失败", isPresented: errorAlertBinding) {
                Button("知道了", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthTitle)
                .font(.title2.weight(.semibold))
            Text("本月已完成 \(completedDateKeys.count) 天练习")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthSummaryGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(calendarCells.indices, id: \.self) { index in
                let cell = calendarCells[index]

                Group {
                    if let day = cell {
                        VStack(spacing: 6) {
                            Text(dayLabel(for: day))
                                .font(.headline)
                            Circle()
                                .fill(completedDateKeys.contains(dateKey(for: day)) ? Color.green : Color.gray.opacity(0.25))
                                .frame(width: 10, height: 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Color.clear
                            .frame(height: 58)
                    }
                }
            }
        }
    }

    private var completedDateKeys: Set<String> {
        Set(dailySummaries.filter(\.practiced).map(\.dateKey))
    }

    private var monthAnchorID: String {
        dateKey(for: displayedMonth)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendarUTC
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendarUTC.timeZone
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var calendarCells: [Date?] {
        let monthDays = daysInMonth(for: displayedMonth)
        guard let firstDay = monthDays.first else {
            return []
        }

        let weekday = calendarUTC.component(.weekday, from: firstDay)
        let leadingEmptyCells = max(0, weekday - calendarUTC.firstWeekday)
        return Array(repeating: nil, count: leadingEmptyCells) + monthDays.map { Optional($0) }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func loadMonthlySummary() async {
        do {
            dailySummaries = try DatabaseManager.shared.fetchMonthlyCompletionSummary(for: displayedMonth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmBackfill() async {
        do {
            displayedMonth = selectedBackfillDate
            try DatabaseManager.shared.backfillPractice(on: selectedBackfillDate)
            dailySummaries = try DatabaseManager.shared.fetchMonthlyCompletionSummary(for: displayedMonth)
            await dashboardStore.refresh()
            isShowingBackfillSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func daysInMonth(for date: Date) -> [Date] {
        let components = calendarUTC.dateComponents([.year, .month], from: date)
        guard
            let monthStart = calendarUTC.date(from: components),
            let dayRange = calendarUTC.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        return dayRange.compactMap { day in
            calendarUTC.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private func dayLabel(for date: Date) -> String {
        String(calendarUTC.component(.day, from: date))
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendarUTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendarUTC.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private let calendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}()
## Current File: Learning/Learning/DatabaseManager.swift
import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let databaseCalendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}()
private let canonicalSelectionCalendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    return calendar
}()

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let fileName = "learning.sqlite3"

    private init() {}

    func initializeDatabase() {
        guard openDatabase() else {
            print("[DB] Failed to open database")
            return
        }

        execute("PRAGMA foreign_keys = ON;")

        for statement in createTableStatements {
            execute(statement)
        }

        migrateUserWordProgressSchemaIfNeeded()
        migrateWordsSchemaIfNeeded()

        for statement in createIndexStatements {
            execute(statement)
        }

        for statement in createTriggerStatements {
            execute(statement)
        }
    }

    private func openDatabase() -> Bool {
        if db != nil {
            return true
        }

        do {
            let dbURL = try databaseURL()
            var handle: OpaquePointer?
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
            let result = sqlite3_open_v2(dbURL.path, &handle, flags, nil)

            if result != SQLITE_OK {
                if let handle {
                    let message = String(cString: sqlite3_errmsg(handle))
                    print("[DB] Open error: \(message)")
                }
                sqlite3_close(handle)
                return false
            }

            db = handle
            return true
        } catch {
            print("[DB] Path error: \(error)")
            return false
        }
    }

    private func databaseURL() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appSupport = baseURL.appendingPathComponent("Learning", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(fileName)
    }

    private func execute(_ sql: String) {
        guard let db else {
            return
        }

        let result = sqlite3_exec(db, sql, nil, nil, nil)
        if result != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(db))
            print("[DB] SQL error: \(message)\nSQL: \(sql)")
        }
    }

    private struct ColumnInfo {
        let name: String
        let type: String
    }

    private func tableColumns(_ tableName: String) -> [ColumnInfo] {
        guard let db else {
            return []
        }

        let sql = "PRAGMA table_info(\(tableName));"
        var statement: OpaquePointer?
        var columns: [ColumnInfo] = []

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let nameCStr = sqlite3_column_text(statement, 1) else {
                continue
            }

            let typeCStr = sqlite3_column_text(statement, 2)
            let name = String(cString: nameCStr)
            let type = typeCStr.map { String(cString: $0) } ?? ""
            columns.append(ColumnInfo(name: name, type: type.uppercased()))
        }

        return columns
    }

    private func addColumnIfMissing(tableName: String, columnName: String, definition: String) {
        let existing = tableColumns(tableName)
        let hasColumn = existing.contains { $0.name == columnName }
        guard !hasColumn else {
            return
        }

        execute("ALTER TABLE \(tableName) ADD COLUMN \(columnName) \(definition);")
    }

    private func migrateUserWordProgressSchemaIfNeeded() {
        let columns = tableColumns("user_word_progress")
        guard !columns.isEmpty else {
            return
        }

        let statusType = columns.first(where: { $0.name == "status" })?.type ?? ""
        if statusType.contains("TEXT") {
            migrateUserWordProgressStatusTextToInt(columns: columns)
        }

        addColumnIfMissing(
            tableName: "user_word_progress",
            columnName: "easiness_factor",
            definition: "REAL NOT NULL DEFAULT 2.50"
        )
        addColumnIfMissing(
            tableName: "user_word_progress",
            columnName: "correct_streak",
            definition: "INTEGER NOT NULL DEFAULT 0"
        )
        addColumnIfMissing(
            tableName: "user_word_progress",
            columnName: "review_count",
            definition: "INTEGER NOT NULL DEFAULT 0"
        )
        addColumnIfMissing(
            tableName: "user_word_progress",
            columnName: "last_interval_days",
            definition: "INTEGER NOT NULL DEFAULT 0"
        )
        addColumnIfMissing(
            tableName: "user_word_progress",
            columnName: "source",
            definition: "TEXT NOT NULL DEFAULT 'new' CHECK (source IN ('new', 'review', 'simple'))"
        )
    }

    private func migrateUserWordProgressStatusTextToInt(columns: [ColumnInfo]) {
        let hasColumn: (String) -> Bool = { name in
            columns.contains { $0.name == name }
        }

        let nextReviewExpr = hasColumn("next_review_at") ? "next_review_at" : "NULL"
        let masteryExpr = hasColumn("mastery_level") ? "mastery_level" : "0"
        let updatedAtExpr = hasColumn("updated_at") ? "updated_at" : "datetime('now')"

        execute("BEGIN TRANSACTION;")
        execute(
            """
            CREATE TABLE IF NOT EXISTS user_word_progress_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                word_id INTEGER NOT NULL,
                status INTEGER NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
                source TEXT NOT NULL DEFAULT 'new' CHECK (source IN ('new', 'review', 'simple')),
                easiness_factor REAL NOT NULL DEFAULT 2.50,
                correct_streak INTEGER NOT NULL DEFAULT 0,
                review_count INTEGER NOT NULL DEFAULT 0,
                mastery_level INTEGER NOT NULL DEFAULT 0,
                last_score INTEGER,
                last_practiced_at TEXT,
                next_review_at TEXT,
                last_interval_days INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE (user_id, word_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );
            """
        )
        execute(
            """
            INSERT INTO user_word_progress_new (
                id,
                user_id,
                word_id,
                status,
                source,
                easiness_factor,
                correct_streak,
                review_count,
                mastery_level,
                last_score,
                last_practiced_at,
                next_review_at,
                last_interval_days,
                updated_at
            )
            SELECT
                id,
                user_id,
                word_id,
                CASE
                    WHEN LOWER(status) IN ('mastered', 'done') THEN 2
                    WHEN LOWER(status) IN ('learning', 'reviewing', 'in_progress') THEN 1
                    ELSE 0
                END AS status,
                'new' AS source,
                2.50 AS easiness_factor,
                0 AS correct_streak,
                0 AS review_count,
                \(masteryExpr) AS mastery_level,
                last_score,
                last_practiced_at,
                \(nextReviewExpr) AS next_review_at,
                0 AS last_interval_days,
                \(updatedAtExpr) AS updated_at
            FROM user_word_progress;
            """
        )
        execute("DROP TABLE user_word_progress;")
        execute("ALTER TABLE user_word_progress_new RENAME TO user_word_progress;")
        execute("COMMIT;")
    }

    private func uniqueIndexColumns(tableName: String) -> [[String]] {
        guard let db else {
            return []
        }

        let indexListSQL = "PRAGMA index_list(\(tableName));"
        var listStatement: OpaquePointer?
        var uniqueIndexes: [String] = []

        guard sqlite3_prepare_v2(db, indexListSQL, -1, &listStatement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(listStatement) }

        while sqlite3_step(listStatement) == SQLITE_ROW {
            let isUnique = sqlite3_column_int(listStatement, 2) == 1
            guard isUnique, let indexNameCStr = sqlite3_column_text(listStatement, 1) else {
                continue
            }
            uniqueIndexes.append(String(cString: indexNameCStr))
        }

        var allColumns: [[String]] = []
        for indexName in uniqueIndexes {
            let indexInfoSQL = "PRAGMA index_info(\(indexName));"
            var infoStatement: OpaquePointer?
            var columns: [String] = []

            guard sqlite3_prepare_v2(db, indexInfoSQL, -1, &infoStatement, nil) == SQLITE_OK else {
                continue
            }

            while sqlite3_step(infoStatement) == SQLITE_ROW {
                guard let columnNameCStr = sqlite3_column_text(infoStatement, 2) else {
                    continue
                }
                columns.append(String(cString: columnNameCStr))
            }
            sqlite3_finalize(infoStatement)

            allColumns.append(columns)
        }

        return allColumns
    }

    private func migrateWordsSchemaIfNeeded() {
        let columns = tableColumns("words")
        guard !columns.isEmpty else {
            return
        }

        let names = Set(columns.map { $0.name })
        let requiredNames: Set<String> = [
            "id",
            "word",
            "phonetic",
            "pos",
            "definition",
            "example",
            "audio_url",
            "type",
            "is_custom",
            "created_at",
            "updated_at"
        ]

        let missingRequired = !requiredNames.isSubset(of: names)
        let hasLegacyMeaning = names.contains("meaning")
        let hasLegacyUniqueWord = uniqueIndexColumns(tableName: "words")
            .contains(where: { $0.count == 1 && $0.first == "word" })

        guard missingRequired || hasLegacyMeaning || hasLegacyUniqueWord else {
            return
        }

        let hasColumn: (String) -> Bool = { name in
            names.contains(name)
        }

        let posExpr = hasColumn("pos") ? "pos" : "NULL"
        let definitionExpr: String = {
            if hasColumn("definition") {
                return "definition"
            }
            if hasColumn("meaning") {
                return "COALESCE(meaning, '')"
            }
            return "''"
        }()
        let exampleExpr = hasColumn("example") ? "example" : "NULL"
        let audioURLExpr = hasColumn("audio_url") ? "audio_url" : "NULL"
        let typeExpr = hasColumn("type")
            ? "CASE WHEN type IN ('word', 'phrase', 'pattern') THEN type ELSE 'word' END"
            : "'word'"
        let isCustomExpr = hasColumn("is_custom")
            ? "CASE WHEN is_custom IN (0, 1) THEN is_custom ELSE 0 END"
            : "0"
        let createdAtExpr = hasColumn("created_at") ? "created_at" : "datetime('now')"
        let updatedAtExpr = hasColumn("updated_at") ? "updated_at" : "datetime('now')"

        execute("BEGIN TRANSACTION;")
        execute(
            """
            CREATE TABLE IF NOT EXISTS words_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT NOT NULL,
                phonetic TEXT,
                pos TEXT,
                definition TEXT NOT NULL,
                example TEXT,
                audio_url TEXT,
                type TEXT NOT NULL DEFAULT 'word' CHECK (type IN ('word', 'phrase', 'pattern')),
                is_custom INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1)),
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            """
        )
        execute(
            """
            INSERT INTO words_new (
                id,
                word,
                phonetic,
                pos,
                definition,
                example,
                audio_url,
                type,
                is_custom,
                created_at,
                updated_at
            )
            SELECT
                id,
                word,
                phonetic,
                \(posExpr) AS pos,
                \(definitionExpr) AS definition,
                \(exampleExpr) AS example,
                \(audioURLExpr) AS audio_url,
                \(typeExpr) AS type,
                \(isCustomExpr) AS is_custom,
                \(createdAtExpr) AS created_at,
                \(updatedAtExpr) AS updated_at
            FROM words;
            """
        )
        execute("DROP TABLE words;")
        execute("ALTER TABLE words_new RENAME TO words;")
        execute("COMMIT;")
    }

    private var createTableStatements: [String] {
        [
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                display_name TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS wordbooks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                owner_user_id INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT NOT NULL,
                phonetic TEXT,
                pos TEXT,
                definition TEXT NOT NULL,
                example TEXT,
                audio_url TEXT,
                type TEXT NOT NULL DEFAULT 'word' CHECK (type IN ('word', 'phrase', 'pattern')),
                is_custom INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1)),
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS wordbook_words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                wordbook_id INTEGER NOT NULL,
                word_id INTEGER NOT NULL,
                added_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE (wordbook_id, word_id),
                FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS user_word_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                word_id INTEGER NOT NULL,
                status INTEGER NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
                source TEXT NOT NULL DEFAULT 'new' CHECK (source IN ('new', 'review', 'simple')),
                easiness_factor REAL NOT NULL DEFAULT 2.50,
                correct_streak INTEGER NOT NULL DEFAULT 0,
                review_count INTEGER NOT NULL DEFAULT 0,
                mastery_level INTEGER NOT NULL DEFAULT 0,
                last_score INTEGER,
                last_practiced_at TEXT,
                next_review_at TEXT,
                last_interval_days INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE (user_id, word_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS daily_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                word_id INTEGER NOT NULL,
                practiced INTEGER NOT NULL DEFAULT 0 CHECK (practiced IN (0, 1)),
                score INTEGER,
                duration_ms INTEGER,
                practiced_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS user_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL UNIQUE,
                preferred_accent TEXT NOT NULL DEFAULT 'american',
                slow_mode INTEGER NOT NULL DEFAULT 0 CHECK (slow_mode IN (0, 1)),
                auto_replay_low_score INTEGER NOT NULL DEFAULT 1 CHECK (auto_replay_low_score IN (0, 1)),
                replay_threshold INTEGER NOT NULL DEFAULT 85,
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS search_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                query TEXT NOT NULL,
                source TEXT,
                searched_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
            );
            """
        ]
    }

    private var createIndexStatements: [String] {
        [
            "CREATE UNIQUE INDEX IF NOT EXISTS uk_word_pos ON words(word, pos);",
            "CREATE INDEX IF NOT EXISTS idx_word ON words(word);",
            "CREATE INDEX IF NOT EXISTS idx_wordbook_words_wordbook_id ON wordbook_words(wordbook_id);",
            "CREATE INDEX IF NOT EXISTS idx_wordbook_words_word_id ON wordbook_words(word_id);",
            "CREATE INDEX IF NOT EXISTS idx_user_word_progress_user_word ON user_word_progress(user_id, word_id);",
            "CREATE INDEX IF NOT EXISTS idx_daily_records_user_practiced_at ON daily_records(user_id, practiced_at);",
            "CREATE INDEX IF NOT EXISTS idx_search_history_user_searched_at ON search_history(user_id, searched_at);"
        ]
    }

    private var createTriggerStatements: [String] {
        [
            """
            CREATE TRIGGER IF NOT EXISTS trg_words_updated_at
            AFTER UPDATE ON words
            FOR EACH ROW
            WHEN NEW.updated_at = OLD.updated_at
            BEGIN
                UPDATE words
                SET updated_at = strftime('%Y-%m-%d %H:%M:%f', 'now')
                WHERE id = NEW.id;
            END;
            """
        ]
    }
}

extension DatabaseManager {
    func insertWordForTesting(
        word: String,
        phonetic: String,
        partOfSpeech: String,
        definition: String,
        createdAt: String
    ) throws -> Int64 {
        initializeDatabase()

        let sql =
            """
            INSERT INTO words (word, phonetic, pos, definition, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?);
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(word, to: statement, index: 1)
        try bindText(phonetic, to: statement, index: 2)
        try bindText(partOfSpeech, to: statement, index: 3)
        try bindText(definition, to: statement, index: 4)
        try bindText(createdAt, to: statement, index: 5)
        try bindText(createdAt, to: statement, index: 6)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to insert testing word")
        }

        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        return sqlite3_last_insert_rowid(db)
    }

    func resetTestingFixturesForTesting() throws {
        initializeDatabase()
        try resetTestingFixtures()
    }

    func fetchRecentWordSummaries(limit: Int) throws -> [RecentWordSummary] {
        initializeDatabase()

        let sql =
            """
            SELECT id, word, phonetic, pos, definition, created_at
            FROM words
            ORDER BY created_at DESC, id DESC
            LIMIT ?;
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind recent words limit")
        }

        var words: [RecentWordSummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let word = stringValue(from: statement, index: 1) ?? ""
            let phonetic = stringValue(from: statement, index: 2)
            let partOfSpeech = stringValue(from: statement, index: 3)
            let definition = stringValue(from: statement, index: 4) ?? ""
            let createdAt = stringValue(from: statement, index: 5) ?? ""

            words.append(
                RecentWordSummary(
                    id: id,
                    word: word,
                    phonetic: phonetic,
                    partOfSpeech: partOfSpeech,
                    definition: definition,
                    createdAt: createdAt
                )
            )
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch recent words")
        }

        return words
    }

    func fetchDashboardSummary() throws -> DashboardSummary {
        initializeDatabase()

        let totalWordCount = try fetchCount(
            sql: "SELECT COUNT(*) FROM words;"
        )
        let masteredWordCount = try fetchCount(
            sql: "SELECT COUNT(*) FROM user_word_progress WHERE status = 2;"
        )
        let recentWords = try fetchRecentWordSummaries(limit: 5)
        let weeklyCheckIns = try fetchWeeklyCheckInDays(limit: 7)

        return DashboardSummary(
            weeklyCheckIns: weeklyCheckIns,
            recentWords: recentWords,
            totalWordCount: totalWordCount,
            masteredWordCount: masteredWordCount
        )
    }

    func fetchMonthlyCompletionSummary(for month: Date) throws -> [DailyCompletionSummary] {
        initializeDatabase()

        let canonicalMonth = canonicalSelectionDate(for: month)
        let monthStart = try monthRange(for: canonicalMonth).start
        guard let monthEnd = databaseCalendarUTC.date(byAdding: .month, value: 1, to: monthStart) else {
            throw databaseError(message: "Failed to compute month range")
        }

        let sql =
            """
            SELECT DATE(practiced_at) AS date_key, MAX(practiced) AS practiced
            FROM daily_records
            WHERE DATE(practiced_at) >= ? AND DATE(practiced_at) < ?
            GROUP BY DATE(practiced_at)
            ORDER BY date_key ASC;
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(dateKey(for: monthStart), to: statement, index: 1)
        try bindText(dateKey(for: monthEnd), to: statement, index: 2)

        var summaries: [DailyCompletionSummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let dateKey = stringValue(from: statement, index: 0) else {
                continue
            }

            summaries.append(
                DailyCompletionSummary(
                    dateKey: dateKey,
                    practiced: sqlite3_column_int(statement, 1) != 0
                )
            )
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch monthly completion summary")
        }

        return summaries
    }

    func backfillPractice(on day: Date) throws {
        initializeDatabase()

        let userID = try ensureBackfillUserID()
        let wordID = try ensureBackfillWordID()
        let practicedAt = timestamp(for: canonicalSelectionDate(for: day))

        let sql =
            """
            INSERT INTO daily_records (user_id, word_id, practiced, practiced_at)
            VALUES (?, ?, 1, ?);
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, userID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind backfill user id")
        }
        guard sqlite3_bind_int64(statement, 2, wordID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind backfill word id")
        }
        try bindText(practicedAt, to: statement, index: 3)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to backfill practice record")
        }
    }

    private func fetchWeeklyCheckInDays(limit: Int) throws -> [WeeklyCheckInDay] {
        let sql =
            """
            SELECT DATE(practiced_at) AS practiced_day, MAX(practiced) AS practiced
            FROM daily_records
            GROUP BY DATE(practiced_at)
            ORDER BY practiced_day DESC
            LIMIT ?;
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind weekly check-in limit")
        }

        var days: [WeeklyCheckInDay] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let date = stringValue(from: statement, index: 0) else {
                continue
            }

            days.append(
                WeeklyCheckInDay(
                    date: date,
                    practiced: sqlite3_column_int(statement, 1) != 0
                )
            )
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch weekly check-ins")
        }

        return days.reversed()
    }

    private func fetchCount(sql: String) throws -> Int {
        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw databaseError(message: "Failed to fetch count")
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    private func ensureBackfillUserID() throws -> Int64 {
        if let existingUserID = try fetchOptionalInt64(sql: "SELECT id FROM users ORDER BY id ASC LIMIT 1;") {
            return existingUserID
        }

        let sql =
            """
            INSERT INTO users (username, display_name)
            VALUES (?, ?);
            """

        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText("calendar-backfill-user", to: statement, index: 1)
        try bindText("Calendar Backfill", to: statement, index: 2)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to create backfill user")
        }

        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        return sqlite3_last_insert_rowid(db)
    }

    private func ensureBackfillWordID() throws -> Int64 {
        if let existingWordID = try fetchOptionalInt64(sql: "SELECT id FROM words ORDER BY id ASC LIMIT 1;") {
            return existingWordID
        }

        let sql =
            """
            INSERT INTO words (word, phonetic, pos, definition, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?);
            """

        let createdAt = timestamp(for: Date(timeIntervalSince1970: 0))
        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText("calendar-backfill-placeholder", to: statement, index: 1)
        try bindText("/ˈkælənˌdɑr/", to: statement, index: 2)
        try bindText("noun", to: statement, index: 3)
        try bindText("Placeholder word used for calendar backfill records.", to: statement, index: 4)
        try bindText(createdAt, to: statement, index: 5)
        try bindText(createdAt, to: statement, index: 6)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to create backfill word")
        }

        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        return sqlite3_last_insert_rowid(db)
    }

    private func fetchOptionalInt64(sql: String) throws -> Int64? {
        var statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        let stepResult = sqlite3_step(statement)
        if stepResult == SQLITE_ROW {
            return sqlite3_column_int64(statement, 0)
        }
        if stepResult == SQLITE_DONE {
            return nil
        }

        throw databaseError(message: "Failed to fetch row id")
    }

    private func monthRange(for date: Date) throws -> DateInterval {
        let components = databaseCalendarUTC.dateComponents([.year, .month], from: date)
        guard let monthStart = databaseCalendarUTC.date(from: components) else {
            throw databaseError(message: "Failed to compute month start")
        }

        guard let monthEnd = databaseCalendarUTC.date(byAdding: .month, value: 1, to: monthStart) else {
            throw databaseError(message: "Failed to compute month end")
        }

        return DateInterval(start: monthStart, end: monthEnd)
    }

    private func canonicalSelectionDate(for date: Date) -> Date {
        let utcComponents = canonicalSelectionCalendarUTC.dateComponents([.year, .month, .day], from: date)
        let utcMidnight = canonicalSelectionCalendarUTC.date(from: utcComponents) ?? date
        let nextUTCDay = canonicalSelectionCalendarUTC.date(byAdding: .day, value: 1, to: utcMidnight) ?? utcMidnight
        return databaseCalendarUTC.startOfDay(for: nextUTCDay)
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = databaseCalendarUTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = databaseCalendarUTC.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func timestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = databaseCalendarUTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = databaseCalendarUTC.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let dayStart = databaseCalendarUTC.startOfDay(for: date)
        let stableTime = databaseCalendarUTC.date(byAdding: .hour, value: 12, to: dayStart) ?? date
        return formatter.string(from: stableTime)
    }

    private func resetTestingFixtures() throws {
        guard isRunningTests else {
            return
        }

        let statements = [
            "DELETE FROM daily_records;",
            "DELETE FROM user_word_progress;",
            "DELETE FROM wordbook_words;",
            "DELETE FROM users;",
            "DELETE FROM words;",
            "DELETE FROM sqlite_sequence WHERE name IN ('daily_records', 'user_word_progress', 'wordbook_words', 'users', 'words');"
        ]

        for sql in statements {
            try executeThrowing(sql)
        }
    }

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private func executeThrowing(_ sql: String) throws {
        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw databaseError(message: "SQL execution failed")
        }
    }

    private func prepareStatement(_ sql: String) throws -> OpaquePointer? {
        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw databaseError(message: "Failed to prepare SQL statement")
        }

        return statement
    }

    private func bindText(_ value: String, to statement: OpaquePointer?, index: Int32) throws {
        guard sqlite3_bind_text(statement, index, value, -1, sqliteTransient) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind SQL text value")
        }
    }

    private func stringValue(from statement: OpaquePointer?, index: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, index) else {
            return nil
        }

        return String(cString: value)
    }

    private func databaseError(message: String) -> NSError {
        let description: String
        if let db {
            description = String(cString: sqlite3_errmsg(db))
        } else {
            description = message
        }

        return NSError(
            domain: "DatabaseManager",
            code: Int(sqlite3_errcode(db)),
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
## Current File: Learning/Learning/DashboardStore.swift
import Combine
import Foundation

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var summary: DashboardSummary = .empty

    func refresh() async {
        do {
            summary = try DatabaseManager.shared.fetchDashboardSummary()
        } catch {
            summary = .empty
        }
    }

    func reload() async {
        await refresh()
    }
}
## Current File: Learning/Learning/MainPage.swift
import SwiftUI

enum MainTab: String, CaseIterable, Hashable {
    case home
    case calendar
    case profile
}

struct MainPage: View {
    static let defaultTab: MainTab = .home

    static let tabTitles: [String] = ["首页", "日历", "我的"]

    @State private var selectedTab: MainTab = Self.defaultTab
    @StateObject private var dashboardStore = DashboardStore()
    @StateObject private var preferencesStore = PreferencesStore()
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomePage(dashboardStore: dashboardStore, scorer: scorer)
            .tabItem {
                Label(Self.tabTitles[0], systemImage: "house.fill")
            }
            .tag(MainTab.home)

            CalendarPage(dashboardStore: dashboardStore)
            .tabItem {
                Label(Self.tabTitles[1], systemImage: "calendar")
            }
            .tag(MainTab.calendar)

            ProfilePage(preferencesStore: preferencesStore)
            .tabItem {
                Label(Self.tabTitles[2], systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
    }
}
## Current File: Learning/Learning/PageModels.swift
import Foundation

struct WeeklyCheckInDay: Identifiable, Equatable {
    let date: String
    let practiced: Bool

    var id: String { date }
}

struct DailyCompletionSummary: Identifiable, Equatable {
    let dateKey: String
    let practiced: Bool

    var id: String { dateKey }
}

struct RecentWordSummary: Identifiable, Equatable {
    let id: Int64
    let word: String
    let phonetic: String?
    let partOfSpeech: String?
    let definition: String
    let createdAt: String
}

struct DashboardSummary: Equatable {
    let weeklyCheckIns: [WeeklyCheckInDay]
    let recentWords: [RecentWordSummary]
    let totalWordCount: Int
    let masteredWordCount: Int

    static let empty = DashboardSummary(
        weeklyCheckIns: [],
        recentWords: [],
        totalWordCount: 0,
        masteredWordCount: 0
    )
}
## Current File: Learning/LearningTests/DatabaseManagerPageQueryTests.swift
import XCTest
@testable import Learning

final class DatabaseManagerPageQueryTests: XCTestCase {
    func test_recentWordsQuery_returns_latest_words_first() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        _ = try database.insertWordForTesting(
            word: "alpha",
            phonetic: "/a/",
            partOfSpeech: "noun",
            definition: "first",
            createdAt: "2026-07-20 10:00:00"
        )
        _ = try database.insertWordForTesting(
            word: "beta",
            phonetic: "/b/",
            partOfSpeech: "noun",
            definition: "second",
            createdAt: "2026-07-21 10:00:00"
        )

        let words = try database.fetchRecentWordSummaries(limit: 3)

        XCTAssertEqual(words.prefix(2).map(\.word), ["beta", "alpha"])
    }

    func test_recentWordsQuery_uses_id_desc_when_createdAt_matches() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let firstID = try database.insertWordForTesting(
            word: "orbit",
            phonetic: "/ˈɔːrbɪt/",
            partOfSpeech: "noun",
            definition: "path around an object",
            createdAt: "2026-07-21 10:00:00"
        )
        let secondID = try database.insertWordForTesting(
            word: "radar",
            phonetic: "/ˈreɪdɑːr/",
            partOfSpeech: "noun",
            definition: "radio detection system",
            createdAt: "2026-07-21 10:00:00"
        )

        XCTAssertEqual(firstID, 1)
        XCTAssertEqual(secondID, 2)

        let words = try database.fetchRecentWordSummaries(limit: 2)

        XCTAssertEqual(words.map(\.word), ["radar", "orbit"])
    }

    func test_backfillPractice_creates_completion_for_selected_day() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        let day = Date(timeIntervalSince1970: 1_722_384_000)

        try database.backfillPractice(on: day)

        let summary = try database.fetchMonthlyCompletionSummary(for: day)
        XCTAssertTrue(summary.contains(where: { $0.dateKey == "2024-08-01" }))
    }
}