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
    let storageLocation: StorageLocation = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/connection_pool_tests.db")
        return .OnDisk(path)
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
        NSFileManager.removeItemAtPath(storageLocation.path)
    }

    // MARK: - Tests

    func testThatDequeuingConnectionFailsWithInvalidOnDiskPath() {
        do {
            // Given
            let pool = ConnectionPool(storageLocation: .OnDisk("/path/does/not/exist"))

            // When
            let _ = try pool.dequeueConnectionForUse()

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
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
                print("Is connection read-only? \(connection.readOnly)")
                try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)")
            }

            XCTFail("Execution should not reach this point")
        } catch let error as Error {
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
            try TestTables.createAndPopulateAgentsTable(connection)
            let pool = ConnectionPool(storageLocation: storageLocation)

            let range = 0..<128
            let expectations: [XCTestExpectation] = range.map { expectationWithDescription("read: \($0)") }
            var counts: [Int] = []

            let queue = dispatch_queue_create("test_serial_queue", DISPATCH_QUEUE_SERIAL)

            // When
            range.forEach { index in
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                    do {
                        try pool.execute { connection in
                            let count: Int = try connection.query("SELECT count(*) FROM agents")
                            dispatch_sync(queue) { counts.append(count) }
                        }
                    } catch {
                        // No-op
                    }

                    expectations[index].fulfill()
                }
            }

            waitForExpectationsWithTimeout(10.0, handler: nil)

            // Then
            XCTAssertEqual(counts.count, range.count, "counts array should have equal number of items as range")

            for (index, count) in counts.enumerate() {
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
            try TestTables.createAndPopulateAgentsTable(connection)
            let pool = ConnectionPool(storageLocation: storageLocation, availableConnectionDrainDelay: 0.1)

            let range = 0..<10
            let expectations: [XCTestExpectation] = range.map { expectationWithDescription("read: \($0)") }
            var counts: [Int] = []

            let queue = dispatch_queue_create("test_serial_queue", DISPATCH_QUEUE_SERIAL)

            // When
            range.forEach { index in
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                    do {
                        try pool.execute { connection in
                            let count: Int = try connection.query("SELECT count(*) FROM agents")
                            dispatch_sync(queue) { counts.append(count) }
                        }
                    } catch {
                        // No-op
                    }

                    expectations[index].fulfill()
                }
            }

            let drainExpectation = expectationWithDescription("drain timer should drain available connections")

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Float(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                drainExpectation.fulfill()
            }

            waitForExpectationsWithTimeout(10.0, handler: nil)

            // Then
            XCTAssertEqual(pool.availableConnections.count, 1, "available connections count should be back down to 1")
            XCTAssertEqual(counts.count, range.count, "counts array should have equal number of items as range")

            for (index, count) in counts.enumerate() {
                XCTAssertEqual(count, 2, "count should be equal to 2 at index: \(index)")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
