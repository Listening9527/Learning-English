import XCTest
@testable import Learning

final class DatabaseManagerSM2SchemaTests: XCTestCase {
    func test_initializeDatabase_uses_sm2_user_word_progress_schema() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()

        database.initializeDatabase()

        let createSQL = try database.fetchCreateTableSQLForTesting(tableName: "user_word_progress")

        XCTAssertTrue(createSQL.contains("status INTEGER NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2))"))
        XCTAssertTrue(createSQL.contains("source TEXT NOT NULL DEFAULT 'new' CHECK (source IN ('new', 'review', 'simple'))"))
        XCTAssertTrue(createSQL.contains("easiness_factor REAL NOT NULL DEFAULT 2.50"))
        XCTAssertTrue(createSQL.contains("correct_streak INTEGER NOT NULL DEFAULT 0"))
        XCTAssertTrue(createSQL.contains("review_count INTEGER NOT NULL DEFAULT 0"))
        XCTAssertTrue(createSQL.contains("next_review_at TEXT"))
        XCTAssertTrue(createSQL.contains("last_interval_days INTEGER NOT NULL DEFAULT 0"))
        XCTAssertFalse(createSQL.contains("mastery_level"))
        XCTAssertFalse(createSQL.contains("last_score"))
        XCTAssertFalse(createSQL.contains("last_practiced_at"))
    }

    func test_initializeDatabase_rebuilds_legacy_user_word_progress_schema() throws {
        let database = DatabaseManager.shared
        try database.resetTestingFixturesForTesting()
        try database.installLegacyUserWordProgressSchemaForTesting()

        database.initializeDatabase()

        let createSQL = try database.fetchCreateTableSQLForTesting(tableName: "user_word_progress")

        XCTAssertTrue(createSQL.contains("easiness_factor REAL NOT NULL DEFAULT 2.50"))
        XCTAssertTrue(createSQL.contains("correct_streak INTEGER NOT NULL DEFAULT 0"))
        XCTAssertTrue(createSQL.contains("review_count INTEGER NOT NULL DEFAULT 0"))
        XCTAssertTrue(createSQL.contains("status INTEGER NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2))"))
        XCTAssertFalse(createSQL.contains("status TEXT"))
        XCTAssertFalse(createSQL.contains("mastery_level"))
        XCTAssertFalse(createSQL.contains("last_score"))
        XCTAssertFalse(createSQL.contains("last_practiced_at"))
    }
}
