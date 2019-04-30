//
//  ConnectionQueue.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

/// The `ConnectionQueue` class creates a thread-safe way to access a database `Connection` across multiple threads
/// using a serial dispatch queue. For maximum thread-safety, use a single database `Connection` which is always
/// accessed through a single `ConnectionQueue`.
public class ConnectionQueue {
    /// The database connection to be accessed solely through the connection queue.
    public let connection: Connection

    private let id: String
    private let queue: DispatchQueue

    // MARK: - Initialization

    /// Creates a `ConnectionQueue` instance with the specified connection.
    ///
    /// - Parameter connection: The database connection to be accessed solely through the connection queue.
    public init(connection: Connection) {
        self.connection = connection
        self.id = UUID().uuidString
        self.queue = DispatchQueue(label: "com.nike.sqift.connection-queue-\(id)")
    }

    // MARK: - Execution

    /// Executes the specified closure on the serial dispatch queue.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if executing the closure encounters an error.
    public func execute(closure: (Connection) throws -> Void) throws {
        var executionError: Error?

        queue.sync {
            do {
                try closure(self.connection)
            } catch {
                executionError = error
            }
        }

        if let executionError = executionError {
            throw executionError
        }
    }

    /// Executes the specified closure inside a transaction on the serial dispatch queue.
    ///
    /// - Parameters:
    ///   - transactionType: The transaction type. `.deferred` by default.
    ///   - closure:         The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if executing the transaction or closure encounters an error.
    public func executeInTransaction(
        transactionType: Connection.TransactionType = .deferred,
        closure: (Connection) throws -> Void)
        throws
    {
        var executionError: Error?

        queue.sync {
            do {
                try self.connection.transaction(transactionType: transactionType) {
                    try closure(self.connection)
                }
            } catch {
                executionError = error
            }
        }

        if let executionError = executionError {
            throw executionError
        }
    }

    /// Executes the specified closure inside a savepoint with the specified name on the serial dispatch queue.
    ///
    /// - Parameters:
    ///   - name:    The name of the savepoint.
    ///   - closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if executing the transaction or closure encounters an error.
    public func executeInSavepoint(named name: String, closure: (Connection) throws -> Void) throws {
        var executionError: Error?

        queue.sync {
            do {
                try self.connection.savepoint(named: name) {
                    try closure(self.connection)
                }
            } catch {
                executionError = error
            }
        }

        if let executionError = executionError {
            throw executionError
        }
    }
}

// MARK: - Hashable

extension ConnectionQueue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
}

// MARK: - Equatable

extension ConnectionQueue: Equatable {
    public static func ==(lhs: ConnectionQueue, rhs: ConnectionQueue) -> Bool {
        return lhs.id == rhs.id
    }
}
