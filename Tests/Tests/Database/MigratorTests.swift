//
//  MigratorTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
@testable import SQift
import XCTest

class MigratorTestCase: BaseTestCase {
    func testThatMigratorCanCreateMigrationsTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        // When
        try migrator.createMigrationTable()
        let exists: Bool? = try connection.query(
            "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
            "table",
            "schema_migrations"
        )

        // Then
        XCTAssertEqual(exists, true)
    }

    func testThatMigratorDoesNotThrowWhenCreatingMigrationsTableWhenTableAlreadyExists() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        // When
        try migrator.createMigrationTable()
        try migrator.createMigrationTable()

        let exists: Bool? = try connection.query(
            "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
            "table",
            "schema_migrations"
        )

        // Then
        XCTAssertEqual(exists, true)
    }

    func testThatMigratorMigrationsTableExistsPropertyReturnsFalseIfTableDoesNotExists() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        // When
        try connection.execute("DROP TABLE IF EXISTS schema_migrations")
        let tableExists = migrator.migrationTableExists

        // Then
        XCTAssertFalse(tableExists)
    }

    func testThatMigratorMigrationsTableExistsPropertyReturnsTrueIfTableExists() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        // When
        try migrator.createMigrationTable()
        let tableExists = migrator.migrationTableExists

        // Then
        XCTAssertTrue(tableExists)
    }

    func testThatMigratorCanRunInitialMigration() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        let expectation = self.expectation(description: "migrations should complete successfully")

        var willMigrate: [UInt64] = []
        var didMigrate: [UInt64] = []
        var migrationError: Error?
        var agentsTableExists: Bool?

        // When
        DispatchQueue.utility.async {
            do {
                try migrator.runMigrationsIfNecessary(
                    migrationSQLForSchemaVersion: { version in
                        return "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
                    },
                    willMigrateToSchemaVersion: { version in
                        willMigrate.append(version)
                    },
                    didMigrateToSchemaVersion: { version in
                        didMigrate.append(version)
                    }
                )

                agentsTableExists = try connection.query(
                    "SELECT count(*) FROM sqlite_master WHERE type = ? AND name = ?",
                    "table",
                    "agents"
                )
            } catch {
                migrationError = error
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(willMigrate.count, 1)
        XCTAssertEqual(didMigrate.count, 1)
        XCTAssertNil(migrationError)
        XCTAssertEqual(agentsTableExists, true)
    }

    func testThatMigratorCanRunMultipleMigrations() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 2)

        let expectation = self.expectation(description: "migrations should complete successfully")

        var willMigrate: [UInt64] = []
        var didMigrate: [UInt64] = []
        var migrationError: Error? = nil
        var agentsTableExists: Bool?
        var agentCount: Int?

        // When
        DispatchQueue.utility.async {
            do {
                try migrator.runMigrationsIfNecessary(
                    migrationSQLForSchemaVersion: { version in
                        switch version {
                        case 1:
                            return "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT NOT NULL)"

                        default:
                            return """
                            INSERT INTO agents(name) VALUES('Sterling Archer');
                            INSERT INTO agents(name) VALUES('Lana Kane')
                            """
                        }
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

                agentCount = try connection.query("SELECT count(*) FROM agents")
            } catch {
                migrationError = error
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        if willMigrate.count == 2 && didMigrate.count == 2 {
            XCTAssertEqual(willMigrate[0], 1)
            XCTAssertEqual(willMigrate[1], 2)

            XCTAssertEqual(didMigrate[0], 1)
            XCTAssertEqual(didMigrate[1], 2)
        } else {
            XCTFail("will and did migrate counts should be 2")
        }

        XCTAssertNil(migrationError)
        XCTAssertEqual(agentsTableExists, true)
        XCTAssertEqual(agentCount, 2)
    }

    func testThatMigratorCanRunMigrationsBeyondTheInitialMigration() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        var migrator: Migrator? = Migrator(connection: connection, desiredSchemaVersion: 1)

        try migrator?.runMigrationsIfNecessary(
            migrationSQLForSchemaVersion: { version in
                return "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
            }
        )

        migrator = nil
        migrator = Migrator(connection: connection, desiredSchemaVersion: 3)

        let expectation = self.expectation(description: "migrations should complete successfully")

        var willMigrate: [UInt64] = []
        var didMigrate: [UInt64] = []
        var migrationError: Error? = nil

        var agentCount: Int?
        var missionsTableExists: Bool?

        // When
        DispatchQueue.utility.async {
            do {
                try migrator?.runMigrationsIfNecessary(
                    migrationSQLForSchemaVersion: { version in
                        switch version {
                        case 2:
                            return """
                                INSERT INTO agents(name) VALUES('Sterling Archer');
                                INSERT INTO agents(name) VALUES('Lana Kane')
                                """

                        default:
                            return """
                                CREATE TABLE missions(id INTEGER PRIMARY KEY AUTOINCREMENT, payment REAL NOT NULL)
                                """
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
                migrationError = error
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        if willMigrate.count == 2 && didMigrate.count == 2 {
            XCTAssertEqual(willMigrate[0], 2)
            XCTAssertEqual(willMigrate[1], 3)

            XCTAssertEqual(didMigrate[0], 2)
            XCTAssertEqual(didMigrate[1], 3)
        } else {
            XCTFail("will and did migrate counts should be 2")
        }

        XCTAssertNil(migrationError)
        XCTAssertEqual(agentCount, 2)
        XCTAssertEqual(missionsTableExists, true)
    }

    func testThatMigratorCanRunMigrationsByDelegatingMigrationToTheCaller() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 2)

        let expectation = self.expectation(description: "migrations should complete successfully")

        var willMigrate: [UInt64] = []
        var didMigrate: [UInt64] = []
        var migrationError: Error? = nil
        var agentsTableExists: Bool?
        var agentCount: Int?

        // When
        DispatchQueue.utility.async {
            do {
                try migrator.runMigrationsIfNecessary(
                    migrateDatabaseToSchemaVersion: { version, connection in
                        switch version {
                        case 1:
                            try connection.execute(
                                "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
                            )
                        default:
                            try connection.execute("""
                                INSERT INTO agents(name) VALUES('Sterling Archer');
                                INSERT INTO agents(name) VALUES('Lana Kane')
                                """
                            )
                        }
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

                agentCount = try connection.query("SELECT count(*) FROM agents")
            } catch {
                migrationError = error
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        if willMigrate.count == 2 && didMigrate.count == 2 {
            XCTAssertEqual(willMigrate[0], 1)
            XCTAssertEqual(willMigrate[1], 2)

            XCTAssertEqual(didMigrate[0], 1)
            XCTAssertEqual(didMigrate[1], 2)
        } else {
            XCTFail("will and did migrate counts should be 2")
        }

        XCTAssertNil(migrationError)
        XCTAssertEqual(agentsTableExists, true)
        XCTAssertEqual(agentCount, 2)
    }

    func testThatMigratorGracefullyHandlesErrorEncounteredDuringMigration() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let migrator = Migrator(connection: connection, desiredSchemaVersion: 1)

        let expectation = self.expectation(description: "migrations should complete successfully")

        var willMigrate: [UInt64] = []
        var didMigrate: [UInt64] = []
        var migrationError: Error? = nil

        // When
        DispatchQueue.utility.async {
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
                migrationError = error
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(willMigrate.count, 1)
        XCTAssertEqual(didMigrate.count, 0)
        XCTAssertNotNil(migrationError)
    }
}
