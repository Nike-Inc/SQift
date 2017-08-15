//
//  BusyTests.swift
//  SQift
//
//  Created by Christian Noon on 8/14/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class BusyTestCase: BaseConnectionTestCase {

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

    func testThatConnectionCanSetTimeoutBusyHandler() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

            let expectation = self.expectation(description: "agents should be retrieved from database")
            var agents: [Agent]?
            var checkpointError: Error?

            // When
            try connection.busyHandler(.timeout(2.0)) // throws SQLITE_BUSY error if this is disabled

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
            XCTAssertNil(checkpointError)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanSetCustomBusyHandler() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

            let expectation = self.expectation(description: "agents should be retrieved from database")
            var agents: [Agent]?
            var busyInvocationCount: Int32 = 0
            var checkpointError: Error?

            // When
            try connection.busyHandler(
                .custom { attempts in
                    busyInvocationCount = attempts + 1
                    return true
                }
            )

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
            XCTAssertNil(checkpointError)
            XCTAssertGreaterThan(busyInvocationCount, 0)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanSetDefaultBehaviorBusyHandler() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

            let expectation = self.expectation(description: "agents should be retrieved from database")
            var agents: [Agent]?
            var checkpointError: Error?

            // When
            try connection.busyHandler(.defaultBehavior)

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
