//
//  ErrorTests.swift
//  SQift
//
//  Created by Christian Noon on 11/12/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class ErrorTestCase: XCTestCase {
    let databaseType: Database.DatabaseType = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/error_tests.db")
        return .OnDisk(path)
    }()

    func testThatInitializingDatabaseWithInvalidFilePathThrowsError() {
        do {
            // Given, When
            let _ = try Database(databaseType: .OnDisk("/path/does/not/exist"))
            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatExecutingInvalidSQLThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.execute("CREATE TABE testing(id)")

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatPreparingStatementWithInvalidSQLThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            let _ = try database.prepare("INSERT IN table")

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithIncorrectNumberOfParametersThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)

            // When
            let insert = try database.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(?, ?, ?)")
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485)

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithParameterOfIncorrectTypeThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)

            // When
            let insert = try database.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(?, ?, ?, ?, ?)")
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485, 10_000, "job_title_value")

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithUnmatchedParameterNameThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)

            // When
            let insert = try database.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(:n, :d, :m, :s, :j)")
            try insert.bind([":n": "NAME", ":d": "DATE", ":m": 1, ":s": 2, ":f": 5])

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithParameterNameOfIncorrectTypeThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)

            // When
            let insert = try database.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(:n, :d, :m, :s, :j)")
            try insert.bind([":n": "NAME", ":d": "DATE", ":m": 1, ":s": 2, ":j": 6])

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatRunningTransactionWithInvalidSQLThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.transaction {
                try database.execute("CREATE TABE testing(id)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatRunningSavepointWithInvalidSQLThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.savepoint("save it good") {
                try database.execute("CREATE TABE testing(id)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatAttachingDatabaseWithInvalidFilePathThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.attachDatabase(.OnDisk("/path/does/not/exist"), withName: "not_gonna_work")
            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDetachingDatabaseThatIsNotAttachedThrowsError() {
        do {
            // Given
            let database = try Database(databaseType: databaseType)

            // When
            try database.detachDatabase("not_attached")
            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }
}
