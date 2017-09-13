//
//  ConnectionQueue.swift
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
    public var hashValue: Int { return id.hashValue }
}

// MARK: - Equatable

extension ConnectionQueue: Equatable {
    public static func ==(lhs: ConnectionQueue, rhs: ConnectionQueue) -> Bool {
        return lhs.id == rhs.id
    }
}
