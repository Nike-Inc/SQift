//
//  MigratorTests.swift
//  SQift
//
//  Created by Christian Noon on 11/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
@testable import SQift
import XCTest

class MigratorTestCase: XCTestCase {
    let timeout = 10.0

    let storageLocation: StorageLocation = {
        let path = NSFileManager.cachesDirectory.stringByAppendingString("/migrator_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(storageLocation.path)
    }

    // MARK: - Tests

    func testThatMigratorCanCreateMigrationsTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            // When
            try migrator.createMigrationsTable()
            let exists: Bool = try connection.query(
                "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                "table",
                "schema_migrations"
            )

            // Then
            XCTAssertTrue(exists, "exists should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorDoesNotThrowWhenCreatingMigrationsTableWhenTableAlreadyExists() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            // When
            try migrator.createMigrationsTable()
            try migrator.createMigrationsTable()

            let exists: Bool = try connection.query(
                "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                "table",
                "schema_migrations"
            )

            // Then
            XCTAssertTrue(exists, "exists should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorMigrationsTableExistsPropertyReturnsFalseIfTableDoesNotExists() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            // When
            try connection.execute("DROP TABLE IF EXISTS schema_migrations")
            let tableExists = migrator.migrationsTableExists

            // Then
            XCTAssertFalse(tableExists, "table exists should be false")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorMigrationsTableExistsPropertyReturnsTrueIfTableExists() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            // When
            try migrator.createMigrationsTable()
            let tableExists = migrator.migrationsTableExists

            // Then
            XCTAssertTrue(tableExists, "table exists should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorCanRunInitialMigration() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            let expectation = expectationWithDescription("migrations should complete successfully")

            var willMigrate: [UInt64] = []
            var didMigrate: [UInt64] = []
            var migrationError: Error? = nil
            var agentsTableExists = false

            // When
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                do {
                    try migrator.runMigrationsIfNecessary(
                        migrationSQLForSchemaVersion: { version in
                            return "CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)"
                        },
                        willMigrateToSchemaVersion: { version in
                            willMigrate.append(version)
                        },
                        didMigrateToSchemaVersion: { version in
                            didMigrate.append(version)
                        }
                    )

                    agentsTableExists = try connection.query(
                        "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                        "table",
                        "agents"
                    )
                } catch {
                    migrationError = error as? Error
                }

                expectation.fulfill()
            }

            waitForExpectationsWithTimeout(timeout, handler: nil)

            // Then
            XCTAssertEqual(willMigrate.count, 1, "will migrate count should be 1")
            XCTAssertEqual(didMigrate.count, 1, "did migrate count should be 1")
            XCTAssertNil(migrationError, "migration error should be nil")
            XCTAssertTrue(agentsTableExists, "agents table exists should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorCanRunMultipleMigrations() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 2)

            let expectation = expectationWithDescription("migrations should complete successfully")

            var willMigrate: [UInt64] = []
            var didMigrate: [UInt64] = []
            var migrationError: Error? = nil
            var agentsTableExists = false
            var agentCount = 0

            // When
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                do {
                    try migrator.runMigrationsIfNecessary(
                        migrationSQLForSchemaVersion: { version in
                            switch version {
                            case 1:
                                return "CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)"
                            default:
                                let SQL = [
                                    "INSERT INTO agents(name) VALUES('Sterling Archer')",
                                    "INSERT INTO agents(name) VALUES('Lana Kane')",
                                ]

                                return SQL.joinWithSeparator(";")
                            }
                        },
                        willMigrateToSchemaVersion: { version in
                            willMigrate.append(version)
                        },
                        didMigrateToSchemaVersion: { version in
                            didMigrate.append(version)
                        }
                    )

                    agentsTableExists = try connection.query("SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                        "table",
                        "agents"
                    )

                    agentCount = try connection.query("SELECT count(*) FROM agents")
                } catch {
                    migrationError = error as? Error
                }

                expectation.fulfill()
            }

            waitForExpectationsWithTimeout(timeout, handler: nil)

            // Then
            if willMigrate.count == 2 && didMigrate.count == 2 {
                XCTAssertEqual(willMigrate[0], 1, "will migrate 0 should be 1")
                XCTAssertEqual(willMigrate[1], 2, "will migrate 1 should be 2")

                XCTAssertEqual(didMigrate[0], 1, "did migrate 0 should be 1")
                XCTAssertEqual(didMigrate[1], 2, "did migrate 1 should be 2")
            } else {
                XCTFail("will and did migrate counts should be 2")
            }

            XCTAssertNil(migrationError, "migration error should be nil")
            XCTAssertTrue(agentsTableExists, "agents table exists should be true")
            XCTAssertEqual(agentCount, 2, "agent count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorCanRunMigrationsBeyondTheInitialMigration() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            var migrator: Migrator? = Migrator(connection: connection, desiredSchemaVersion: 1)

            try migrator?.runMigrationsIfNecessary(
                migrationSQLForSchemaVersion: { version in
                    return "CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)"
                }
            )

            migrator = nil
            migrator = Migrator(connection: connection, desiredSchemaVersion: 3)

            let expectation = expectationWithDescription("migrations should complete successfully")

            var willMigrate: [UInt64] = []
            var didMigrate: [UInt64] = []
            var migrationError: Error? = nil

            var agentCount = 0
            var missionsTableExists = false

            // When
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                do {
                    try migrator?.runMigrationsIfNecessary(
                        migrationSQLForSchemaVersion: { version in
                            switch version {
                            case 2:
                                let SQL = [
                                    "INSERT INTO agents(name) VALUES('Sterling Archer')",
                                    "INSERT INTO agents(name) VALUES('Lana Kane')",
                                ]

                                return SQL.joinWithSeparator(";")
                            default:
                                return "CREATE TABLE missions(id INTEGER PRIMARY KEY AUTOINCREMENT, payment REAL NOT NULL)"
                            }
                        },
                        willMigrateToSchemaVersion: { version in
                            willMigrate.append(version)
                        },
                        didMigrateToSchemaVersion: { version in
                            didMigrate.append(version)
                        }
                    )

                    agentCount = try connection.query("SELECT count(*) FROM agents")

                    missionsTableExists = try connection.query(
                        "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                        "table",
                        "missions"
                    )
                } catch {
                    migrationError = error as? Error
                }

                expectation.fulfill()
            }

            waitForExpectationsWithTimeout(timeout, handler: nil)

            // Then
            if willMigrate.count == 2 && didMigrate.count == 2 {
                XCTAssertEqual(willMigrate[0], 2, "will migrate 0 should be 2")
                XCTAssertEqual(willMigrate[1], 3, "will migrate 1 should be 3")

                XCTAssertEqual(didMigrate[0], 2, "did migrate 0 should be 2")
                XCTAssertEqual(didMigrate[1], 3, "did migrate 1 should be 3")
            } else {
                XCTFail("will and did migrate counts should be 2")
            }

            XCTAssertNil(migrationError, "migration error should be nil")
            XCTAssertEqual(agentCount, 2, "agent count should be 2")
            XCTAssertTrue(missionsTableExists, "missions table exists should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorCanRunMigrationsByDelegatingMigrationToTheCaller() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 2)

            let expectation = expectationWithDescription("migrations should complete successfully")

            var willMigrate: [UInt64] = []
            var didMigrate: [UInt64] = []
            var migrationError: Error? = nil
            var agentsTableExists = false
            var agentCount = 0

            // When
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                do {
                    try migrator.runMigrationsIfNecessary(
                        migrateDatabaseToSchemaVersion: { version, connection in
                            switch version {
                            case 1:
                                try connection.execute(
                                    "CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)"
                                )
                            default:
                                try connection.execute("INSERT INTO agents(name) VALUES('Sterling Archer')")
                                try connection.execute("INSERT INTO agents(name) VALUES('Lana Kane')")
                            }
                        },
                        willMigrateToSchemaVersion: { version in
                            willMigrate.append(version)
                        },
                        didMigrateToSchemaVersion: { version in
                            didMigrate.append(version)
                        }
                    )

                    agentsTableExists = try connection.query("SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                        "table",
                        "agents"
                    )

                    agentCount = try connection.query("SELECT count(*) FROM agents")
                } catch {
                    migrationError = error as? Error
                }

                expectation.fulfill()
            }

            waitForExpectationsWithTimeout(timeout, handler: nil)

            // Then
            if willMigrate.count == 2 && didMigrate.count == 2 {
                XCTAssertEqual(willMigrate[0], 1, "will migrate 0 should be 1")
                XCTAssertEqual(willMigrate[1], 2, "will migrate 1 should be 2")

                XCTAssertEqual(didMigrate[0], 1, "did migrate 0 should be 1")
                XCTAssertEqual(didMigrate[1], 2, "did migrate 1 should be 2")
            } else {
                XCTFail("will and did migrate counts should be 2")
            }

            XCTAssertNil(migrationError, "migration error should be nil")
            XCTAssertTrue(agentsTableExists, "agents table exists should be true")
            XCTAssertEqual(agentCount, 2, "agent count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatMigratorGracefullyHandlesErrorEncounteredDuringMigration() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

            let expectation = expectationWithDescription("migrations should complete successfully")

            var willMigrate: [UInt64] = []
            var didMigrate: [UInt64] = []
            var migrationError: Error? = nil

            // When
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                do {
                    try migrator.runMigrationsIfNecessary(
                        migrationSQLForSchemaVersion: { version in
                            return "CREATE TABLETYPO agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)"
                        },
                        willMigrateToSchemaVersion: { version in
                            willMigrate.append(version)
                        },
                        didMigrateToSchemaVersion: { version in
                            didMigrate.append(version)
                        }
                    )
                } catch {
                    migrationError = error as? Error
                }

                expectation.fulfill()
            }

            waitForExpectationsWithTimeout(timeout, handler: nil)

            // Then
            XCTAssertEqual(willMigrate.count, 1, "will migrate count should be 1")
            XCTAssertEqual(didMigrate.count, 0, "did migrate count should be 0")
            XCTAssertNotNil(migrationError, "migration error should be nil")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
