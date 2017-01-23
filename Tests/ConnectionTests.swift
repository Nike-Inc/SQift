//
//  ConnectionTests.swift
//  SQift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
@testable import SQift
import XCTest

class ConnectionTestCase: XCTestCase {
    let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/connection_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Open and Close Tests

    func testThatConnectionCanOpenDatabaseConnection() {
        // Given, When, Then
        do {
            let _ = try Connection(storageLocation: storageLocation)
            let _ = try Connection(storageLocation: .inMemory)
            let _ = try Connection(storageLocation: .temporary)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionInitializationDefaultFlagsMatchConnectionPropertyValues() {
        do {
            // Given, When
            let connection = try Connection(storageLocation: storageLocation)

            // Then
            XCTAssertFalse(connection.readOnly)
            XCTAssertTrue(connection.threadSafe)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionInitializationCustomFlagsMatchConnectionPropertyValues() {
        do {
            // Given
            var writableConnection: Connection? = try Connection(storageLocation: storageLocation)
            try writableConnection?.execute("PRAGMA foreign_keys = true")
            let writableForeignKeys: Bool = try writableConnection?.query("PRAGMA foreign_keys") ?? false
            writableConnection = nil

            // When
            let readOnlyConnection = try Connection(storageLocation: storageLocation, readOnly: true, multiThreaded: false)
            let readOnlyForeignKeys: Bool = try readOnlyConnection.query("PRAGMA foreign_keys")

            // Then
            XCTAssertTrue(readOnlyConnection.readOnly)
            XCTAssertTrue(readOnlyConnection.threadSafe)
            XCTAssertTrue(writableForeignKeys)
            XCTAssertFalse(readOnlyForeignKeys)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanCloseDatabaseConnection() {
        do {
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
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Execution Tests

    func testThatConnectionCanExecutePragmaStatements() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When, Then
            try connection.execute("PRAGMA foreign_keys = true")
            try connection.execute("PRAGMA journal_mode = WAL")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanCreateTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When, Then
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanDropTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When, Then
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("DROP TABLE cars")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanInsertRowsIntoTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When, Then
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")
            try connection.execute("INSERT INTO cars VALUES(3, 'Skoda', 9000)")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanInsertThousandsOfRowsIntoTableUnderOneSecond() {
        do {
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
                let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)")

                for index in 1...20_000 {
                    try insert.bind("Sterling Archer-\(index)", "2015-10-02T08:20:00.000", 485, 240_000.10, jobTitle, "Charger").run()
                }
            }

            let timeInterval = start.timeIntervalSinceNow

            // Then
            XCTAssertLessThan(timeInterval, 1.000, "database should be able to insert 25_000 rows in under 1 second")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanUpdateRowsInTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When, Then
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("UPDATE cars SET price=89400 WHERE id=1")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanDeleteRowsInTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("DELETE FROM cars")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanSelectRowsInTable() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var rows: [[Any?]] = []

            // When
            for row in try connection.prepare("SELECT * FROM cars") {
                rows.append(row.values)
            }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Audi", "rows[0][1] should be `Audi`")
                XCTAssertEqual(rows[0][2] as? Int64, 52642, "rows[0][2] should be 52642")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Mercedes", "rows[1][1] should be `Mercedes`")
                XCTAssertEqual(rows[1][2] as? Int64, 57127, "rows[1][2] should be 57127")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanSelectColumnValuesFromRowUsingColumnNames() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var cars: [(String, UInt64)] = []

            // When
            for row in try connection.prepare("SELECT * FROM cars") {
                let name: String = row["name"]
                let price: UInt64 = row["price"]

                cars.append((name, price))
            }

            // Then
            if cars.count == 2 {
                XCTAssertEqual(cars[0].0, "Audi", "cars[0] name should be 'Audi'")
                XCTAssertEqual(cars[0].1, 52642, "cars[0].1 should be 52642")

                XCTAssertEqual(cars[1].0, "Mercedes", "cars[0] name should be 'Mercedes'")
                XCTAssertEqual(cars[1].1, 57127, "cars[0].1 should be 57127")
            } else {
                XCTFail("cars count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanSelectRowsInTableAndCaptureTheRowDescription() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var descriptions: [String] = []

            // When
            for row in try connection.prepare("SELECT * FROM cars WHERE price > ?", 20_000) {
                descriptions.append(row.description)
            }

            // Then
            if descriptions.count == 2 {
                XCTAssertEqual(descriptions[0], "[1, 'Audi', 52642]")
                XCTAssertEqual(descriptions[1], "[2, 'Mercedes', 57127]")
            } else {
                XCTFail("row count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanFetchFirstRowOfSelectStatement() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var car: (String, UInt64)?

            // When
            if
                let row = try connection.fetch("SELECT * FROM cars WHERE name='Audi'"),
                let name: String = row["name"],
                let price: UInt64 = row["price"]
            {
                car = (name, price)
            }

            // Then
            XCTAssertEqual(car?.0, "Audi", "car 0 should be 'Audi'")
            XCTAssertEqual(car?.1, 52642, "car 1 should be 52642")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Binding Tests

    func testThatConnectionCanBindParametersToStatement() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, date TEXT)")

            let date: Date = {
                var components = DateComponents()
                components.year = 2015
                components.month = 11
                components.day = 8

                let gregorianCalendar = Calendar(identifier: .gregorian)

                return gregorianCalendar.date(from: components)!
            }()

            // When
            try connection.prepare("INSERT INTO cars VALUES(?, ?, ?, ?)").bind(1, "Audi", 52642, date).run()

            var row: [Any?] = []

            for insertedRow in try connection.prepare("SELECT * FROM cars") {
                row = insertedRow.values
            }

            // Then
            if row.count == 4 {
                XCTAssertEqual(row[0] as? Int64, 1, "item 0 should be 1")
                XCTAssertEqual(row[1] as? String, "Audi", "item 1 should be 'Audi'")
                XCTAssertEqual(row[2] as? Int64, 52642, "item 2 should be 52642")

                if let dateString = row[3] as? String {
                    let insertedDate = BindingDateFormatter.date(from: dateString)
                    XCTAssertEqual(insertedDate, date, "item 3 converted date should equal original date")
                } else {
                    XCTFail("item 4 should be a String type")
                }
            } else {
                XCTFail("rows count should be 1")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanBindNamedParametersToStatement() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, dup_name TEXT)")

            // When
            let parameters1: [String: Bindable?] = ["?1": 1, "?2": "Audi", "?3": 52642]
            try connection.prepare("INSERT INTO cars VALUES(?1, ?2, ?3, ?2)").bind(parameters1).run()

            let parameters2: [String: Bindable?] = [":id": 2, ":name": "Mercedes", ":price": 57127]
            try connection.run("INSERT INTO cars VALUES(:id, :name, :price, :name)", parameters2)

            let rows = try connection.prepare("SELECT * FROM cars").map { $0.values }
            let audiCount: Int = try connection.query("SELECT * FROM cars WHERE name = :name", [":name": "Audi"])
            let hondaCount: Int? = try connection.query("SELECT * FROM cars WHERE name = :name", [":name": "Honda"])

            // Then
            XCTAssertEqual(audiCount, 1, "audi count should be 1")
            XCTAssertEqual(hondaCount, nil, "honda count should be 0")

            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Audi", "rows[0][1] should be `Audi`")
                XCTAssertEqual(rows[0][2] as? Int64, 52642, "rows[0][2] should be 52642")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Mercedes", "rows[1][1] should be `Mercedes`")
                XCTAssertEqual(rows[1][2] as? Int64, 57127, "rows[1][2] should be 57127")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Transaction and Savepoint Tests

    func testThatConnectionCanExecuteTransaction() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            try connection.transaction {
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
            }

            let rows = try connection.prepare("SELECT * FROM cars").map { $0.values }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Audi", "rows[0][1] should be `Audi`")
                XCTAssertEqual(rows[0][2] as? Int64, 52642, "rows[0][2] should be 52642")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Mercedes", "rows[1][1] should be `Mercedes`")
                XCTAssertEqual(rows[1][2] as? Int64, 57127, "rows[1][2] should be 57127")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanRollbackTransactionExecutionWhenTransactionThrows() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            do {
                try connection.transaction {
                    try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                    try connection.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            } catch {
                // No-op: this is expected due to invalid SQL in second prepare statement
            }

            let count: Int = try connection.query("SELECT count(*) FROM cars")

            // Then
            XCTAssertEqual(count, 0, "count should be zero")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanExecuteSavepoint() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            try connection.savepoint("'savepoint-1'") {
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

                try connection.savepoint("'savepoint    2") {
                    try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            }

            // When
            let rows = try connection.prepare("SELECT * FROM cars").map { $0.values }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Audi", "rows[0][1] should be `Audi`")
                XCTAssertEqual(rows[0][2] as? Int64, 52642, "rows[0][2] should be 52642")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Mercedes", "rows[1][1] should be `Mercedes`")
                XCTAssertEqual(rows[1][2] as? Int64, 57127, "rows[1][2] should be 57127")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanRollbackToSavepointWhenSavepointExecutionThrows() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            do {
                try connection.savepoint("save-it-up") {
                    try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                    try connection.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            } catch {
                // No-op: this is expected due to invalid SQL in second prepare statement
            }

            let count: Int = try connection.query("SELECT count(*) FROM cars")

            // Then
            XCTAssertEqual(count, 0, "count should be zero")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanExecuteSavepointsWithCrazyCharactersInName() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            try connection.savepoint("savè mę 😱 \n\r\n nõw \n plèãśę  ") {
                try connection.run("INSERT INTO cars VALUES(?, ?, ?)", 1, "Audi", 52642)

                try connection.savepoint("  save with' random \" chàracters") {
                    try connection.run("INSERT INTO cars VALUES(?, ?, ?)", 2, "Mercedes", 57127)
                }
            }

            // When
            let rows = try connection.prepare("SELECT * FROM cars").map { $0.values }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Audi", "rows[0][1] should be `Audi`")
                XCTAssertEqual(rows[0][2] as? Int64, 52642, "rows[0][2] should be 52642")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Mercedes", "rows[1][1] should be `Mercedes`")
                XCTAssertEqual(rows[1][2] as? Int64, 57127, "rows[1][2] should be 57127")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Attach Database Tests

    func testThatConnectionCanAttachAndDetachDatabase() {
        let personDBPath = FileManager.cachesDirectory.appending("/attach_detach_db_tests.db")
        defer { FileManager.removeItem(atPath: personDBPath) }

        do {
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
            let rows = try connection1.prepare("SELECT * FROM person").map { $0.values }

            try connection1.detachDatabase(named: "personDB")

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1, "rows[0][0] should be 1")
                XCTAssertEqual(rows[0][1] as? String, "Sterling Archer", "rows[0][1] should be `Sterling Archer`")

                XCTAssertEqual(rows[1][0] as? Int64, 2, "rows[1][0] should be 2")
                XCTAssertEqual(rows[1][1] as? String, "Lana Kane", "rows[1][1] should be `Lana Kane`")
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Trace Tests

    func testThatConnectionCanTraceStatementExecution() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            var statements: [String] = []

            // When
            connection.trace { SQL in
                statements.append(SQL)
            }

            try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()

            try connection.prepare("SELECT * FROM agents").forEach { _ in /** No-op */ }

            connection.trace(nil)

            // Then
            if statements.count == 4 {
                XCTAssertEqual(statements[0], "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                XCTAssertEqual(statements[1], "INSERT INTO agents VALUES(1, 'Sterling Archer')")
                XCTAssertEqual(statements[2], "INSERT INTO agents VALUES(2, 'Lana Kane')")
                XCTAssertEqual(statements[3], "SELECT * FROM agents")
            } else {
                XCTFail("statements count should be 4")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanTraceStatementEventExecution() {
        if #available(iOS 10.0, OSX 10.12.0, tvOS 10.0, watchOS 3.0, *) {
            do {
                // Given
                var connection: Connection? = try Connection(storageLocation: storageLocation)

                let mask = (
                    Connection.TraceEvent.statementMask |
                    Connection.TraceEvent.profileMask |
                    Connection.TraceEvent.rowMask |
                    Connection.TraceEvent.connectionClosedMask
                )

                var traceEvents: [Connection.TraceEvent] = []

                // When
                connection?.traceEvent(mask: mask) { event in
                    traceEvents.append(event)
                }

                try connection?.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()

                try connection?.prepare("SELECT * FROM agents").forEach { _ in /** No-op */ }

                connection = nil

                // Then
                if traceEvents.count == 11 {
                    XCTAssertEqual(traceEvents[0].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[1].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[2].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[3].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[4].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[5].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[6].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[7].rawValue, "Row")
                    XCTAssertEqual(traceEvents[8].rawValue, "Row")
                    XCTAssertEqual(traceEvents[9].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[10].rawValue, "ConnectionClosed")

                    if case let .statement(statement, sql) = traceEvents[0] {
                        XCTAssertEqual(statement, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                        XCTAssertEqual(sql, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[1] {
                        XCTAssertEqual(statement, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[2] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(1, \'Sterling Archer\')")
                        XCTAssertEqual(sql, "INSERT INTO agents VALUES(?, ?)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[3] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(1, \'Sterling Archer\')")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[4] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(2, \'Lana Kane\')")
                        XCTAssertEqual(sql, "INSERT INTO agents VALUES(?, ?)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[5] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(2, \'Lana Kane\')")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[6] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                        XCTAssertEqual(sql, "SELECT * FROM agents")
                    }

                    if case let .row(statement) = traceEvents[7] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                    }

                    if case let .row(statement) = traceEvents[8] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                    }

                    if case let .profile(statement, seconds) = traceEvents[9] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }
                } else {
                    XCTFail("traceEvents count should be 10")
                }
            } catch {
                XCTFail("Test Encountered Unexpected Error: \(error)")
            }
        }
    }

    func testThatConnectionCanTraceStatementEventExecutionUsingMask() {
        if #available(iOS 10.0, OSX 10.12.0, tvOS 10.0, watchOS 3.0, *) {
            do {
                // Given
                var connection: Connection? = try Connection(storageLocation: storageLocation)
                var traceEvents: [Connection.TraceEvent] = []

                // When
                connection?.traceEvent(mask: Connection.TraceEvent.statementMask | Connection.TraceEvent.profileMask) { event in
                    traceEvents.append(event)
                }

                try connection?.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()

                try connection?.prepare("SELECT * FROM agents").forEach { _ in /** No-op */ }

                connection = nil

                // Then
                XCTAssertEqual(traceEvents.count, 8)
            } catch {
                XCTFail("Test Encountered Unexpected Error: \(error)")
            }
        }
    }

    // MARK: - Collation Tests

    func testThatConnectionCanCreateAndExecuteCustomNumericCollationFunction() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            connection.createCollation(withName: "NUMERIC") { lhs, rhs in
                return lhs.compare(rhs, options: .numeric, locale: Locale.autoupdatingCurrent)
            }

            try connection.execute("DROP TABLE IF EXISTS test")
            try connection.execute("CREATE TABLE test(text TEXT COLLATE 'NUMERIC' NOT NULL)")

            let inserted = ["string 1", "string 21", "string 12", "string 11", "string 02"]
            let expected = ["string 1", "string 02", "string 11", "string 12", "string 21"]

            try inserted.forEach { try connection.run("INSERT INTO test(text) VALUES(?)", $0) }

            // When
            let extracted: [String] = try connection.prepare("SELECT * FROM test ORDER BY text").map { $0[0] }

            // Then
            XCTAssertEqual(extracted, expected, "extracted strings array should match expected strings array")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanCreateAndExecuteCustomDiacriticCollationFunction() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let options: String.CompareOptions = [.literal, .widthInsensitive, .forcedOrdering]

            connection.createCollation(withName: "DIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: options, locale: Locale.autoupdatingCurrent)
            }

            try connection.execute("DROP TABLE IF EXISTS test")
            try connection.execute("CREATE TABLE test(text TEXT COLLATE 'DIACRITIC' NOT NULL)")

            let inserted = ["o", "ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"]
            let expected = ["o", "ó", "ò", "ô", "ö", "õ", "ø", "ō", "œ"]

            try inserted.forEach { try connection.run("INSERT INTO test(text) VALUES(?)", $0) }

            // When
            let extracted: [String] = try connection.prepare("SELECT * FROM test ORDER BY text").map { $0[0] }

            // Then
            XCTAssertEqual(extracted, expected, "extracted strings array should match expected strings array")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanReplaceCustomCollationFunctionOnTheFly() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            connection.createCollation(withName: "NODIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: .diacriticInsensitive, locale: Locale.autoupdatingCurrent)
            }

            let equal1: Bool = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            connection.createCollation(withName: "NODIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: [], locale: Locale.autoupdatingCurrent)
            }

            let equal2: Bool = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            // Then
            XCTAssertTrue(equal1, "equal 1 should be true when using `.DiacriticInsensitiveSearch` compare options")
            XCTAssertFalse(equal2, "equal 2 should be false when using default compare options")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}

// MARK: -

extension Connection.TraceEvent {
    var rawValue: String {
        switch self {
        case .statement:
            return "Statement"
        case .profile:
            return "Profile"
        case .row:
            return "Row"
        case .connectionClosed:
            return "ConnectionClosed"
        }
    }
}
