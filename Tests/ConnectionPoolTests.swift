//
//  ConnectionPoolTests.swift
//  SQift
//
//  Created by Christian Noon on 11/15/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
@testable import SQift
import XCTest

class ConnectionPoolTestCase: XCTestCase {
    private let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/connection_pool_tests.db")
        return .onDisk(path)
    }()

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

    override func tearDown() {
        super.tearDown()
        FileManager.removeItem(atPath: storageLocation.path)
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
            XCTAssertEqual(error.code, SQLITE_CANTOPEN, "error code should be `SQLITE_CANTOPEN`")
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDequeueingConnectionCreatesNewConnection() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: storageLocation)
            pool.availableConnections.removeAll()

            // When
            let connection = try pool.dequeueConnectionForUse()

            // Then
            XCTAssertFalse(pool.availableConnections.contains(connection), "available connections should not contain connection")
            XCTAssertTrue(pool.busyConnections.contains(connection), "busy connections should contain connection")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDequeueingConnectionCreatesNewConnectionAndExecutesPreparationClosure() {
        do {
            // Given
            let pool = ConnectionPool(
                storageLocation: storageLocation,
                connectionPreparation: { connection in
                    try connection.execute("PRAGMA synchronous = 1")
                }
            )

            pool.availableConnections.removeAll()

            var synchronous = 0

            // When
            let connection = try pool.dequeueConnectionForUse()

            try pool.execute { connection in
                synchronous = try connection.query("PRAGMA synchronous")
            }

            // Then
            XCTAssertFalse(pool.availableConnections.contains(connection), "available connections should not contain connection")
            XCTAssertTrue(pool.busyConnections.contains(connection), "busy connections should contain connection")
            XCTAssertEqual(synchronous, 1, "synchronous should be 1")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatEnqueueConnectionRemovesBusyConnectionAndInsertsAvailableConnection() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: storageLocation)
            let connection = try pool.dequeueConnectionForUse()

            let beforeEnqueueAvailableConnections = pool.availableConnections
            let beforeEnqueueBusyConnections = pool.busyConnections

            // When
            pool.enqueueConnectionForReuse(connection)

            // Then
            XCTAssertFalse(beforeEnqueueAvailableConnections.contains(connection), "available connections should not contain connection before enqueue")
            XCTAssertTrue(beforeEnqueueBusyConnections.contains(connection), "busy connections should contain connection before enqueue")

            XCTAssertTrue(pool.availableConnections.contains(connection), "available connections should contain connection after enqueue")
            XCTAssertFalse(pool.busyConnections.contains(connection), "busy connections should not contain connection after enqueue")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionPoolCanExecuteReadOnlyClosure() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: storageLocation)

            var count = -1

            // When
            try pool.execute { connection in
                count = try connection.query("SELECT count(*) FROM sqlite_master where type = 'table'")
            }

            // Then
            XCTAssertEqual(count, 0, "count should be equal to 0")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
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
            XCTAssertEqual(error.code, SQLITE_READONLY, "error code should equal SQLITE_READONLY")
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatConnectionPoolCanExecuteMultipleClosuresInParallel() {
        do {
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
                            let count: Int = try connection.query("SELECT count(*) FROM agents")
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
            XCTAssertEqual(counts.count, range.count, "counts array should have equal number of items as range")

            for (index, count) in counts.enumerated() {
                XCTAssertEqual(count, 2, "count should be equal to 2 at index: \(index)")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionPoolDrainDelayWorksAsExpected() {
        do {
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
                            let count: Int = try connection.query("SELECT count(*) FROM agents")
                            queue.sync { counts.append(count) }
                        }
                    } catch {
                        // No-op
                    }

                    expectations[index].fulfill()
                }
            }

            let drainExpectation = expectation(description: "drain timer should drain available connections")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                drainExpectation.fulfill()
            }

            waitForExpectations(timeout: 10.0, handler: nil)

            // Then
            XCTAssertEqual(pool.availableConnections.count, 1, "available connections count should be back down to 1")
            XCTAssertEqual(counts.count, range.count, "counts array should have equal number of items as range")

            for (index, count) in counts.enumerated() {
                XCTAssertEqual(count, 2, "count should be equal to 2 at index: \(index)")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
