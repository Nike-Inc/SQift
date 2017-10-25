//
//  ConnectionPool.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQLite3

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

    let storageLocation: StorageLocation
    let flags: Int32

    // MARK: - Private - Properties

    private let queue: DispatchQueue
    private let drainDelay: TimeInterval
    private var drainInProgress: Bool
    private let connectionPreparation: ((Connection) throws -> Void)?

    // MARK: - Initialization

    /// Creates a `ConnectionPool` instance with the storage location, drain delay and connection preparation.
    ///
    /// The connection preparation closure is always executed on any new connection, before the public `execute` method
    /// closure is run. This can be very useful for setting up PRAGMAs or custom collation closures on the connection
    /// before use.
    ///
    /// - Parameters:
    ///   - storageLocation:       The storage location path to use during initialization.
    ///   - drainDelay:            Total time to wait before draining the available connections. `1.0` by default.
    ///   - connectionPreparation: The closure executed when a new connection is created. `nil` by default.
    public init(
        storageLocation: StorageLocation,
        availableConnectionDrainDelay drainDelay: TimeInterval = 1.0,
        connectionPreparation: ((Connection) throws -> Void)? = nil)
    {
        self.storageLocation = storageLocation
        self.drainDelay = drainDelay
        self.drainInProgress = false
        self.connectionPreparation = connectionPreparation

        self.flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_SHAREDCACHE
        self.queue = DispatchQueue(label: "com.nike.sqift.connection-pool-\(UUID().uuidString)")

        self.availableConnections = []
        self.busyConnections = []
    }

    // MARK: - Execution

    /// Executes the specified closure on the first available connection inside a connection queue.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func execute(closure: (Connection) throws -> Void) throws {
        var connection: ConnectionQueue!
        var dequeueError: Error?

        queue.sync {
            do {
                connection = try self.dequeueConnectionForUse()
            } catch {
                dequeueError = error
            }
        }

        guard dequeueError == nil else { throw dequeueError! }

        try connection.execute { database in try closure(database) }

        queue.sync {
            self.enqueueConnectionForReuse(connection)
            self.startDrainDelayTimerIfNecessary()
        }
    }

    // MARK: - Internal - Pool Dequeue and Enqueue

    func dequeueConnectionForUse() throws -> ConnectionQueue {
        let connectionQueue: ConnectionQueue

        if !availableConnections.isEmpty {
            connectionQueue = availableConnections.removeFirst()
        } else {
            connectionQueue = try ConnectionQueue(connection: Connection(storageLocation: storageLocation, flags: flags))
            try connectionPreparation?(connectionQueue.connection)
        }

        busyConnections.insert(connectionQueue)

        return connectionQueue
    }

    func enqueueConnectionForReuse(_ connection: ConnectionQueue) {
        busyConnections.remove(connection)
        availableConnections.insert(connection)
    }

    // MARK: - Internal - Drain Delay Timer

    func startDrainDelayTimerIfNecessary() {
        guard !drainInProgress else { return }

        drainInProgress = true

        queue.asyncAfter(deadline: .now() + drainDelay) { [weak self] in
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
