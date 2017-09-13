//
//  SQLiteErrorTests.swift
//
//  Copyright (c) 2015-present Nike, Inc. (https://www.nike.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import SQift
import SQLite3
import XCTest

class SQLiteErrorTestCase: BaseTestCase {
    func testThatInitializingConnectionWithInvalidFilePathThrowsError() {
        do {
            // Given, When
            let _ = try Connection(storageLocation: .onDisk("/path/does/not/exist"))
            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatExecutingInvalidSQLThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.execute("CREATE TABE testing(id)")

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatPreparingStatementWithInvalidSQLThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            let _ = try connection.prepare("INSERT IN table")

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithIncorrectNumberOfParametersThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(?, ?, ?)")
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485)

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithParameterOfIncorrectTypeThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(?, ?, ?, ?, ?)")
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485, 10_000, nil)
            try insert.run()

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CONSTRAINT)
            XCTAssertEqual(error.message, "NOT NULL constraint failed: agents.job_title")
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithUnmatchedParameterNameThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(:n, :d, :m, :s, :j)")
            try insert.bind([":n": "NAME", ":d": "DATE", ":m": 1, ":s": 2, ":f": 5])

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_MISUSE)
            XCTAssertEqual(error.message, "Bind could not find index for key: \':f\'")
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatBindingStatementWithParameterNameOfIncorrectTypeThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title) VALUES(:n, :d, :m, :s, :j)")
            try insert.bind([":n": "NAME", ":d": "DATE", ":m": 1, ":s": 2, ":j": nil])
            try insert.run()

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CONSTRAINT)
            XCTAssertEqual(error.message, "NOT NULL constraint failed: agents.job_title")
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatRunningTransactionWithInvalidSQLThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.transaction {
                try connection.execute("CREATE TABE testing(id)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatRunningSavepointWithInvalidSQLThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.savepoint(named: "save it good") {
                try connection.execute("CREATE TABE testing(id)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatAttachingDatabaseWithInvalidFilePathThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.attachDatabase(from: StorageLocation.onDisk("/path/does/not/exist"), withName: "not_gonna_work")
            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDetachingDatabaseThatIsNotAttachedThrowsError() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            try connection.detachDatabase(named: "not_attached")
            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }
}
