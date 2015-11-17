//
//  ConnectionTests.swift
//  SQift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class ConnectionTestCase: XCTestCase {
    let connectionType: Connection.ConnectionType = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/database_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(connectionType.path)
    }

    // MARK: - Open and Close Tests

    func testThatConnectionCanOpenDatabaseConnection() {
        // Given, When, Then
        do {
            let _ = try Connection(connectionType: connectionType)
            let _ = try Connection(connectionType: .InMemory)
            let _ = try Connection(connectionType: .Temporary)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionInitializationWithDefaultFlagsMatchConnectionPropertyValues() {
        do {
            // Given, When
            let connection = try Connection(connectionType: connectionType)

            // Then
            XCTAssertFalse(connection.readOnly)
            XCTAssertTrue(connection.threadSafe)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionInitializationWithCustomFlagsMatchConnectionPropertyValues() {
        do {
            // Given
            var writableConnection: Connection? = try Connection(connectionType: connectionType)
            try writableConnection?.execute("PRAGMA foreign_keys = true")
            writableConnection = nil

            // When
            let readOnlyConnection = try Connection(connectionType: connectionType, readOnly: true, multiThreaded: false)

            // Then
            XCTAssertTrue(readOnlyConnection.readOnly)
            XCTAssertTrue(readOnlyConnection.threadSafe)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanCloseDatabaseConnection() {
        do {
            // Given
            var onDiskConnection: Connection? = try Connection(connectionType: connectionType)
            var inMemoryConnection: Connection? = try Connection(connectionType: .InMemory)
            var temporaryConnection: Connection? = try Connection(connectionType: .Temporary)

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
            let connection = try Connection(connectionType: connectionType)

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
            let connection = try Connection(connectionType: connectionType)

            // When, Then
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanDropTable() {
        do {
            // Given
            let connection = try Connection(connectionType: connectionType)

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
            let connection = try Connection(connectionType: connectionType)

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
            let connection = try Connection(connectionType: connectionType)
            try connection.execute("PRAGMA synchronous = NORMAL")
            try connection.execute("PRAGMA journal_mode = WAL")
            try TestTables.createAndPopulateAgentsTable(connection)

            // NOTE: Most machines can insert ~25_000 rows per second with these settings. May need to decrease the
            // number of rows on CI machines due to running inside a VM.

            // When
            let start = NSDate()

            try connection.transaction {
                let jobTitle = "Superman".dataUsingEncoding(NSUTF8StringEncoding)!
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
            let connection = try Connection(connectionType: connectionType)

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
            let connection = try Connection(connectionType: connectionType)

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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var car: (String, UInt64)?

            // When
            let row = try connection.fetch("SELECT * FROM cars WHERE name='Audi'")

            if let name: String = row["name"], let price: UInt64 = row["price"] {
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
            let connection = try Connection(connectionType: connectionType)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, date TEXT)")

            let date: NSDate = {
                let components = NSDateComponents()
                components.year = 2015
                components.month = 11
                components.day = 8

                let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!

                return gregorianCalendar.dateFromComponents(components)!
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
                    let insertedDate = BindingDateFormatter.dateFromString(dateString)
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
            let connection = try Connection(connectionType: connectionType)
            try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, dup_name TEXT)")

            // When
            let parameters1: [String: Bindable?] = ["?1": 1, "?2": "Audi", "?3": 52642]
            try connection.prepare("INSERT INTO cars VALUES(?1, ?2, ?3, ?2)").bind(parameters1).run()

            let parameters2: [String: Bindable?] = [":id": 2, ":name": "Mercedes", ":price": 57127]
            try connection.prepare("INSERT INTO cars VALUES(:id, :name, :price, :name)").bind(parameters2).run()

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

    // MARK: - Transaction and Savepoint Tests

    func testThatConnectionCanExecuteTransaction() {
        do {
            // Given
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
            let connection = try Connection(connectionType: connectionType)
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
        let personDBPath = NSFileManager.documentsDirectory.stringByAppendingString("/attach_detach_db_tests.db")
        defer { NSFileManager.removeItemAtPath(personDBPath) }

        do {
            // Given
            let connection1 = try Connection(connectionType: connectionType)
            try connection1.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try connection1.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

            var connection2: Connection? = try Connection(connectionType: .OnDisk(personDBPath))
            try connection2?.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT)")
            try connection2?.prepare("INSERT INTO person VALUES(?, ?)").bind(1, "Sterling Archer").run()

            connection2 = nil

            // When
            try connection1.attachDatabase(.OnDisk(personDBPath), withName: "personDB")
            try connection1.prepare("INSERT INTO person VALUES(?, ?)").bind(2, "Lana Kane").run()
            let rows = try connection1.prepare("SELECT * FROM person").map { $0.values }

            try connection1.detachDatabase("personDB")

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
            let connection = try Connection(connectionType: connectionType)

            var statements: [String] = []

            // When
            connection.trace { SQL in
                statements.append(SQL)
            }

            try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()

            try connection.prepare("SELECT * FROM agents").forEach { _ in /** No-op */ }

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
}
