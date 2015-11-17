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
/// are available, and initializes new connections when all available connections are busy.
///
/// Since SQLite has no limit on the maximum number of open connections to a single database, the `ConnectionPool`
/// will initialize as many connections as needed within a small amount of time. Each time a connection is executed,
/// the internal drain delay timer starts up. When the drain delay timer fires, it will drain the available connections
/// if there are no more busy connections. If there are still busy connections, the timer is restarted. This allows the
/// `ConnectionPool` to spin up as many connections as necessary for very small amounts of time.
///
/// The thread-safety is guaranteed by the connection pool by always executing the SQL closure inside a
/// connection queue. This ensures all SQL closures executed on the connection are done so in a serial fashion, thus
/// guaranteeing the thread-safety of each connection.
public class ConnectionPool {

    // MARK: - Internal - Properties

    var availableConnections: Set<ConnectionQueue>
    var busyConnections: Set<ConnectionQueue>   

    let connectionType: Connection.ConnectionType
    let flags: Int32

    // MARK: - Private - Properties

    private let queue: dispatch_queue_t
    private let drainDelay: NSTimeInterval
    private var drainInProgress: Bool

    // MARK: - Initialization

    /**
        Initializes the `ConnectionPool` instance with the specified connection type and drain delay.

        - parameter connectionType: The connection type to initialize.
        - parameter drainDelay:     Total time to wait before draining the available connections. Default is `1.0`.

        - throws: An `Error` if SQLite fails to initialize the default connection.

        - returns: The new `ConnectionPool` instance.
    */
    public init(
        connectionType: Connection.ConnectionType,
        availableConnectionDrainDelay drainDelay: NSTimeInterval = 1.0)
        throws
    {
        self.connectionType = connectionType
        self.drainDelay = drainDelay
        self.drainInProgress = false

        self.flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_SHAREDCACHE
        self.queue = dispatch_queue_create("com.nike.sqift.connection-pool-\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)

        self.availableConnections = []
        self.busyConnections = []

        let connection = try ConnectionQueue(connection: Connection(connectionType: connectionType, flags: flags))
        availableConnections.insert(connection)
    }

    // MARK: - Execution

    /**
        Executes the specified closure on the first available connection inside a connection queue.

        - parameter closure: The closure to execute.

        - throws: An `Error` if SQLite encounters an error executing the closure.
    */
    public func execute(closure: Connection throws -> Void) throws {
        var connection: ConnectionQueue!

        dispatch_sync(queue) { connection = self.dequeueConnectionForUse() }

        try connection.execute { database in try closure(database) }

        dispatch_sync(queue) {
            self.enqueueConnectionForReuse(connection)
            self.startDrainDelayTimerIfNecessary()
        }
    }

    // MARK: - Internal - Pool Dequeue and Enqueue

    func dequeueConnectionForUse() -> ConnectionQueue {
        let connection: ConnectionQueue

        if !availableConnections.isEmpty {
            connection = availableConnections.removeFirst()
        } else {
            connection = try! ConnectionQueue(connection: Connection(connectionType: connectionType, flags: flags))
        }

        busyConnections.insert(connection)

        return connection
    }

    func enqueueConnectionForReuse(connection: ConnectionQueue) {
        busyConnections.remove(connection)
        availableConnections.insert(connection)
    }

    // MARK: - Internal - Drain Delay Timer

    func startDrainDelayTimerIfNecessary() {
        guard !drainInProgress else { return }

        drainInProgress = true

        let dispatchDrainDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(drainDelay * Double(NSEC_PER_SEC)))

        dispatch_after(dispatchDrainDelay, queue) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.drainAllAvailableConnectionsExceptOne()
        }
    }

    func drainAllAvailableConnectionsExceptOne() {
        drainInProgress = false

        guard availableConnections.count > 1 else { return }

        guard busyConnections.isEmpty else {
            startDrainDelayTimerIfNecessary()
            return
        }

        availableConnections = [availableConnections.first!]
    }
}
