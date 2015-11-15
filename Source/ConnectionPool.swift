//
//  ConnectionPool.swift
//  SQift
//
//  Created by Christian Noon on 11/15/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public class ConnectionPool {

    // MARK: - Public - Properties

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

    public init(databaseType: Database.DatabaseType, maxConnectionCount: Int = 16) throws {
        self.databaseType = databaseType
        self.flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_SHAREDCACHE
        self.queue = dispatch_queue_create("com.nike.fetch.database-pool-\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)
        self.maxConnectionCount = max(maxConnectionCount, 1)

        self.availableConnections = []
        self.busyConnections = []
        self.busyConnectionClosureCounts = [:]

        let connection = try DatabaseQueue(database: Database(databaseType: databaseType, flags: flags))
        availableConnections.insert(connection)
    }

    // MARK: - Execution

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
