//
//  DatabaseTests.swift
//  SQift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class DatabaseTestCase: XCTestCase {
    let databaseType: Database.DatabaseType = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/database_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(databaseType.path)
    }

    // MARK: - Open and Close Tests

    func testThatDatabaseCanOpenDatabase() {
        // Given, When, Then
        do {
            let _ = try Database(databaseType: databaseType)
            let _ = try Database(databaseType: .InMemory)
            let _ = try Database(databaseType: .Temporary)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseInitializationDefaultFlagsMatchDatabasePropertyValues() {
        do {
            // Given, When
            let database = try Database(databaseType: databaseType)

            // Then
            XCTAssertFalse(database.readOnly)
            XCTAssertTrue(database.threadSafe)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseInitializationCustomFlagsMatchDatabasePropertyValues() {
        do {
            // Given
            var writableDatabase: Database? = try Database(databaseType: databaseType)
            try writableDatabase?.execute("PRAGMA foreign_keys = true")
            writableDatabase = nil

            // When
            let readOnlyDatabase = try Database(databaseType: databaseType, readOnly: true, multiThreaded: false)

            // Then
            XCTAssertTrue(readOnlyDatabase.readOnly)
            XCTAssertTrue(readOnlyDatabase.threadSafe)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanCloseDatabase() {
        do {
            // Given
            var onDiskDatabase: Database? = try Database(databaseType: databaseType)
            var inMemoryDatabase: Database? = try Database(databaseType: .InMemory)
            var temporaryDatabase: Database? = try Database(databaseType: .Temporary)

            // When, Then
            try onDiskDatabase?.execute("PRAGMA foreign_keys = true")
            onDiskDatabase = nil

            try inMemoryDatabase?.execute("PRAGMA foreign_keys = true")
            inMemoryDatabase = nil

            try temporaryDatabase?.execute("PRAGMA foreign_keys = true")
            temporaryDatabase = nil
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Execution Tests

    func testThatDatabaseCanExecutePragmaStatements() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When, Then
            try database.execute("PRAGMA foreign_keys = true")
            try database.execute("PRAGMA journal_mode = WAL")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanCreateTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When, Then
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanDropTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When, Then
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("DROP TABLE cars")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanInsertRowsIntoTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When, Then
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")
            try database.execute("INSERT INTO cars VALUES(3, 'Skoda', 9000)")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanInsertThousandsOfRowsIntoTableUnderOneSecond() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("PRAGMA synchronous = NORMAL")
            try database.execute("PRAGMA journal_mode = WAL")
            try TestTables.createAndPopulateAgentsTableInDatabase(database)

            // NOTE: Most machines can insert ~25_000 rows per second with these settings. May need to decrease the
            // number of rows on CI machines due to running inside a VM.

            // When
            let start = NSDate()

            try database.transaction {
                let jobTitle = "Superman".dataUsingEncoding(NSUTF8StringEncoding)!
                let insert = try database.prepare("INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)")

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

    func testThatDatabaseCanUpdateRowsInTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When, Then
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("UPDATE cars SET price=89400 WHERE id=1")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanDeleteRowsInTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("DELETE FROM cars")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanSelectRowsInTable() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var rows: [[Any?]] = []

            // When
            for row in try database.prepare("SELECT * FROM cars") {
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

    func testThatDatabaseCanSelectColumnValuesFromRowUsingColumnNames() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var cars: [(String, UInt64)] = []

            // When
            for row in try database.prepare("SELECT * FROM cars") {
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

    func testThatDatabaseCanSelectRowsInTableAndCaptureTheRowDescription() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var descriptions: [String] = []

            // When
            for row in try database.prepare("SELECT * FROM cars WHERE price > ?", 20_000) {
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

    func testThatDatabaseCanFetchFirstRowOfSelectStatement() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
            try database.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

            var car: (String, UInt64)?

            // When
            let row = try database.fetch("SELECT * FROM cars WHERE name='Audi'")

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

    func testThatDatabaseCanBindParametersToStatement() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, date TEXT)")

            let date: NSDate = {
                let components = NSDateComponents()
                components.year = 2015
                components.month = 11
                components.day = 8

                let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!

                return gregorianCalendar.dateFromComponents(components)!
            }()

            // When
            try database.prepare("INSERT INTO cars VALUES(?, ?, ?, ?)").bind(1, "Audi", 52642, date).run()

            var row: [Any?] = []

            for insertedRow in try database.prepare("SELECT * FROM cars") {
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

    func testThatDatabaseCanBindNamedParametersToStatement() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, dup_name TEXT)")

            // When
            let parameters1: [String: Bindable?] = ["?1": 1, "?2": "Audi", "?3": 52642]
            try database.prepare("INSERT INTO cars VALUES(?1, ?2, ?3, ?2)").bind(parameters1).run()

            let parameters2: [String: Bindable?] = [":id": 2, ":name": "Mercedes", ":price": 57127]
            try database.prepare("INSERT INTO cars VALUES(:id, :name, :price, :name)").bind(parameters2).run()

            let rows = try database.prepare("SELECT * FROM cars").map { $0.values }

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

    func testThatDatabaseCanExecuteTransaction() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            try database.transaction {
                try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
            }

            let rows = try database.prepare("SELECT * FROM cars").map { $0.values }

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

    func testThatDatabaseCanRollbackTransactionExecutionWhenTransactionThrows() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            do {
                try database.transaction {
                    try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                    try database.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            } catch {
                // No-op: this is expected due to invalid SQL in second prepare statement
            }

            let count: Int = try database.query("SELECT count(*) FROM cars")

            // Then
            XCTAssertEqual(count, 0, "count should be zero")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanExecuteSavepoint() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            try database.savepoint("'savepoint-1'") {
                try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

                try database.savepoint("'savepoint    2") {
                    try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            }

            // When
            let rows = try database.prepare("SELECT * FROM cars").map { $0.values }

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

    func testThatDatabaseCanRollbackToSavepointWhenSavepointExecutionThrows() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

            // When
            do {
                try database.savepoint("save-it-up") {
                    try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                    try database.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
                }
            } catch {
                // No-op: this is expected due to invalid SQL in second prepare statement
            }

            let count: Int = try database.query("SELECT count(*) FROM cars")

            // Then
            XCTAssertEqual(count, 0, "count should be zero")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    // MARK: - Attach Database Tests

    func testThatDatabaseCanAttachAndDetachDatabase() {
        let personDBPath = NSFileManager.documentsDirectory.stringByAppendingString("/attach_detach_db_tests.db")
        defer { NSFileManager.removeItemAtPath(personDBPath) }

        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try database.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
            try database.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

            var connection2: Database? = try Database(databaseType: .OnDisk(personDBPath))
            try connection2?.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT)")
            try connection2?.prepare("INSERT INTO person VALUES(?, ?)").bind(1, "Sterling Archer").run()

            connection2 = nil

            // When
            try database.attachDatabase(.OnDisk(personDBPath), withName: "personDB")
            try database.prepare("INSERT INTO person VALUES(?, ?)").bind(2, "Lana Kane").run()
            let rows = try database.prepare("SELECT * FROM person").map { $0.values }

            try database.detachDatabase("personDB")

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

    func testThatDatabaseCanTraceStatementExecution() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            var statements: [String] = []

            // When
            database.trace { SQL in
                statements.append(SQL)
            }

            try database.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
            try database.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
            try database.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()

            try database.prepare("SELECT * FROM agents").forEach { _ in /** No-op */ }

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
