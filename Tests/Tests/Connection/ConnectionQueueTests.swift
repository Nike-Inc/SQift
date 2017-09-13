//
//  ConnectionQueueTests.swift
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

class ConnectionQueueTestCase: BaseTestCase {
    func testThatConnectionQueueCanExecuteStatements() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64?

            // When, Then
            try queue.execute { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueThrowsErrorWhenExecutingStatement() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            // When
            try queue.execute { connection in
                try connection.execute("CREATE TBL agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR, "error code should be equal to `SQLITE_ERROR`")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInTransaction() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64?

            // When, Then
            try queue.executeInTransaction { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueThrowsErrorWhenExecutingTransaction() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            // When
            try queue.executeInTransaction { connection in
                try connection.execute("CREATE TBL agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR, "error code should be equal to `SQLITE_ERROR`")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInSavepoint() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64?

            // When, Then
            try queue.executeInSavepoint(named: "savepoint name with spaces") { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueThrowsErrorWhenExecutingSavepoint() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            // When
            try queue.executeInSavepoint(named: "create_table") { connection in
                try connection.execute("CREATE TBL agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR, "error code should be equal to `SQLITE_ERROR`")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
