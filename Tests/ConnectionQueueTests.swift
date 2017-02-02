//
//  ConnectionQueueTests.swift
//  SQift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class ConnectionQueueTestCase: XCTestCase {
    private let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/database_queue_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Tests

    func testThatConnectionQueueCanExecuteStatements() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64 = 0

            // When, Then
            try queue.execute { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2, "row count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
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
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInTransaction() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64 = 0

            // When, Then
            try queue.executeInTransaction { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2, "row count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
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
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionQueueCanExecuteStatementsInSavepoint() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            var rowCount: Int64 = 0

            // When, Then
            try queue.executeInSavepoint("savepoint name with spaces") { connection in
                try connection.execute("DROP TABLE IF EXISTS agents")
                try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Sterling Archer", "World's Greatest Secret Agent")
                try connection.run("INSERT INTO agents(name, job) VALUES(?, ?)", "Lana Kane", "Top Agent")

                rowCount = try connection.query("SELECT count(*) FROM agents")
            }

            // Then
            XCTAssertEqual(rowCount, 2, "row count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionQueueThrowsErrorWhenExecutingSavepoint() {
        do {
            // Given
            let queue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation))

            // When
            try queue.executeInSavepoint("create_table") { connection in
                try connection.execute("CREATE TBL agents(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, job TEXT)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_ERROR, "error code should be equal to `SQLITE_ERROR`")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
