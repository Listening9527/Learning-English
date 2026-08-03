import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let backfillPlaceholderWord = "__calendar_backfill_placeholder__"
private let legacyBackfillPlaceholderWord = "calendar-backfill-placeholder"
private let backfillPlaceholderPartOfSpeech = "__backfill_placeholder__"
private let databaseCalendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    return calendar
}()
private let selectionCalendarCurrent: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}()

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let fileName = "learning.sqlite3"

    private init() {}

    func initializeDatabase() {
        let isFirstInstallLaunch = !databaseFileExists()

        guard openDatabase() else {
            print("[DB] Failed to open database")
            return
        }

        execute("PRAGMA foreign_keys = ON;")

        if isFirstInstallLaunch {
            createBaseSchema()
            return
        }

        // Existing installs still run idempotent create + migration to keep schema healthy.
        createBaseSchema()
        dropDeprecatedWordbookSchemaIfNeeded()

        migrateUserWordProgressSchemaIfNeeded()
        migrateWordsSchemaIfNeeded()
        migrateUserSettingsSchemaIfNeeded()
    }

    private func createBaseSchema() {

        for statement in createTableStatements {
            execute(statement)
        }

        for statement in createIndexStatements {
            execute(statement)
        }

        for statement in createTriggerStatements {
            execute(statement)
        }
    }

    private func databaseFileExists() -> Bool {
        do {
            let url = try databaseURL()
            return FileManager.default.fileExists(atPath: url.path)
        } catch {
            return false
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
        let needsRebuild = isLegacyUserWordProgressSchema(columns)

        if needsRebuild {
            rebuildUserWordProgressTable()
        }
    }

    private func isLegacyUserWordProgressSchema(_ columns: [ColumnInfo]) -> Bool {
        guard !columns.isEmpty else {
            return false
        }

        let names = Set(columns.map(\.name))
        let required: Set<String> = [
            "id",
            "user_id",
            "word_id",
            "status",
            "source",
            "easiness_factor",
            "correct_streak",
            "review_count",
            "next_review_at",
            "last_interval_days",
            "updated_at"
        ]

        let hasLegacyFields = names.contains("mastery_level") || names.contains("last_score") || names.contains("last_practiced_at")
        let missingRequired = !required.isSubset(of: names)
        let statusType = columns.first(where: { $0.name == "status" })?.type ?? ""
        let sourceType = columns.first(where: { $0.name == "source" })?.type ?? ""

        return hasLegacyFields || missingRequired || statusType.contains("TEXT") || sourceType.isEmpty
    }

    private func rebuildUserWordProgressTable() {
        execute("DROP TABLE IF EXISTS user_word_progress;")
        execute(userWordProgressCreateStatement)
    }

    private func migrateWordsSchemaIfNeeded() {
        let columns = tableColumns("words")
        guard !columns.isEmpty else {
            return
        }

        let names = Set(columns.map { $0.name })
        let coreRequiredNames: Set<String> = [
            "id",
            "word",
            "created_at",
            "updated_at"
        ]

        // If core identity columns are missing, rebuild as a last resort.
        if !coreRequiredNames.isSubset(of: names) {
            execute("DROP TABLE IF EXISTS words;")
            execute(wordsCreateStatement(tableName: "words"))
            return
        }

        let requiredNames: Set<String> = [
            "id",
            "word",
            "phonetic",
            "syllable_division",
            "frequency",
            "word_root",
            "pos",
            "definition",
            "translation",
            "example",
            "example_1",
            "example_1_translation",
            "example_2",
            "example_2_translation",
            "example_3",
            "example_3_translation",
            "audio_url",
            "type",
            "is_custom",
            "created_at",
            "updated_at"
        ]

        let hasLegacyMeaning = names.contains("meaning")
        let missingRequired = !requiredNames.isSubset(of: names)

        guard missingRequired || hasLegacyMeaning else {
            return
        }

        addColumnIfMissing(tableName: "words", columnName: "syllable_division", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "frequency", definition: "REAL NOT NULL DEFAULT 0")
        addColumnIfMissing(tableName: "words", columnName: "word_root", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "translation", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_1", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_1_translation", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_2", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_2_translation", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_3", definition: "TEXT")
        addColumnIfMissing(tableName: "words", columnName: "example_3_translation", definition: "TEXT")

        // Backfill legacy `meaning` into `definition` when needed.
        if hasLegacyMeaning {
            execute(
                """
                UPDATE words
                SET definition = COALESCE(NULLIF(definition, ''), meaning)
                WHERE COALESCE(definition, '') = '' AND COALESCE(meaning, '') <> '';
                """
            )
        }

        // Keep old single-example column in sync for older UI/query paths.
        execute(
            """
            UPDATE words
            SET example = COALESCE(NULLIF(example, ''), example_1)
            WHERE COALESCE(example, '') = '' AND COALESCE(example_1, '') <> '';
            """
        )
    }

    private func migrateUserSettingsSchemaIfNeeded() {
        let columns = tableColumns("user_settings")
        guard !columns.isEmpty else {
            return
        }

        addColumnIfMissing(
            tableName: "user_settings",
            columnName: "daily_goal",
            definition: "INTEGER NOT NULL DEFAULT 20"
        )
        addColumnIfMissing(
            tableName: "user_settings",
            columnName: "notifications_enabled",
            definition: "INTEGER NOT NULL DEFAULT 0 CHECK (notifications_enabled IN (0, 1))"
        )
        addColumnIfMissing(
            tableName: "user_settings",
            columnName: "notification_hour",
            definition: "INTEGER NOT NULL DEFAULT 20"
        )
        addColumnIfMissing(
            tableName: "user_settings",
            columnName: "notification_minute",
            definition: "INTEGER NOT NULL DEFAULT 0"
        )
    }

    private func dropDeprecatedWordbookSchemaIfNeeded() {
        execute("DROP TABLE IF EXISTS wordbook_words;")
        execute("DROP TABLE IF EXISTS wordbooks;")
        execute("DROP INDEX IF EXISTS idx_wordbook_words_wordbook_id;")
        execute("DROP INDEX IF EXISTS idx_wordbook_words_word_id;")
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
            \(wordsCreateStatement(tableName: "words"))
            """,
            """
            \(userWordProgressCreateStatement)
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

    private func wordsCreateStatement(tableName: String) -> String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            phonetic TEXT,
            syllable_division TEXT,
            frequency REAL NOT NULL DEFAULT 0,
            word_root TEXT,
            pos TEXT,
            definition TEXT NOT NULL DEFAULT '',
            translation TEXT,
            example TEXT,
            example_1 TEXT,
            example_1_translation TEXT,
            example_2 TEXT,
            example_2_translation TEXT,
            example_3 TEXT,
            example_3_translation TEXT,
            audio_url TEXT,
            type TEXT NOT NULL DEFAULT 'word' CHECK (type IN ('word', 'phrase', 'pattern')),
            is_custom INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1)),
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );
        """
    }

    private var userWordProgressCreateStatement: String {
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
            next_review_at TEXT,
            last_interval_days INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            UNIQUE (user_id, word_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
        );
        """
    }
}

extension DatabaseManager {
    private struct SampleWordSeed {
        let word: String
        let phonetic: String
        let partOfSpeech: String
        let definition: String
        let example: String
    }

    struct WordsMarkdownImportSummary {
        let parsed: Int
        let imported: Int
        let updated: Int
        let skipped: Int
    }

    private struct ParsedMarkdownWordRow {
        let word: String
        let phonetic: String
        let syllableDivision: String
        let frequency: Double
        let wordRoot: String
        let partOfSpeech: String
        let definition: String
        let translation: String
        let example1: String
        let example1Translation: String
        let example2: String
        let example2Translation: String
        let example3: String
        let example3Translation: String

        var legacyExample: String {
            let candidates = [example1, example2, example3]
            return candidates.first { !$0.isEmpty } ?? ""
        }
    }

    func importWordsFromMarkdown(
        fileURL: URL,
        replaceExisting: Bool = false,
        isCustom: Bool = false
    ) throws -> WordsMarkdownImportSummary {
        initializeDatabase()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = parseWordsMarkdownRows(content)

        var imported = 0
        var updated = 0
        var skipped = 0

        try executeThrowing("BEGIN TRANSACTION;")
        do {
            for row in rows {
                if let existingID = try fetchExistingWordID(for: row) {
                    if replaceExisting {
                        try updateWordRow(id: existingID, row: row, isCustom: isCustom)
                        updated += 1
                    } else {
                        skipped += 1
                    }
                } else {
                    try insertWordRow(row, isCustom: isCustom)
                    imported += 1
                }
            }
            try executeThrowing("COMMIT;")
        } catch {
            try? executeThrowing("ROLLBACK;")
            throw error
        }

        return WordsMarkdownImportSummary(
            parsed: rows.count,
            imported: imported,
            updated: updated,
            skipped: skipped
        )
    }

    private func parseWordsMarkdownRows(_ content: String) -> [ParsedMarkdownWordRow] {
        content
            .components(separatedBy: .newlines)
            .compactMap(parseMarkdownWordRow)
    }

    private func parseMarkdownWordRow(_ rawLine: String) -> ParsedMarkdownWordRow? {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.hasPrefix("|") else {
            return nil
        }

        let cells = line
            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard cells.count >= 14 else {
            return nil
        }
        guard cells[0] != "单词", cells[0] != "Word" else {
            return nil
        }

        let isSeparator = cells.allSatisfy { cell in
            let normalized = cell
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "-", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.isEmpty
        }
        guard !isSeparator else {
            return nil
        }

        let word = cells[0]
        guard !word.isEmpty else {
            return nil
        }

        let frequencyValue = Double(cells[3]) ?? 0

        return ParsedMarkdownWordRow(
            word: word,
            phonetic: cells[1],
            syllableDivision: cells[2],
            frequency: max(0, frequencyValue),
            wordRoot: cells[4],
            partOfSpeech: cells[5],
            definition: cells[6],
            translation: cells[7],
            example1: cells[8],
            example1Translation: cells[9],
            example2: cells[10],
            example2Translation: cells[11],
            example3: cells[12],
            example3Translation: cells[13]
        )
    }

    private func fetchExistingWordID(for row: ParsedMarkdownWordRow) throws -> Int64? {
        let sql =
            """
            SELECT id
            FROM words
            WHERE word = ?
              AND COALESCE(pos, '') = COALESCE(?, '')
              AND COALESCE(definition, '') = COALESCE(?, '')
              AND COALESCE(translation, '') = COALESCE(?, '')
            ORDER BY id ASC
            LIMIT 1;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(row.word, to: statement, index: 1)
        try bindText(row.partOfSpeech, to: statement, index: 2)
        try bindText(row.definition, to: statement, index: 3)
        try bindText(row.translation, to: statement, index: 4)

        let result = sqlite3_step(statement)
        if result == SQLITE_ROW {
            return sqlite3_column_int64(statement, 0)
        }
        if result == SQLITE_DONE {
            return nil
        }

        throw databaseError(message: "Failed to query existing word")
    }

    private func insertWordRow(_ row: ParsedMarkdownWordRow, isCustom: Bool) throws {
        let sql =
            """
            INSERT INTO words (
                word, phonetic, syllable_division, frequency, word_root, pos,
                definition, translation, example,
                example_1, example_1_translation,
                example_2, example_2_translation,
                example_3, example_3_translation,
                type, is_custom, created_at, updated_at
            )
            VALUES (
                ?, ?, ?, ?, ?, ?,
                ?, ?, ?,
                ?, ?,
                ?, ?,
                ?, ?,
                'word', ?, datetime('now'), datetime('now')
            );
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(row.word, to: statement, index: 1)
        try bindText(row.phonetic, to: statement, index: 2)
        try bindText(row.syllableDivision, to: statement, index: 3)
        guard sqlite3_bind_double(statement, 4, row.frequency) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind frequency")
        }
        try bindText(row.wordRoot, to: statement, index: 5)
        try bindText(row.partOfSpeech, to: statement, index: 6)
        try bindText(row.definition, to: statement, index: 7)
        try bindText(row.translation, to: statement, index: 8)
        try bindText(row.legacyExample, to: statement, index: 9)
        try bindText(row.example1, to: statement, index: 10)
        try bindText(row.example1Translation, to: statement, index: 11)
        try bindText(row.example2, to: statement, index: 12)
        try bindText(row.example2Translation, to: statement, index: 13)
        try bindText(row.example3, to: statement, index: 14)
        try bindText(row.example3Translation, to: statement, index: 15)
        guard sqlite3_bind_int(statement, 16, isCustom ? 1 : 0) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind custom flag")
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to insert markdown word row")
        }
    }

    private func updateWordRow(id: Int64, row: ParsedMarkdownWordRow, isCustom: Bool) throws {
        let sql =
            """
            UPDATE words
            SET phonetic = ?,
                syllable_division = ?,
                frequency = ?,
                word_root = ?,
                pos = ?,
                definition = ?,
                translation = ?,
                example = ?,
                example_1 = ?,
                example_1_translation = ?,
                example_2 = ?,
                example_2_translation = ?,
                example_3 = ?,
                example_3_translation = ?,
                type = 'word',
                is_custom = ?,
                updated_at = datetime('now')
            WHERE id = ?;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(row.phonetic, to: statement, index: 1)
        try bindText(row.syllableDivision, to: statement, index: 2)
        guard sqlite3_bind_double(statement, 3, row.frequency) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind frequency")
        }
        try bindText(row.wordRoot, to: statement, index: 4)
        try bindText(row.partOfSpeech, to: statement, index: 5)
        try bindText(row.definition, to: statement, index: 6)
        try bindText(row.translation, to: statement, index: 7)
        try bindText(row.legacyExample, to: statement, index: 8)
        try bindText(row.example1, to: statement, index: 9)
        try bindText(row.example1Translation, to: statement, index: 10)
        try bindText(row.example2, to: statement, index: 11)
        try bindText(row.example2Translation, to: statement, index: 12)
        try bindText(row.example3, to: statement, index: 13)
        try bindText(row.example3Translation, to: statement, index: 14)
        guard sqlite3_bind_int(statement, 15, isCustom ? 1 : 0) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind custom flag")
        }
        guard sqlite3_bind_int64(statement, 16, id) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind row id")
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to update markdown word row")
        }
    }

    func fetchSearchHistory(limit: Int) throws -> [String] {
        initializeDatabase()

        let sql =
            """
            SELECT query
            FROM search_history
            WHERE query <> ''
            GROUP BY query
            ORDER BY MAX(searched_at) DESC, MAX(id) DESC
            LIMIT ?;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind search history limit")
        }

        var history: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let query = stringValue(from: statement, index: 0), !query.isEmpty else {
                continue
            }
            history.append(query)
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch search history")
        }

        return history
    }

    func fetchUserPreferences() throws -> UserPreferences {
        initializeDatabase()

        let userID = try ensureBackfillUserID()
        let sql =
            """
            SELECT daily_goal, notifications_enabled, notification_hour, notification_minute
            FROM user_settings
            WHERE user_id = ?
            LIMIT 1;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, userID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind user id")
        }

        if sqlite3_step(statement) == SQLITE_ROW {
            return UserPreferences(
                dailyGoal: Int(sqlite3_column_int(statement, 0)),
                notificationsEnabled: sqlite3_column_int(statement, 1) != 0,
                notificationHour: Int(sqlite3_column_int(statement, 2)),
                notificationMinute: Int(sqlite3_column_int(statement, 3))
            )
        }

        return .default
    }

    func saveUserPreferences(_ preferences: UserPreferences) throws {
        initializeDatabase()

        let userID = try ensureBackfillUserID()
        let sql =
            """
            INSERT INTO user_settings (user_id, daily_goal, notifications_enabled, notification_hour, notification_minute, updated_at)
            VALUES (?, ?, ?, ?, ?, datetime('now'))
            ON CONFLICT(user_id) DO UPDATE SET
                daily_goal = excluded.daily_goal,
                notifications_enabled = excluded.notifications_enabled,
                notification_hour = excluded.notification_hour,
                notification_minute = excluded.notification_minute,
                updated_at = datetime('now');
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, userID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind user id")
        }
        guard sqlite3_bind_int(statement, 2, Int32(max(preferences.dailyGoal, 1))) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind daily goal")
        }
        guard sqlite3_bind_int(statement, 3, preferences.notificationsEnabled ? 1 : 0) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind notifications enabled")
        }
        guard sqlite3_bind_int(statement, 4, Int32(max(0, min(preferences.notificationHour, 23)))) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind notification hour")
        }
        guard sqlite3_bind_int(statement, 5, Int32(max(0, min(preferences.notificationMinute, 59)))) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind notification minute")
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to save user preferences")
        }
    }


    func searchWords(query: String) throws -> [RecentWordSummary] {
        initializeDatabase()

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        let sql =
            """
                        SELECT id, word, phonetic, syllable_division, frequency, word_root, pos, definition, translation,
                                     example_1, example_1_translation, example_2, example_2_translation, example_3, example_3_translation,
                                     created_at
            FROM words
            WHERE COALESCE(pos, '') <> '\(backfillPlaceholderPartOfSpeech)'
              AND word <> '\(legacyBackfillPlaceholderWord)'
              AND (
                word LIKE ? COLLATE NOCASE
                OR definition LIKE ? COLLATE NOCASE
                                OR translation LIKE ? COLLATE NOCASE
              )
            ORDER BY created_at DESC, id DESC
            LIMIT 30;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        let pattern = "%\(normalizedQuery)%"
        try bindText(pattern, to: statement, index: 1)
        try bindText(pattern, to: statement, index: 2)
        try bindText(pattern, to: statement, index: 3)

        var words: [RecentWordSummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            words.append(
                RecentWordSummary(
                    id: sqlite3_column_int64(statement, 0),
                    word: stringValue(from: statement, index: 1) ?? "",
                    phonetic: stringValue(from: statement, index: 2),
                    syllableDivision: stringValue(from: statement, index: 3),
                    frequency: sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 4),
                    wordRoot: stringValue(from: statement, index: 5),
                    partOfSpeech: stringValue(from: statement, index: 6),
                    definition: stringValue(from: statement, index: 7) ?? "",
                    translation: stringValue(from: statement, index: 8),
                    example1: stringValue(from: statement, index: 9),
                    example1Translation: stringValue(from: statement, index: 10),
                    example2: stringValue(from: statement, index: 11),
                    example2Translation: stringValue(from: statement, index: 12),
                    example3: stringValue(from: statement, index: 13),
                    example3Translation: stringValue(from: statement, index: 14),
                    createdAt: stringValue(from: statement, index: 15) ?? ""
                )
            )
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to search words")
        }

        try insertSearchHistory(query: normalizedQuery, source: "search")
        return words
    }

    func createCustomWord(
        word: String,
        phonetic: String,
        syllableDivision: String = "",
        frequency: Double = 0,
        wordRoot: String = "",
        partOfSpeech: String,
        definition: String,
        translation: String = "",
        example1: String = "",
        example1Translation: String = "",
        example2: String = "",
        example2Translation: String = "",
        example3: String = "",
        example3Translation: String = ""
    ) throws -> Int64 {
        initializeDatabase()

        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefinition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty, !trimmedDefinition.isEmpty else {
            throw databaseError(message: "Word and definition are required")
        }

        let timestampValue = timestamp(for: Date())
        let sql =
            """
            INSERT INTO words (
                word, phonetic, syllable_division, frequency, word_root, pos,
                definition, translation, example, example_1, example_1_translation,
                example_2, example_2_translation, example_3, example_3_translation,
                type, is_custom, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'word', 1, ?, ?);
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        let trimmedPhonetic = phonetic.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSyllableDivision = syllableDivision.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWordRoot = wordRoot.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPart = partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample1 = example1.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample1Translation = example1Translation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample2 = example2.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample2Translation = example2Translation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample3 = example3.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample3Translation = example3Translation.trimmingCharacters(in: .whitespacesAndNewlines)

        let fallbackExample = [trimmedExample1, trimmedExample2, trimmedExample3].first { !$0.isEmpty } ?? ""
        let normalizedFrequency = max(0, frequency)

        try bindText(trimmedWord, to: statement, index: 1)
        try bindText(trimmedPhonetic, to: statement, index: 2)
        try bindText(trimmedSyllableDivision, to: statement, index: 3)
        guard sqlite3_bind_double(statement, 4, normalizedFrequency) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind frequency")
        }
        try bindText(trimmedWordRoot, to: statement, index: 5)
        try bindText(trimmedPart, to: statement, index: 6)
        try bindText(trimmedDefinition, to: statement, index: 7)
        try bindText(trimmedTranslation, to: statement, index: 8)
        try bindText(fallbackExample, to: statement, index: 9)
        try bindText(trimmedExample1, to: statement, index: 10)
        try bindText(trimmedExample1Translation, to: statement, index: 11)
        try bindText(trimmedExample2, to: statement, index: 12)
        try bindText(trimmedExample2Translation, to: statement, index: 13)
        try bindText(trimmedExample3, to: statement, index: 14)
        try bindText(trimmedExample3Translation, to: statement, index: 15)
        try bindText(timestampValue, to: statement, index: 16)
        try bindText(timestampValue, to: statement, index: 17)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to create custom word")
        }

        guard let db else {
            throw databaseError(message: "Database is not open")
        }

        let insertedWordID = sqlite3_last_insert_rowid(db)
        try insertSearchHistory(query: trimmedWord, source: "custom_word")
        return insertedWordID
    }

    func fetchStudyWords(limit: Int = 10, offset: Int = 0) throws -> [String] {
        initializeDatabase()

        let cappedLimit = max(1, limit)
        let cappedOffset = max(0, offset)

        var words = try fetchStudyWordsFromWordsTable(limit: cappedLimit, offset: cappedOffset)
        if words.isEmpty, cappedOffset == 0 {
            try insertThirtySampleWords()
            words = try fetchStudyWordsFromWordsTable(limit: cappedLimit, offset: cappedOffset)
        }

        return words
    }

    private func fetchStudyWordsFromWordsTable(limit: Int, offset: Int) throws -> [String] {

        let sql =
            """
                        SELECT word
                        FROM words
                        WHERE COALESCE(pos, '') <> '\(backfillPlaceholderPartOfSpeech)'
                            AND word <> '\(legacyBackfillPlaceholderWord)'
                        ORDER BY created_at DESC, id DESC
                        LIMIT ? OFFSET ?;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind study words limit")
        }
        guard sqlite3_bind_int(statement, 2, Int32(offset)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind study words offset")
        }

        var words: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let word = stringValue(from: statement, index: 0) else {
                continue
            }
            let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalized.isEmpty {
                words.append(normalized)
            }
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch study words")
        }

        return Array(NSOrderedSet(array: words)) as? [String] ?? words
    }

    func fetchWordSummaries(words: [String]) throws -> [RecentWordSummary] {
        initializeDatabase()

        let normalizedWords = words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        guard !normalizedWords.isEmpty else {
            return []
        }

        let placeholders = Array(repeating: "?", count: normalizedWords.count).joined(separator: ",")
        let sql =
            """
            SELECT id, word, phonetic, syllable_division, frequency, word_root, pos, definition, translation,
                   example_1, example_1_translation, example_2, example_2_translation, example_3, example_3_translation,
                   created_at
            FROM words
            WHERE LOWER(word) IN (
                \(placeholders)
            )
              AND COALESCE(pos, '') <> '\(backfillPlaceholderPartOfSpeech)'
              AND word <> '\(legacyBackfillPlaceholderWord)'
            ORDER BY created_at DESC, id DESC;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        for (index, word) in normalizedWords.enumerated() {
            try bindText(word, to: statement, index: Int32(index + 1))
        }

        var summaries: [RecentWordSummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            summaries.append(
                RecentWordSummary(
                    id: sqlite3_column_int64(statement, 0),
                    word: stringValue(from: statement, index: 1) ?? "",
                    phonetic: stringValue(from: statement, index: 2),
                    syllableDivision: stringValue(from: statement, index: 3),
                    frequency: sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 4),
                    wordRoot: stringValue(from: statement, index: 5),
                    partOfSpeech: stringValue(from: statement, index: 6),
                    definition: stringValue(from: statement, index: 7) ?? "",
                    translation: stringValue(from: statement, index: 8),
                    example1: stringValue(from: statement, index: 9),
                    example1Translation: stringValue(from: statement, index: 10),
                    example2: stringValue(from: statement, index: 11),
                    example2Translation: stringValue(from: statement, index: 12),
                    example3: stringValue(from: statement, index: 13),
                    example3Translation: stringValue(from: statement, index: 14),
                    createdAt: stringValue(from: statement, index: 15) ?? ""
                )
            )
        }

        let result = sqlite3_errcode(db)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw databaseError(message: "Failed to fetch word summaries")
        }

        return summaries
    }

    func markWordAsForgotten(wordID: Int64) throws {
        initializeDatabase()

        let userID = try ensureBackfillUserID()
        let sql =
            """
            INSERT INTO user_word_progress (user_id, word_id, status, source, updated_at)
            VALUES (?, ?, 0, 'review', datetime('now'))
            ON CONFLICT(user_id, word_id)
            DO UPDATE SET
                status = 0,
                source = 'review',
                updated_at = datetime('now');
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, userID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind user id")
        }
        guard sqlite3_bind_int64(statement, 2, wordID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind word id")
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to mark word as forgotten")
        }
    }

    func insertWordForTesting(
        word: String,
        phonetic: String,
        partOfSpeech: String?,
        definition: String,
        createdAt: String
    ) throws -> Int64 {
        initializeDatabase()

        let sql =
            """
            INSERT INTO words (
                word, phonetic, syllable_division, frequency, word_root, pos,
                definition, translation, created_at, updated_at
            )
            VALUES (?, ?, '', 0, '', ?, ?, '', ?, ?);
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(word, to: statement, index: 1)
        try bindText(phonetic, to: statement, index: 2)
        if let partOfSpeech {
            try bindText(partOfSpeech, to: statement, index: 3)
        } else {
            guard sqlite3_bind_null(statement, 3) == SQLITE_OK else {
                throw databaseError(message: "Failed to bind testing word part of speech")
            }
        }
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

    func insertThirtySampleWords() throws {
        initializeDatabase()

        let samples: [SampleWordSeed] = [
            .init(word: "abandon", phonetic: "/əˈbændən/", partOfSpeech: "verb", definition: "to leave behind", example: "They had to abandon the old plan."),
            .init(word: "ability", phonetic: "/əˈbɪləti/", partOfSpeech: "noun", definition: "the power or skill to do something", example: "She showed her ability to lead."),
            .init(word: "absolute", phonetic: "/ˈæbsəluːt/", partOfSpeech: "adjective", definition: "complete and total", example: "We need absolute silence here."),
            .init(word: "absorb", phonetic: "/əbˈzɔːrb/", partOfSpeech: "verb", definition: "to take in", example: "Plants absorb sunlight for energy."),
            .init(word: "academic", phonetic: "/ˌækəˈdemɪk/", partOfSpeech: "adjective", definition: "related to education or study", example: "He returned to academic research."),
            .init(word: "access", phonetic: "/ˈækses/", partOfSpeech: "noun", definition: "a way of entering or using something", example: "Students have access to the library."),
            .init(word: "accompany", phonetic: "/əˈkʌmpəni/", partOfSpeech: "verb", definition: "to go with someone", example: "I will accompany you to the station."),
            .init(word: "accurate", phonetic: "/ˈækjərət/", partOfSpeech: "adjective", definition: "correct and exact", example: "The report provides accurate numbers."),
            .init(word: "achieve", phonetic: "/əˈtʃiːv/", partOfSpeech: "verb", definition: "to successfully reach a goal", example: "They achieved strong sales growth."),
            .init(word: "acquire", phonetic: "/əˈkwaɪər/", partOfSpeech: "verb", definition: "to obtain something", example: "Children acquire language quickly."),
            .init(word: "adapt", phonetic: "/əˈdæpt/", partOfSpeech: "verb", definition: "to adjust to new conditions", example: "We must adapt to the market."),
            .init(word: "adequate", phonetic: "/ˈædɪkwət/", partOfSpeech: "adjective", definition: "enough in quantity or quality", example: "The room has adequate lighting."),
            .init(word: "adjust", phonetic: "/əˈdʒʌst/", partOfSpeech: "verb", definition: "to change slightly", example: "Adjust the chair to a comfortable height."),
            .init(word: "administration", phonetic: "/ədˌmɪnɪˈstreɪʃən/", partOfSpeech: "noun", definition: "the management of an organization", example: "She works in school administration."),
            .init(word: "adopt", phonetic: "/əˈdɑːpt/", partOfSpeech: "verb", definition: "to start using a method or idea", example: "The team adopted a new workflow."),
            .init(word: "advance", phonetic: "/ədˈvæns/", partOfSpeech: "verb", definition: "to move forward or improve", example: "Technology continues to advance rapidly."),
            .init(word: "advocate", phonetic: "/ˈædvəkeɪt/", partOfSpeech: "verb", definition: "to publicly support something", example: "Doctors advocate regular exercise."),
            .init(word: "affect", phonetic: "/əˈfekt/", partOfSpeech: "verb", definition: "to influence something", example: "Weather can affect travel plans."),
            .init(word: "aggregate", phonetic: "/ˈæɡrɪɡət/", partOfSpeech: "noun", definition: "a total formed by combining parts", example: "The aggregate score decides the winner."),
            .init(word: "aid", phonetic: "/eɪd/", partOfSpeech: "noun", definition: "help or support", example: "International aid arrived quickly."),
            .init(word: "allocate", phonetic: "/ˈæləkeɪt/", partOfSpeech: "verb", definition: "to distribute resources", example: "We need to allocate more time to testing."),
            .init(word: "alter", phonetic: "/ˈɔːltər/", partOfSpeech: "verb", definition: "to change", example: "The design was altered at the last minute."),
            .init(word: "analysis", phonetic: "/əˈnæləsɪs/", partOfSpeech: "noun", definition: "careful examination of something", example: "The data analysis revealed a pattern."),
            .init(word: "annual", phonetic: "/ˈænjuəl/", partOfSpeech: "adjective", definition: "happening once a year", example: "The company released its annual report."),
            .init(word: "anticipate", phonetic: "/ænˈtɪsɪpeɪt/", partOfSpeech: "verb", definition: "to expect in advance", example: "We anticipate higher demand next month."),
            .init(word: "apparent", phonetic: "/əˈpærənt/", partOfSpeech: "adjective", definition: "easy to notice or understand", example: "It became apparent that we were late."),
            .init(word: "approach", phonetic: "/əˈproʊtʃ/", partOfSpeech: "noun", definition: "a way of dealing with something", example: "Their approach to learning is practical."),
            .init(word: "appropriate", phonetic: "/əˈproʊpriət/", partOfSpeech: "adjective", definition: "suitable for a particular purpose", example: "Please wear appropriate shoes."),
            .init(word: "approximate", phonetic: "/əˈprɑːksɪmət/", partOfSpeech: "adjective", definition: "close to the real amount", example: "The approximate cost is fifty dollars."),
            .init(word: "arbitrary", phonetic: "/ˈɑːrbɪtreri/", partOfSpeech: "adjective", definition: "based on random choice rather than reason", example: "The deadline felt somewhat arbitrary.")
        ]

        let sql =
            """
            INSERT OR IGNORE INTO words (
                word, phonetic, syllable_division, frequency, word_root, pos,
                definition, translation, example, example_1,
                type, is_custom, created_at, updated_at
            )
            VALUES (?, ?, '', 0, '', ?, ?, '', ?, ?, 'word', 1, ?, ?);
            """

        try executeThrowing("BEGIN TRANSACTION;")
        defer {
            try? executeThrowing("COMMIT;")
        }

        for (index, sample) in samples.enumerated() {
            let statement = try prepareStatement(sql)
            defer { sqlite3_finalize(statement) }

            let day = String(format: "%02d", index + 1)
            let createdAt = "2026-07-\(day) 10:00:00"

            try bindText(sample.word, to: statement, index: 1)
            try bindText(sample.phonetic, to: statement, index: 2)
            try bindText(sample.partOfSpeech, to: statement, index: 3)
            try bindText(sample.definition, to: statement, index: 4)
            try bindText(sample.example, to: statement, index: 5)
            try bindText(sample.example, to: statement, index: 6)
            try bindText(createdAt, to: statement, index: 7)
            try bindText(createdAt, to: statement, index: 8)

            let result = sqlite3_step(statement)
            guard result == SQLITE_DONE else {
                throw databaseError(message: "Failed to insert sample word")
            }
        }
    }

    func resetTestingFixturesForTesting() throws {
        initializeDatabase()
        try resetTestingFixtures()
    }

    func fetchCreateTableSQLForTesting(tableName: String) throws -> String {
        initializeDatabase()

        let sql =
            """
            SELECT sql
            FROM sqlite_master
            WHERE type = 'table' AND name = ?
            LIMIT 1;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(tableName, to: statement, index: 1)

        guard sqlite3_step(statement) == SQLITE_ROW,
              let tableSQL = stringValue(from: statement, index: 0) else {
            throw databaseError(message: "Failed to fetch create table SQL")
        }

        return tableSQL
    }

    func installLegacyUserWordProgressSchemaForTesting() throws {
        initializeDatabase()
        guard isRunningTests else {
            return
        }

        try executeThrowing("DROP TABLE IF EXISTS user_word_progress;")
        try executeThrowing(
            """
            CREATE TABLE user_word_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                word_id INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'new',
                mastery_level INTEGER NOT NULL DEFAULT 0,
                last_score INTEGER,
                last_practiced_at TEXT,
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE (user_id, word_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );
            """
        )
    }

    private func insertSearchHistory(query: String, source: String) throws {
        let sql =
            """
            INSERT INTO search_history (user_id, query, source, searched_at)
            VALUES (?, ?, ?, ?);
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        let userID = try ensureBackfillUserID()
        guard sqlite3_bind_int64(statement, 1, userID) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind search user id")
        }
        try bindText(query, to: statement, index: 2)
        try bindText(source, to: statement, index: 3)
        try bindText(timestamp(for: Date()), to: statement, index: 4)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(message: "Failed to insert search history")
        }
    }

    func fetchRecentWordSummaries(limit: Int) throws -> [RecentWordSummary] {
        initializeDatabase()

        let sql =
            """
            SELECT id, word, phonetic, syllable_division, frequency, word_root, pos, definition, translation,
                   example_1, example_1_translation, example_2, example_2_translation, example_3, example_3_translation,
                   created_at
            FROM words
                        WHERE COALESCE(pos, '') <> '\(backfillPlaceholderPartOfSpeech)'
                            AND word <> '\(legacyBackfillPlaceholderWord)'
            ORDER BY created_at DESC, id DESC
            LIMIT ?;
            """

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw databaseError(message: "Failed to bind recent words limit")
        }

        var words: [RecentWordSummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let word = stringValue(from: statement, index: 1) ?? ""
            let phonetic = stringValue(from: statement, index: 2)
            let syllableDivision = stringValue(from: statement, index: 3)
            let frequency = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 4)
            let wordRoot = stringValue(from: statement, index: 5)
            let partOfSpeech = stringValue(from: statement, index: 6)
            let definition = stringValue(from: statement, index: 7) ?? ""
            let translation = stringValue(from: statement, index: 8)
            let example1 = stringValue(from: statement, index: 9)
            let example1Translation = stringValue(from: statement, index: 10)
            let example2 = stringValue(from: statement, index: 11)
            let example2Translation = stringValue(from: statement, index: 12)
            let example3 = stringValue(from: statement, index: 13)
            let example3Translation = stringValue(from: statement, index: 14)
            let createdAt = stringValue(from: statement, index: 15) ?? ""

            words.append(
                RecentWordSummary(
                    id: id,
                    word: word,
                    phonetic: phonetic,
                    syllableDivision: syllableDivision,
                    frequency: frequency,
                    wordRoot: wordRoot,
                    partOfSpeech: partOfSpeech,
                    definition: definition,
                    translation: translation,
                    example1: example1,
                    example1Translation: example1Translation,
                    example2: example2,
                    example2Translation: example2Translation,
                    example3: example3,
                    example3Translation: example3Translation,
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
            sql: "SELECT COUNT(*) FROM words WHERE COALESCE(pos, '') <> '\(backfillPlaceholderPartOfSpeech)' AND word <> '\(legacyBackfillPlaceholderWord)';"
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

        let statement = try prepareStatement(sql)
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

        let statement = try prepareStatement(sql)
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

        let statement = try prepareStatement(sql)
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
        let statement = try prepareStatement(sql)
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

        let statement = try prepareStatement(sql)
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
        if let existingWordID = try fetchOptionalInt64(
            sql: "SELECT id FROM words WHERE pos = '\(backfillPlaceholderPartOfSpeech)' ORDER BY id ASC LIMIT 1;"
        ) {
            return existingWordID
        }

        if let legacyPlaceholderID = try fetchOptionalInt64(
            sql: "SELECT id FROM words WHERE word = '\(legacyBackfillPlaceholderWord)' ORDER BY id ASC LIMIT 1;"
        ) {
            try executeThrowing(
                "UPDATE words SET pos = '\(backfillPlaceholderPartOfSpeech)' WHERE id = \(legacyPlaceholderID);"
            )
            return legacyPlaceholderID
        }

        let sql =
            """
            INSERT INTO words (word, phonetic, pos, definition, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?);
            """

        let createdAt = timestamp(for: Date(timeIntervalSince1970: 0))
        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(backfillPlaceholderWord, to: statement, index: 1)
        try bindText("/ˈkælənˌdɑr/", to: statement, index: 2)
        try bindText(backfillPlaceholderPartOfSpeech, to: statement, index: 3)
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
        let statement = try prepareStatement(sql)
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
        let localComponents = selectionCalendarCurrent.dateComponents([.year, .month, .day], from: date)
        var utcComponents = DateComponents()
        utcComponents.calendar = databaseCalendarUTC
        utcComponents.timeZone = databaseCalendarUTC.timeZone
        utcComponents.year = localComponents.year
        utcComponents.month = localComponents.month
        utcComponents.day = localComponents.day
        let utcMidnight = databaseCalendarUTC.date(from: utcComponents) ?? date
        return databaseCalendarUTC.startOfDay(for: utcMidnight)
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
            "DELETE FROM user_settings;",
            "DELETE FROM search_history;",
            "DELETE FROM users;",
            "DELETE FROM words;",
            "DELETE FROM sqlite_sequence WHERE name IN ('daily_records', 'user_word_progress', 'user_settings', 'search_history', 'users', 'words');"
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