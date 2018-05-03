//
//  ConnectionTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
@testable import SQift
import SQLite3
import XCTest

class ConnectionTestCase: BaseTestCase {

    // MARK: - Tests - Open and Close Connection

    func testThatConnectionCanOpenDatabaseConnection() throws {
        // Given, When, Then
        let _ = try Connection(storageLocation: storageLocation)
        let _ = try Connection(storageLocation: .inMemory)
        let _ = try Connection(storageLocation: .temporary)
    }

    func testThatConnectionInitializationDefaultFlagsMatchConnectionPropertyValues() throws {
        // Given, When
        let connection = try Connection(storageLocation: storageLocation)

        // Then
        XCTAssertFalse(connection.readOnly)
        XCTAssertTrue(connection.threadSafe)
    }

    func testThatConnectionInitializationCustomFlagsMatchConnectionPropertyValues() throws {
        // Given
        var writableConnection: Connection? = try Connection(storageLocation: storageLocation)
        try writableConnection?.execute("PRAGMA foreign_keys = true")
        let writableForeignKeys: Bool = try writableConnection?.query("PRAGMA foreign_keys") ?? false
        writableConnection = nil

        // When
        let readOnlyConnection = try Connection(storageLocation: storageLocation, readOnly: true, multiThreaded: false)
        let readOnlyForeignKeys: Bool? = try readOnlyConnection.query("PRAGMA foreign_keys")

        // Then
        XCTAssertEqual(readOnlyConnection.readOnly, true)
        XCTAssertEqual(readOnlyConnection.threadSafe, true)
        XCTAssertEqual(writableForeignKeys, true)
        XCTAssertEqual(readOnlyForeignKeys, false)
    }

    func testThatConnectionCanCloseDatabaseConnection() throws {
        // Given
        var onDiskConnection: Connection? = try Connection(storageLocation: storageLocation)
        var inMemoryConnection: Connection? = try Connection(storageLocation: .inMemory)
        var temporaryConnection: Connection? = try Connection(storageLocation: .temporary)

        // When, Then
        try onDiskConnection?.execute("PRAGMA foreign_keys = true")
        onDiskConnection = nil

        try inMemoryConnection?.execute("PRAGMA foreign_keys = true")
        inMemoryConnection = nil

        try temporaryConnection?.execute("PRAGMA foreign_keys = true")
        temporaryConnection = nil
    }

    // MARK: - Tests - Execution

    func testThatConnectionCanExecutePragmaStatements() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When, Then
        try connection.execute("""
            PRAGMA foreign_keys = true;
            PRAGMA journal_mode = WAL
            """
        )
    }

    func testThatConnectionCanCreateTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When, Then
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
    }

    func testThatConnectionCanDropTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When, Then
        try connection.execute("""
            CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER);
            DROP TABLE cars
            """
        )
    }

    func testThatConnectionCanInsertRowsIntoTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When, Then
        try connection.execute("""
            CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER);
            INSERT INTO cars VALUES(1, 'Audi', 52642);
            INSERT INTO cars VALUES(2, 'Mercedes', 57127);
            INSERT INTO cars VALUES(3, 'Skoda', 9000)
            """
        )
    }

    func testThatConnectionCanInsertThousandsOfRowsIntoTableUnderOneSecond() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("PRAGMA synchronous = NORMAL")
        try connection.execute("PRAGMA journal_mode = WAL")
        try TestTables.createAndPopulateAgentsTable(using: connection)

        // NOTE: Most machines can insert ~25_000 rows per second with these settings. May need to decrease the
        // number of rows on CI machines due to running inside a VM.

        // When
        let start = Date()

        try connection.transaction {
            let jobTitle = "Superman".data(using: .utf8)!
            let insert = try connection.prepare("""
                INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)
                """
            )

            for index in 1...20_000 {
                try insert.bind("Sterling Archer-\(index)", "2015-10-02T08:20:00.000", 485, 240_000.10, jobTitle, "Charger").run()
            }
        }

        let timeInterval = start.timeIntervalSinceNow

        // Then
        XCTAssertLessThan(timeInterval, 1.000, "database should be able to insert 25_000 rows in under 1 second")
    }

    func testThatConnectionCanUpdateRowsInTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When, Then
        try connection.execute("""
            CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER);
            INSERT INTO cars VALUES(1, 'Audi', 52642);
            UPDATE cars SET price = 89400 WHERE id = 1
            """
        )
    }

    func testThatConnectionCanDeleteRowsInTable() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When
        try connection.execute("""
            CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER);
            INSERT INTO cars VALUES(1, 'Audi', 52642);
            DELETE FROM cars
            """
        )
    }

    // MARK: - Tests - Interrupt

    func testThatConnectionCanInterruptLongRunningOperation() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        try connection.transaction {
            let statement = try connection.prepare("INSERT INTO cars(name, price) VALUES(?, ?)")
            try (1...10_000).forEach { try statement.bind("BMW", $0).run() }
        }

        let expectation = self.expectation(description: "transaction should be cancelled")
        var prices: [Int]?
        var queryError: Error?

        // When
        DispatchQueue.utility.async {
            do {
                prices = try connection.query("SELECT price FROM cars")
                expectation.fulfill()
            } catch {
                queryError = error
                expectation.fulfill()
            }
        }

        DispatchQueue.utility.asyncAfter(seconds: 0.005) { connection.interrupt() }
        waitForExpectations(timeout: 5, handler: nil)

        // Then (sometimes interrupt won't stop the query prior to completion)
        if let prices = prices {
            XCTAssertNil(queryError)
            XCTAssertEqual(prices.count, 10_000)
        } else {
            XCTAssertNil(prices)
            XCTAssertNotNil(queryError)

            if let error = queryError as? SQLiteError {
                XCTAssertEqual(error.code, SQLITE_INTERRUPT)
                XCTAssertEqual(error.message, "interrupted")
            }
        }
    }

    // MARK: - Tests - FTS4

    func testThatConnectionSupportsFTS4Module() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        try connection.execute("""
            CREATE VIRTUAL TABLE email USING fts4(sender, title, body);
            INSERT INTO email VALUES('Christian Noon', 'iOS Architectures', 'There are so many possibilities');
            INSERT INTO email VALUES('Dave Camp', 'SQift Features', 'Should we support so many SQLite APIs?')
            """
        )

        // When
        let emailRowCount: Int? = try connection.query("SELECT count(1) FROM email")
        let senders1: [String] = try connection.query("SELECT sender FROM email WHERE email MATCH 'many'")
        let senders2: [String] = try connection.query("SELECT sender FROM email WHERE body MATCH 'so NOT support'")

        // Then
        XCTAssertEqual(emailRowCount, 2)
        XCTAssertEqual(senders1, ["Christian Noon", "Dave Camp"])
        XCTAssertEqual(senders2, ["Christian Noon"])
    }

    // MARK: - Tests - Attach Database

    func testThatConnectionCanAttachAndDetachDatabase() throws {
        let personDBPath = FileManager.cachesDirectory.appending("/attach_detach_db_tests.db")
        defer { FileManager.removeItem(atPath: personDBPath) }

        // Given
        let connection1 = try Connection(storageLocation: storageLocation)
        try connection1.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
        try connection1.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

        var connection2: Connection? = try Connection(storageLocation: .onDisk(personDBPath))
        try connection2?.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT)")
        try connection2?.prepare("INSERT INTO person VALUES(?, ?)").bind(1, "Sterling Archer").run()

        connection2 = nil

        // When
        try connection1.attachDatabase(from: StorageLocation.onDisk(personDBPath), withName: "personDB")
        try connection1.prepare("INSERT INTO person VALUES(?, ?)").bind(2, "Lana Kane").run()
        let rows: [[Any?]] = try connection1.query("SELECT * FROM person") { $0.values }

        try connection1.detachDatabase(named: "personDB")

        // Then
        if rows.count == 2 {
            XCTAssertEqual(rows[0][0] as? Int64, 1)
            XCTAssertEqual(rows[0][1] as? String, "Sterling Archer")

            XCTAssertEqual(rows[1][0] as? Int64, 2)
            XCTAssertEqual(rows[1][1] as? String, "Lana Kane")
        } else {
            XCTFail("rows count should be 2")
        }
    }
}
