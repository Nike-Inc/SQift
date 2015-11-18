//
//  Database.swift
//  SQift
//
//  Created by Christian Noon on 11/17/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `Database` class is a lightweight way to create a single writable connection queue and connection pool for
/// all read statements. The read and write APIs are designed to make it simple to execute SQL statements on the
/// appropriate type of `Connection` in a thread-safe manner.
public class Database {
    private var writerConnectionQueue: ConnectionQueue!
    private var readerConnectionPool: ConnectionPool!

    /**
        Initializes the `Database` with the specified storage location and initialization flags.

        - parameter storageLocation: The storage location path to use during initialization.
        - parameter readOnly:        Whether the database should be read-only.
        - parameter multiThreaded:   Whether the database should be multi-threaded.
        - parameter sharedCache:     Whether the database should use a shared cache.

        - throws: An `Error` if SQLite encounters an error opening the writable connection.

        - returns: The new `Database` instance.
    */
    public init(
        storageLocation: StorageLocation = .InMemory,
        readOnly: Bool = false,
        multiThreaded: Bool = true,
        sharedCache: Bool = true)
        throws
    {
        let writerConnection = try Connection(
            storageLocation: storageLocation,
            readOnly: readOnly,
            multiThreaded: multiThreaded,
            sharedCache: sharedCache
        )

        self.writerConnectionQueue = ConnectionQueue(connection: writerConnection)
        self.readerConnectionPool = ConnectionPool(storageLocation: storageLocation)
    }

    /**
        Initializes the `Database` with the specified storage location and initialization flags.

        - parameter storageLocation: The storage location path to use during initialization.
        - parameter flags:           The bitmask flags to use when initializing the database.

        - throws: An `Error` if SQLite encounters an error opening the writable connection.

        - returns: The new `Database` instance.
     */
    public init(storageLocation: StorageLocation, flags: Int32) throws {
        let writerConnection = try Connection(storageLocation: storageLocation, flags: flags)

        self.writerConnectionQueue = ConnectionQueue(connection: writerConnection)
        self.readerConnectionPool = ConnectionPool(storageLocation: storageLocation)
    }

    /**
        Executes the specified closure on the read-only connection pool.

        - parameter closure: The closure to execute.

        - throws: An `Error` if SQLite encounters an error executing the closure.
    */
    public func executeRead(closure: Connection throws -> Void) throws {
        try readerConnectionPool.execute { connection in
            try closure(connection)
        }
    }

    /**
        Executes the specified closure on the writer connection queue.

        - parameter closure: The closure to execute.

        - throws: An `Error` if SQLite encounters an error executing the closure.
    */
    public func executeWrite(closure: Connection throws -> Void) throws {
        try writerConnectionQueue.execute { connection in
            try closure(connection)
        }
    }
}
