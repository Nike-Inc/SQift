//
//  ConnectionQueueTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import SQLite3
import XCTest

class ConnectionQueueTestCase: BaseTestCase {
    func testThatConnectionQueueCanExecuteStatements() throws {
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
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInTransaction() throws {
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
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInSavepoint() throws {
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
            XCTAssertEqual(error.code, SQLITE_ERROR)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
