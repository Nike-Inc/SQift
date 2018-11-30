//
//  BusyTests.swift
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

    func testThatConnectionCanSetTimeoutBusyHandler() throws {
        // Given
        try TestTables.insertDummyAgents(count: 1_000, connection: connection)

        let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

        let readExpectation = self.expectation(description: "agents should be retrieved from database")
        let checkpointExpectation = self.expectation(description: "checkpoint operation should succeed")

        var agents: [Agent]?
        var checkpointError: Error?

        // When

        // CN (8/21/17) - I can't find a way around this issue. It seems that iOS 10 and 11 might have a
        // simulator bug or potentially a bug in SQLite where the timeout is actually in nanoseconds instead
        // of milliseconds. By bumping the value up, the tests do pass. Because of this, I'd strongly advocate
        // that people only ever use custom busy handlers that track their own timing rather than using the
        // timeout busy handler. Again, this may only be an issue in the unit tests and the simulator.
        //
        // I also tested using `PRAGMA busy_timeout = 2000` and the same behavior is observed. I can't find
        // any information about this online which is odd, but we should really avoid using this in production.
        let timeout: TimeInterval = 20_000.0

        try connection.busyHandler(.timeout(timeout)) // throws SQLITE_BUSY error if this is disabled

        DispatchQueue.utility.async {
            do {
                agents = try readConnection.query("SELECT * FROM agents")
                readExpectation.fulfill()
            } catch {
                // No-op
            }
        }

        DispatchQueue.utility.asyncAfter(seconds: 0.01) {
            do {
                _ = try self.connection.checkpoint(mode: .truncate)
                checkpointExpectation.fulfill()
            } catch {
                checkpointError = error
                checkpointExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(agents?.count, 1_002)
        XCTAssertNil(checkpointError)
    }

    func testThatConnectionCanSetCustomBusyHandler() throws {
        // Given
        try TestTables.insertDummyAgents(count: 10_000, connection: connection)

        let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

        let expectation = self.expectation(description: "agents should be retrieved from database")
        var agents: [Agent]?
        var checkpointError: Error?

        let _busyInvocationLock = NSLock()
        var _busyInvocationCount: Int32 = 0

        var busyInvocationCount: Int32 {
            get {
                _busyInvocationLock.lock() ; defer { _busyInvocationLock.unlock() }
                return _busyInvocationCount
            }
            set {
                _busyInvocationLock.lock() ; defer { _busyInvocationLock.unlock() }
                _busyInvocationCount = newValue
            }
        }

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

        DispatchQueue.utility.asyncAfter(seconds: 0.01) {
            do {
                _ = try self.connection.checkpoint(mode: .truncate)
            } catch {
                checkpointError = error
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(agents?.count, 10_002)
        XCTAssertNil(checkpointError)
        XCTAssertGreaterThan(busyInvocationCount, 0)
    }

    func testThatConnectionCanSetDefaultBehaviorBusyHandler() throws {
        // Disable test on CI since timing is too unpredictable
        guard !ProcessInfo.isRunningOnCI else { return }

        // Given
        try TestTables.insertDummyAgents(count: 10_000, connection: connection)

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

        DispatchQueue.utility.asyncAfter(seconds: 0.01) {
            do {
                _ = try self.connection.checkpoint(mode: .truncate)
            } catch {
                checkpointError = error
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(agents?.count, 10_002)
        XCTAssertNotNil(checkpointError)

        if let error = checkpointError as? SQLiteError {
            XCTAssertEqual(error.code, SQLITE_BUSY)
            XCTAssertEqual(error.message, "database is locked")
        }
    }
}
