//
//  CheckpointTests.swift
//  SQift
//
//  Created by Christian Noon on 8/13/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class CheckpointTestCase: BaseConnectionTestCase {

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        do {
            try connection.execute("PRAGMA journal_mode = WAL")
        } catch {
            // No-op
        }
    }

    // MARK: - Tests

    func testThatConnectionCanCheckpointDatabaseUsingPassiveCheckpointMode() {
        do {
            // Given
            try connection.transaction {
                let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
                let statement = try connection.prepare(sql)

                for index in 1...1_000 {
                    try statement.bind("name", "date", index, 2.01, "job".data(using: .utf8), nil).run()
                }
            }

            // When
            let result = try connection.checkpoint(mode: .passive)

            // Then
            XCTAssertEqual(result.logFrames, 11)
            XCTAssertEqual(result.checkpointedFrames, 11)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingFullCheckpointMode() {
        do {
            // Given
            try connection.transaction {
                let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
                let statement = try connection.prepare(sql)

                for index in 1...1_000 {
                    try statement.bind("name", "date", index, 2.01, "job".data(using: .utf8), nil).run()
                }
            }

            // When
            let result = try connection.checkpoint(mode: .full)

            // Then
            XCTAssertEqual(result.logFrames, 11)
            XCTAssertEqual(result.checkpointedFrames, 11)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingRestartCheckpointMode() {
        do {
            // Given
            try connection.transaction {
                let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
                let statement = try connection.prepare(sql)

                for index in 1...1_000 {
                    try statement.bind("name", "date", index, 2.01, "job".data(using: .utf8), nil).run()
                }
            }

            // When
            let result = try connection.checkpoint(mode: .restart)

            // Then
            XCTAssertEqual(result.logFrames, 11)
            XCTAssertEqual(result.checkpointedFrames, 11)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingTruncateCheckpointMode() {
        do {
            // Given
            try connection.transaction {
                let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
                let statement = try connection.prepare(sql)

                for index in 1...1_000 {
                    try statement.bind("name", "date", index, 2.01, "job".data(using: .utf8), nil).run()
                }
            }

            // When
            let result = try connection.checkpoint(mode: .truncate)

            // Then
            XCTAssertEqual(result.logFrames, 0) // CN (8/14/17) - DB is being truncated but results are always 0?
            XCTAssertEqual(result.checkpointedFrames, 0)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionThrowsBusyErrorWhenCheckpointingBusyDatabase() {
        do {
            // Given
            let dateString = bindingDateFormatter.string(from: Date())

            try connection.transaction {
                let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
                let statement = try connection.prepare(sql)

                for index in 1...1_000 {
                    try statement.bind("name", dateString, index, 2.01, "job".data(using: .utf8), nil).run()
                }
            }

            let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

            let expectation = self.expectation(description: "agents should be retrieved from database")
            var agents: [Agent]?
            var checkpointError: Error?

            // When
            DispatchQueue.utility.async {
                do {
                    agents = try readConnection.query("SELECT * FROM agents")
                    expectation.fulfill()
                } catch {
                    // No-op
                }
            }

            DispatchQueue.utility.asyncAfter(seconds: 0.001) {
                do {
                    _ = try self.connection.checkpoint(mode: .truncate)
                } catch {
                    checkpointError = error
                }
            }

            waitForExpectations(timeout: timeout, handler: nil)

            // Then
            XCTAssertEqual(agents?.count, 1_002)
            XCTAssertNotNil(checkpointError)

            if let error = checkpointError as? SQLiteError {
                XCTAssertEqual(error.code, SQLITE_BUSY)
                XCTAssertEqual(error.message, "database is locked")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
