//
//  Database.swift
//  SQift
//
//  Created by Christian Noon on 11/17/15.
//  Copyright © 2015 Nike. All rights reserved.
//

//import Foundation
//
///// The `Database` class is a lightweight way to create a single writable connection queue and connection pool for
///// all read statements. The read and write APIs are designed to make it simple to execute SQL statements on the
///// appropriate type of `Connection` in a thread-safe manner.
//public class Database {
//    /// The writer connection queue used to execute all write operations.
//    public var writerConnectionQueue: ConnectionQueue!
//
//    /// The reader connection pool used to execute all read operations.
//    public var readerConnectionPool: ConnectionPool!
//
//    // MARK: - Initialization
//
//    /**
//        Initializes the `Database` with the specified storage location, initialization flags and preparation closures.
//
//        The writer connection preparation closure is executed immediately after the writer connection is created. This 
//        can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
//        connection preparation closure is executed immediately after a new reader connection is created.
//
//        - parameter storageLocation:             The storage location path to use during initialization.
//        - parameter multiThreaded:               Whether the database should be multi-threaded. Default is `true`.
//        - parameter sharedCache:                 Whether the database should use a shared cache. Default is `false`.
//        - parameter drainDelay:                  Total time to wait before draining available reader connections. Default is `1.0`.
//        - parameter writerConnectionPreparation: Closure executed when the writer connection is created. Default is `nil`.
//        - parameter readerConnectionPreparation: Closure executed when each new reader connection is created. Default is `nil`.
//
//        - throws: An `Error` if SQLite encounters an error opening the writable connection.
//
//        - returns: The new `Database` instance.
//    */
//    public init(
//        storageLocation: StorageLocation = .InMemory,
//        multiThreaded: Bool = true,
//        sharedCache: Bool = false,
//        drainDelay: NSTimeInterval = 1.0,
//        writerConnectionPreparation: (Connection throws -> Void)? = nil,
//        readerConnectionPreparation: (Connection throws -> Void)? = nil)
//        throws
//    {
//        let writerConnection = try Connection(
//            storageLocation: storageLocation,
//            readOnly: false,
//            multiThreaded: multiThreaded,
//            sharedCache: sharedCache
//        )
//
//        try writerConnectionPreparation?(writerConnection)
//
//        writerConnectionQueue = ConnectionQueue(connection: writerConnection)
//
//        readerConnectionPool = ConnectionPool(
//            storageLocation: storageLocation,
//            availableConnectionDrainDelay: drainDelay,
//            connectionPreparation: readerConnectionPreparation
//        )
//    }
//
//    /**
//        Initializes the `Database` with the specified storage location, initialization flags and preparation closures.
//
//        The writer connection preparation closure is executed immediately after the writer connection is created. This
//        can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
//        connection preparation closure is executed immediately after a new reader connection is created.
//
//        - parameter storageLocation:   The storage location path to use during initialization.
//        - parameter flags:             The bitmask flags to use when initializing the database.
//        - parameter drainDelay:        Total time to wait before draining available reader connections. Default is `1.0`.
//        - parameter writerConnectionPreparation: Closure executed when the writer connection is created. Default is `nil`.
//        - parameter readerConnectionPreparation: Closure executed when each new reader connection is created. Default is `nil`.
//
//        - throws: An `Error` if SQLite encounters an error opening the writable connection.
//
//        - returns: The new `Database` instance.
//    */
//    public init(
//        storageLocation: StorageLocation,
//        flags: Int32,
//        drainDelay: NSTimeInterval = 1.0,
//        writerConnectionPreparation: (Connection throws -> Void)? = nil,
//        readerConnectionPreparation: (Connection throws -> Void)? = nil)
//        throws
//    {
//        let writerConnection = try Connection(storageLocation: storageLocation, flags: flags)
//        try writerConnectionPreparation?(writerConnection)
//
//        writerConnectionQueue = ConnectionQueue(connection: writerConnection)
//
//        readerConnectionPool = ConnectionPool(
//            storageLocation: storageLocation,
//            availableConnectionDrainDelay: drainDelay,
//            connectionPreparation: readerConnectionPreparation
//        )
//    }
//
//    // MARK: - Execution
//
//    /**
//        Executes the specified closure on the read-only connection pool.
//
//        - parameter closure: The closure to execute.
//
//        - throws: An `Error` if SQLite encounters an error executing the closure.
//    */
//    public func executeRead(closure: Connection throws -> Void) throws {
//        try readerConnectionPool.execute { connection in
//            try closure(connection)
//        }
//    }
//
//    /**
//        Executes the specified closure on the writer connection queue.
//
//        - parameter closure: The closure to execute.
//
//        - throws: An `Error` if SQLite encounters an error executing the closure.
//    */
//    public func executeWrite(closure: Connection throws -> Void) throws {
//        try writerConnectionQueue.execute { connection in
//            try closure(connection)
//        }
//    }
//}
