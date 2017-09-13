//
//  Database.swift
//
//  Copyright (c) 2015-present Nike, Inc. (https://www.nike.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// The `Database` class is a lightweight way to create a single writable connection queue and connection pool for
/// all read statements. The read and write APIs are designed to make it simple to execute SQL statements on the
/// appropriate type of `Connection` in a thread-safe manner.
public class Database {
    /// The writer connection queue used to execute all write operations.
    public var writerConnectionQueue: ConnectionQueue!

    /// The reader connection pool used to execute all read operations.
    public var readerConnectionPool: ConnectionPool!

    // MARK: - Initialization

    /// Creates a `Database` instance with the specified storage location, initialization flags and preparation closures.
    ///
    /// The writer connection preparation closure is executed immediately after the writer connection is created. This
    /// can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
    /// connection preparation closure is executed immediately after a new reader connection is created.
    ///
    /// - Parameters:
    ///   - storageLocation:             The storage location path to use during initialization.
    ///   - multiThreaded:               Whether the database should be multi-threaded. `true` by default.
    ///   - sharedCache:                 Whether the database should use a shared cache. `false` by default.
    ///   - drainDelay:                  Total time to wait before draining available reader connections. `1.0` by 
    ///                                  default.
    ///   - writerConnectionPreparation: The closure executed when the writer connection is created. `nil` by default.
    ///   - readerConnectionPreparation: The closure executed when each new reader connection is created. `nil` by 
    ///                                  default.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error opening the writable connection.
    public init(
        storageLocation: StorageLocation = .inMemory,
        multiThreaded: Bool = true,
        sharedCache: Bool = false,
        drainDelay: TimeInterval = 1.0,
        writerConnectionPreparation: ((Connection) throws -> Void)? = nil,
        readerConnectionPreparation: ((Connection) throws -> Void)? = nil)
        throws
    {
        let writerConnection = try Connection(
            storageLocation: storageLocation,
            readOnly: false,
            multiThreaded: multiThreaded,
            sharedCache: sharedCache
        )

        try writerConnectionPreparation?(writerConnection)

        writerConnectionQueue = ConnectionQueue(connection: writerConnection)

        readerConnectionPool = ConnectionPool(
            storageLocation: storageLocation,
            availableConnectionDrainDelay: drainDelay,
            connectionPreparation: readerConnectionPreparation
        )
    }

    /// Creates a `Database` instance with the specified storage location, initialization flags and preparation closures.
    ///
    /// The writer connection preparation closure is executed immediately after the writer connection is created. This
    /// can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
    /// connection preparation closure is executed immediately after a new reader connection is created.
    ///
    /// - Parameters:
    ///   - storageLocation:             The storage location path to use during initialization.
    ///   - flags:                       The bitmask flags to use when initializing the database.
    ///   - drainDelay:                  Total time to wait before draining available reader connections. `1.0` by 
    ///                                  default.
    ///   - writerConnectionPreparation: The closure executed when the writer connection is created. `nil` by default.
    ///   - readerConnectionPreparation: The closure executed when each new reader connection is created. `nil` by 
    ///                                  default.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error opening the writable connection.
    public init(
        storageLocation: StorageLocation,
        flags: Int32,
        drainDelay: TimeInterval = 1.0,
        writerConnectionPreparation: ((Connection) throws -> Void)? = nil,
        readerConnectionPreparation: ((Connection) throws -> Void)? = nil)
        throws
    {
        let writerConnection = try Connection(storageLocation: storageLocation, flags: flags)
        try writerConnectionPreparation?(writerConnection)

        writerConnectionQueue = ConnectionQueue(connection: writerConnection)

        readerConnectionPool = ConnectionPool(
            storageLocation: storageLocation,
            availableConnectionDrainDelay: drainDelay,
            connectionPreparation: readerConnectionPreparation
        )
    }

    // MARK: - Execution

    /// Executes the specified closure on the read-only connection pool.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func executeRead(closure: (Connection) throws -> Void) throws {
        try readerConnectionPool.execute { connection in
            try closure(connection)
        }
    }

    /// Executes the specified closure on the writer connection queue.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func executeWrite(closure: (Connection) throws -> Void) throws {
        try writerConnectionQueue.execute { connection in
            try closure(connection)
        }
    }
}
