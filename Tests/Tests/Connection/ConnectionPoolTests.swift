//
//  ConnectionPoolTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
@testable import SQift
import SQLite3
import XCTest

class ConnectionPoolTestCase: BaseTestCase {

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        // Initialize read / write database before opening connection pool. Otherwise connection pool will fail
        // to initialize because it only opens readonly connections.
        do {
            let _ = try Connection(storageLocation: storageLocation)
        } catch {
            // No-op
        }
    }

    // MARK: - Tests

    func testThatDequeuingConnectionFailsWithInvalidOnDiskPath() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: .onDisk("/path/does/not/exist"))

            // When
            let _ = try pool.dequeueConnectionForUse()

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDequeueingConnectionCreatesNewConnection() throws {
        // Given
        let pool = ConnectionPool(storageLocation: storageLocation)
        pool.availableConnections.removeAll()

        // When
        let connection = try pool.dequeueConnectionForUse()

        // Then
        XCTAssertFalse(pool.availableConnections.contains(connection))
        XCTAssertTrue(pool.busyConnections.contains(connection))
    }

    func testThatDequeueingConnectionCreatesNewConnectionAndExecutesPreparationClosure() throws {
        // Given
        let pool = ConnectionPool(
            storageLocation: storageLocation,
            connectionPreparation: { connection in
                try connection.execute("PRAGMA synchronous = 1")
            }
        )

        pool.availableConnections.removeAll()

        var synchronous: Int?

        // When
        let connection = try pool.dequeueConnectionForUse()

        try pool.execute { connection in
            synchronous = try connection.query("PRAGMA synchronous")
        }

        // Then
        XCTAssertFalse(pool.availableConnections.contains(connection))
        XCTAssertTrue(pool.busyConnections.contains(connection))
        XCTAssertEqual(synchronous, 1)
    }

    func testThatEnqueueConnectionRemovesBusyConnectionAndInsertsAvailableConnection() throws {
        // Given
        let pool = ConnectionPool(storageLocation: storageLocation)
        let connection = try pool.dequeueConnectionForUse()

        let beforeEnqueueAvailableConnections = pool.availableConnections
        let beforeEnqueueBusyConnections = pool.busyConnections

        // When
        pool.enqueueConnectionForReuse(connection)

        // Then
        XCTAssertFalse(beforeEnqueueAvailableConnections.contains(connection))
        XCTAssertTrue(beforeEnqueueBusyConnections.contains(connection))

        XCTAssertTrue(pool.availableConnections.contains(connection))
        XCTAssertFalse(pool.busyConnections.contains(connection))
    }

    func testThatConnectionPoolCanExecuteReadOnlyClosure() throws {
        // Given
        let pool = ConnectionPool(storageLocation: storageLocation)

        var count: Int?

        // When
        try pool.execute { connection in
            count = try connection.query("SELECT count(*) FROM sqlite_master where type = 'table'")
        }

        // Then
        XCTAssertEqual(count, 0)
    }

    func testThatConnectionPoolFailsToExecuteWriteClosure() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: storageLocation)

            // When
            try pool.execute { connection in
                try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as SQLiteError {
            // Then
            XCTAssertEqual(error.code, SQLITE_READONLY)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatConnectionPoolCanExecuteMultipleClosuresInParallel() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try TestTables.createAndPopulateAgentsTable(using: connection)
        let pool = ConnectionPool(storageLocation: storageLocation)

        let range = 0..<128
        let expectations: [XCTestExpectation] = range.map { expectation(description: "read: \($0)") }
        var counts: [Int] = []

        let queue = DispatchQueue(label: "test_serial_queue")
        let utilityQueue = DispatchQueue.global(qos: .utility)

        // When
        range.forEach { index in
            utilityQueue.async {
                do {
                    try pool.execute { connection in
                        guard let count: Int = try connection.query("SELECT count(*) FROM agents") else { return }
                        queue.sync { counts.append(count) }
                    }
                } catch {
                    // No-op
                }

                expectations[index].fulfill()
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)

        // Then
        XCTAssertEqual(counts.count, range.count)

        for count in counts {
            XCTAssertEqual(count, 2)
        }
    }

    func testThatConnectionPoolDrainDelayWorksAsExpected() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try TestTables.createAndPopulateAgentsTable(using: connection)
        let pool = ConnectionPool(storageLocation: storageLocation, availableConnectionDrainDelay: 0.1)

        let range = 0..<10
        let expectations: [XCTestExpectation] = range.map { expectation(description: "read: \($0)") }
        var counts: [Int] = []

        let queue = DispatchQueue(label: "test_serial_queue")
        let utilityQueue = DispatchQueue.global(qos: .utility)

        // When
        range.forEach { index in
            utilityQueue.async {
                do {
                    try pool.execute { connection in
                        guard let count: Int = try connection.query("SELECT count(*) FROM agents") else { return }
                        queue.sync { counts.append(count) }
                    }
                } catch {
                    // No-op
                }

                expectations[index].fulfill()
            }
        }

        let drainExpectation = expectation(description: "drain timer should drain available connections")
        DispatchQueue.main.asyncAfter(seconds: 0.2) { drainExpectation.fulfill() }

        waitForExpectations(timeout: 10.0, handler: nil)

        // Then
        XCTAssertEqual(pool.availableConnections.count, 1, "available connections count should be back down to 1")
        XCTAssertEqual(counts.count, range.count, "counts array should have equal number of items as range")

        for (index, count) in counts.enumerated() {
            XCTAssertEqual(count, 2, "count should be equal to 2 at index: \(index)")
        }
    }
}
