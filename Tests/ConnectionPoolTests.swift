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
    let databaseType: Database.DatabaseType = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/connection_pool_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        // Initialize read / write database before opening connection pool. Otherwise connection pool will fail
        // to initialize because it only opens readonly connections.
        do {
            let _ = try Database(databaseType: databaseType)
        } catch {
            // No-op
        }
    }

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(databaseType.path)
    }

    // MARK: - Tests

    func testThatConnectionPoolInitializationSucceeds() {
        do {
            // Given, When, Then
            let _ = try ConnectionPool(databaseType: databaseType)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionPoolInitializationFailsWithInvalidOnDiskPath() {
        do {
            // Given, When
            let _ = try ConnectionPool(databaseType: .OnDisk("/path/does/not/exist"))
            XCTFail("Execution should not reach this point")
        } catch let error as Error {
            // Then
            XCTAssertEqual(error.code, SQLITE_CANTOPEN)
        } catch {
            XCTFail("Failed with an unknown error type: \(error)")
        }
    }

    func testThatDequeueingConnectionReturnsAvailableConnection() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType)

            let beforeDequeueAvailableConnections = pool.availableConnections
            let beforeDequeueBusyConnections = pool.busyConnections
            let beforeBusyCount = pool.busyConnectionClosureCounts.count

            // When
            let connection = pool.dequeueConnectionForUse()

            // Then
            XCTAssertTrue(beforeDequeueAvailableConnections.contains(connection), "before dequeue, available connections should contain connection")
            XCTAssertFalse(beforeDequeueBusyConnections.contains(connection), "before dequeue, busy connections should not contain connection")

            XCTAssertFalse(pool.availableConnections.contains(connection), "after dequeue, available connections should not contain connection")
            XCTAssertTrue(pool.busyConnections.contains(connection), "after dequeue, busy connections should contain connection")

            XCTAssertEqual(beforeBusyCount, 0, "before busy count should be 0 since no connections should have been busy")
            XCTAssertEqual(pool.busyConnectionClosureCounts[connection], 1, "closure count for connection should be 1 after dequeue")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDequeueingConnectionCreatesNewConnection() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType)
            pool.availableConnections.removeAll()
            let beforeBusyCount = pool.busyConnectionClosureCounts.count

            // When
            let connection = pool.dequeueConnectionForUse()

            // Then
            XCTAssertFalse(pool.availableConnections.contains(connection), "available connections should not contain connection")
            XCTAssertTrue(pool.busyConnections.contains(connection), "busy connections should contain connection")

            XCTAssertEqual(beforeBusyCount, 0, "before busy count should be 0 since no connections should have been busy")
            XCTAssertEqual(pool.busyConnectionClosureCounts[connection], 1, "closure count for connection should be 1 after dequeue")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDequeueingConnectionReusesBusyConnectionIfNecessary() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 1)

            // When
            let connection1 = pool.dequeueConnectionForUse()
            let connection2 = pool.dequeueConnectionForUse()

            // Then
            XCTAssertEqual(connection1, connection2, "connection 1 should equal connection 2")
            XCTAssertFalse(pool.availableConnections.contains(connection2), "available connections should not contain connection 2")
            XCTAssertTrue(pool.busyConnections.contains(connection2), "busy connections should contain connection 2")

            XCTAssertEqual(pool.busyConnectionClosureCounts[connection2], 2, "closure count for connection 2 should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatEnqueueConnectionRemovesBusyConnectionAndInsertsAvailableConnection() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType)
            let connection = pool.dequeueConnectionForUse()

            let beforeClosureCount = pool.busyConnectionClosureCounts[connection]
            let beforeEnqueueAvailableConnections = pool.availableConnections
            let beforeEnqueueBusyConnections = pool.busyConnections

            // When
            pool.enqueueConnectionForReuse(connection)

            // Then
            XCTAssertEqual(beforeClosureCount, 1, "before closure count should be 1")
            XCTAssertFalse(beforeEnqueueAvailableConnections.contains(connection), "available connections should not contain connection before enqueue")
            XCTAssertTrue(beforeEnqueueBusyConnections.contains(connection), "busy connections should contain connection before enqueue")

            XCTAssertNil(pool.busyConnectionClosureCounts[connection], "busy connection closure count should be nil after enqueue")
            XCTAssertTrue(pool.availableConnections.contains(connection), "available connections should contain connection after enqueue")
            XCTAssertFalse(pool.busyConnections.contains(connection), "busy connections should not contain connection after enqueue")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatEnqueueConnectionDecrementsBusyConnectionWhenClosureCountIsLargerThanOne() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 1)
            pool.dequeueConnectionForUse()
            let connection = pool.dequeueConnectionForUse()

            let beforeClosureCount = pool.busyConnectionClosureCounts[connection]
            let beforeEnqueueAvailableConnections = pool.availableConnections
            let beforeEnqueueBusyConnections = pool.busyConnections

            // When
            pool.enqueueConnectionForReuse(connection)

            // Then
            XCTAssertEqual(beforeClosureCount, 2, "before closure count should be 2")
            XCTAssertFalse(beforeEnqueueAvailableConnections.contains(connection), "available connections should not contain connection before enqueue")
            XCTAssertTrue(beforeEnqueueBusyConnections.contains(connection), "busy connections should contain connection before enqueue")

            XCTAssertEqual(pool.busyConnectionClosureCounts[connection], 1, "closure count should be 1")
            XCTAssertFalse(pool.availableConnections.contains(connection), "available connections should not contain connection after enqueue")
            XCTAssertTrue(pool.busyConnections.contains(connection), "busy connections should contain connection after enqueue")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatBusyConnectionWithLowestClosureCountWorksUnderNormalConditions() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 8)

            pool.availableConnections.insert(
                try DatabaseQueue(database: Database(databaseType: pool.databaseType, flags: pool.flags))
            )

            pool.availableConnections.insert(
                try DatabaseQueue(database: Database(databaseType: pool.databaseType, flags: pool.flags))
            )

            let connection1 = pool.dequeueConnectionForUse()
            let connection2 = pool.dequeueConnectionForUse()
            let connection3 = pool.dequeueConnectionForUse()

            pool.busyConnectionClosureCounts[connection1] = 4
            pool.busyConnectionClosureCounts[connection2] = 3
            pool.busyConnectionClosureCounts[connection3] = 2

            // When
            let lowestConnection = pool.busyConnectionWithLowestClosureCount()

            // Then
            XCTAssertNotEqual(connection1, connection2, "connection 1 and 2 should not be equal")
            XCTAssertNotEqual(connection2, connection3, "connection 2 and 3 should not be equal")
            XCTAssertNotEqual(connection1, connection3, "connection 1 and 3 should not be equal")

            XCTAssertEqual(lowestConnection, connection3, "lowest connection should equal connection 3")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatBusyConnectionWithLowestClosureCountReturnsNilWhenThereAreNoBusyConnections() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 1)

            // When
            let lowestConnection = pool.busyConnectionWithLowestClosureCount()

            // Then
            XCTAssertNil(lowestConnection, "lowest connection should be nil when busy connections is empty")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionPoolCanExecuteReadOnlyClosure() {
        do {
            // Given
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 1)

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
            let pool = try ConnectionPool(databaseType: databaseType, maxConnectionCount: 1)

            // When
            try pool.execute { connection in
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
            let database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)
            let pool = try ConnectionPool(databaseType: databaseType)

            let range = 0..<pool.maxConnectionCount
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
}
