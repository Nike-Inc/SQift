//
//  ConnectionPool.swift
//  SQift
//
//  Created by Christian Noon on 11/15/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `ConnectionPool` class allows multiple read-only connections to access a database simultaneously in a
/// thread-safe manner. Internally, the pool manages two different sets of connections, ones that are available
/// and ones that are currently busy executing SQL logic. The pool will reuse available connections when they
/// are available, and initializes new connections when all available connections are busy until the max
/// connection count is reached.
///
/// If the max connection count is reached, the pool will start to append additional SQL closures to the already
/// busy connections. This could result in blocking behavior. SQLite does not have a limit on the maximumn number
/// of open connections to a single database. With that said, the default limit of 64 is set to a reasonable value
/// that most likely will never be exceeded.
///
/// The thread-safety is guaranteed by the connection pool by always executing the SQL closure inside a
/// connection queue. This ensures all SQL closures executed on the connection are done so in a serial fashion, thus
/// guaranteeing the thread-safety of each connection.
public class ConnectionPool {

    // MARK: - Public - Properties

    /// The maximum number of connections the pool can create.
    public let maxConnectionCount: Int

    // MARK: - Internal - Properties

    var availableConnections: Set<DatabaseQueue>
    var busyConnections: Set<DatabaseQueue>

    var busyConnectionClosureCounts: [DatabaseQueue: Int]

    var currentConnectionCount: Int { return availableConnections.count + busyConnections.count }
    var openConnectionIsAvailable: Bool { return availableConnections.count > 0 }
    var connectionLimitHasBeenReached: Bool { return currentConnectionCount == maxConnectionCount }

    let databaseType: Database.DatabaseType
    let flags: Int32

    // MARK: - Private - Properties

    private let queue: dispatch_queue_t

    // MARK: - Initialization

    /**
        Initializes the `ConnectionPool` instance with the specified database type and maximum connection count.

        - parameter databaseType:       The database type to initialize.
        - parameter maxConnectionCount: The maximum number of connections the pool can create.

        - throws: An `Error` if SQLite fails to initialize the default connection.

        - returns: The new `ConnectionPool` instance.
    */
    public init(databaseType: Database.DatabaseType, maxConnectionCount: Int = 64) throws {
        self.databaseType = databaseType
        self.flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_SHAREDCACHE
        self.queue = dispatch_queue_create("com.nike.sqift.connection-pool-\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)
        self.maxConnectionCount = max(maxConnectionCount, 1)

        self.availableConnections = []
        self.busyConnections = []
        self.busyConnectionClosureCounts = [:]

        let connection = try DatabaseQueue(database: Database(databaseType: databaseType, flags: flags))
        availableConnections.insert(connection)
    }

    // MARK: - Execution

    /**
        Executes the specified closure on the first available connection inside a connection queue.

        - parameter closure: The closure to execute.

        - throws: An `Error` if SQLite encounters an error executing the closure.
    */
    public func execute(closure: Database throws -> Void) throws {
        var connection: DatabaseQueue!

        dispatch_sync(queue) { connection = self.dequeueConnectionForUse() }
        try connection.execute { database in try closure(database) }
        dispatch_sync(queue) { self.enqueueConnectionForReuse(connection) }
    }

    // MARK: - Internal - Pool Dequeue and Enqueue

    func dequeueConnectionForUse() -> DatabaseQueue {
        let connection: DatabaseQueue

        if openConnectionIsAvailable {
            connection = availableConnections.removeFirst()
        } else if !connectionLimitHasBeenReached {
            connection = try! DatabaseQueue(database: Database(databaseType: databaseType, flags: flags))
        } else {
            connection = busyConnectionWithLowestClosureCount()!
        }

        busyConnections.insert(connection)

        if busyConnectionClosureCounts[connection] == nil {
            busyConnectionClosureCounts[connection] = 1
        } else {
            busyConnectionClosureCounts[connection] = busyConnectionClosureCounts[connection]! + 1
        }

        return connection
    }

    func enqueueConnectionForReuse(connection: DatabaseQueue) {
        let closureCount = busyConnectionClosureCounts[connection] ?? 1

        guard closureCount == 1 else {
            busyConnectionClosureCounts[connection] = closureCount - 1
            return
        }

        busyConnectionClosureCounts.removeValueForKey(connection)

        busyConnections.remove(connection)
        availableConnections.insert(connection)
    }

    func busyConnectionWithLowestClosureCount() -> DatabaseQueue? {
        var lowestConnection: DatabaseQueue?
        var lowestCount = Int.max

        for (databaseQueue, count) in busyConnectionClosureCounts {
            if lowestConnection == nil || count < lowestCount {
                lowestConnection = databaseQueue
                lowestCount = count
            }
        }

        return lowestConnection
    }
}
