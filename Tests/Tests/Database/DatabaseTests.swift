//
//  DatabaseTests.swift
//  SQift
//
//  Created by Christian Noon on 11/17/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class DatabaseTestCase: BaseTestCase {

    // MARK: - Helper Types

    private struct Person: ExpressibleByRow, CustomStringConvertible {
        let id: Int64
        let firstName: String
        let lastName: String

        var description: String { return firstName + " " + lastName }

        init(row: Row) throws {
            self.id = row[0]
            self.firstName = row[1]
            self.lastName = row[2]
        }
    }

    // MARK: - Tests

    func testThatDatabaseCanBeInitializedWithAllStorageLocations() {
        // Given, When, Then
        do {
            let _ = try Database(storageLocation: storageLocation)
            let _ = try Database(storageLocation: .inMemory)
            let _ = try Database(storageLocation: .temporary)
            let _ = try Database(storageLocation: storageLocation, flags: SQLITE_OPEN_READONLY)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatDatabaseInitializationExecutesWriterConnectionPreparationClosure() {
        do {
            // Given
            let database = try Database(
                storageLocation: storageLocation,
                writerConnectionPreparation: { connection in
                    try connection.execute("PRAGMA foreign_keys = ON")
                    try connection.execute("PRAGMA synchronous = 1")
                }
            )

            var foreignKeys: Int?
            var synchronous: Int? = 0

            // When
            try database.writerConnectionQueue.execute { connection in
                foreignKeys = try connection.query("PRAGMA foreign_keys")
                synchronous = try connection.query("PRAGMA synchronous")
            }

            // Then
            XCTAssertEqual(foreignKeys, 1)
            XCTAssertEqual(synchronous, 1)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatDatabaseFailsToInitializeWithInvalidOnDiskStorageLocation() {
        do {
            // Given, When
            let _ = try Database(storageLocation: .onDisk("/path/does/not/exist"))

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDatabaseCanExecuteRead() {
        do {
            // Given, When, Then
            let database = try Database(storageLocation: storageLocation)

            // When
            var areValuesEqual: Bool?

            try database.executeRead { connection in
                areValuesEqual = try connection.query("SELECT ? = ?", 1, 2)
            }

            // Then
            XCTAssertEqual(areValuesEqual, false)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatDatabaseCanExecuteWrite() {
        do {
            // Given, When, Then
            let database = try Database(storageLocation: storageLocation)

            // When
            var tableExists: Bool?

            try database.executeWrite { connection in
                try connection.run("CREATE TABLE agent(name TEXT PRIMARY KEY)")
                tableExists = try connection.query("SELECT count(*) FROM sqlite_master WHERE type = ?", "table")
            }

            // Then
            XCTAssertEqual(tableExists, true)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatDatabaseCanSpitUpNewReadConnectionsThatContainLatestWrittenChanges() {
        do {
            // Given
            let database = try Database(
                storageLocation: storageLocation,
                multiThreaded: true,
                sharedCache: true,
                writerConnectionPreparation: { connection in
                    try connection.execute("""
                        PRAGMA journal_mode = WAL;
                        PRAGMA cache_size = -10000
                        """
                    ) // 10 MB max in-memory cache size
                }
            )

            try database.executeWrite { connection in
                try connection.execute("""
                    CREATE TABLE person(id INTEGER PRIMARY KEY, first_name TEXT NOT NULL, last_name TEXT NOT NULL)
                    """
                )

                try TestTables.createAndPopulateAgentsTable(using: connection)
                try TestTables.insertDummyAgents(count: 10_000, connection: connection)
            }

            let expectation = self.expectation(description: "Query should return agents and blocks checkpointing")
            var agentQueryError: Error?
            var agents: [Agent]?

            DispatchQueue.userInitiated.async {
                do {
                    try database.executeRead { agents = try $0.query("SELECT * FROM agents") }
                    expectation.fulfill()
                } catch {
                    agentQueryError = error
                }
            }

            var writeError: Error?
            var readError1: Error?
            var readError2: Error?
            var personBeforeCheckpoint1: Person?
            var personBeforeCheckpoint2: Person?

            // When
            DispatchQueue.userInitiated.asyncAfter(seconds: 0.1) {
                do {
                    try database.executeWrite { connection in
                        try connection.execute("INSERT INTO person(first_name, last_name) VALUES('Sterling', 'Archer')")
                    }

                    DispatchQueue.userInitiated.async {
                        do {
                            try database.executeRead { connection in
                                personBeforeCheckpoint1 = try connection.query("SELECT * FROM person WHERE id = 1")
                            }
                        } catch {
                            readError1 = error
                        }
                    }

                    DispatchQueue.userInitiated.async {
                        do {
                            try database.executeRead { connection in
                                personBeforeCheckpoint2 = try connection.query("SELECT * FROM person WHERE id = 1")
                            }
                        } catch {
                            readError2 = error
                        }
                    }
                } catch {
                    writeError = error
                }
            }

            waitForExpectations(timeout: timeout, handler: nil)

            var personAfterCheckpoint: Person?
            try database.executeRead { personAfterCheckpoint = try $0.query("SELECT * FROM person WHERE id = 1") }

            var cacheSize: Int64 = -1
            var pageSize: Int64 = -1

            try database.executeRead { cacheSize = try $0.query("PRAGMA cache_size") ?? -1 }
            try database.executeRead { pageSize = try $0.query("PRAGMA page_size") ?? -1 }

            // Then
            XCTAssertNil(agentQueryError)
            XCTAssertEqual(agents?.count, 10_002)

            XCTAssertNil(writeError)
            XCTAssertNil(readError1)
            XCTAssertNil(readError2)

            XCTAssertEqual(personBeforeCheckpoint1?.firstName, "Sterling")
            XCTAssertEqual(personBeforeCheckpoint1?.lastName, "Archer")

            XCTAssertEqual(personBeforeCheckpoint2?.firstName, "Sterling")
            XCTAssertEqual(personBeforeCheckpoint2?.lastName, "Archer")

            XCTAssertEqual(personAfterCheckpoint?.firstName, "Sterling")
            XCTAssertEqual(personAfterCheckpoint?.lastName, "Archer")

            XCTAssertEqual(cacheSize, -10_000)
            XCTAssertEqual(pageSize, 4_096)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
