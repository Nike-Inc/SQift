//
//  ConnectionQueue.swift
//  SQift
//
//  Created by Dave Camp on 3/21/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `ConnectionQueue` class creates a thread-safe way to access a database `Connection` across multiple threads
/// using a serial dispatch queue. For maximum thread-safety, use a single database `Connection` which is always
/// accessed through a single `ConnectionQueue`.
public class ConnectionQueue {
    /// The database connection to be accessed solely through the connection queue.
    public let connection: Connection

    private let id: String
    private let queue: dispatch_queue_t

    // MARK: - Initialization

    /**
        Initializes the `ConnectionQueue` instance with the specified connection.

        - parameter connection: The database connection to be accessed solely through the connection queue.

        - returns: The new `ConnectionQueue` instance.
    */
    public init(connection: Connection) {
        self.connection = connection
        self.id = NSUUID().UUIDString
        self.queue = dispatch_queue_create("com.nike.sqift.connection-queue-\(id)", DISPATCH_QUEUE_SERIAL)
    }

    // MARK: - Execution

    /**
        Executes the specified closure on the serial dispatch queue.

        - parameter closure: A closure to execute.

        - throws: An `Error` if executing the closure encounters an error.
    */
    public func execute(closure: Connection throws -> Void) throws {
        var executionError: ErrorType?

        dispatch_sync(queue) {
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

    /**
        Executes the specified closure inside a transaction on the serial dispatch queue.

        - parameter closure: A closure to execute.

        - throws: An `Error` if executing the transaction or closure encounters an error.
    */
    public func executeInTransaction(
        transactionType: Connection.TransactionType = .Deferred,
        closure: Connection throws -> Void)
        throws
    {
        var executionError: ErrorType?

        dispatch_sync(queue) {
            do {
                try self.connection.transaction(transactionType) {
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

    /**
        Executes the specified closure inside a savepoint with the specified name on the serial dispatch queue.

        - parameter closure: A closure to execute.

        - throws: An `Error` if executing the transaction or closure encounters an error.
    */
    public func executeInSavepoint(name: String, closure: Connection throws -> Void) throws {
        var executionError: ErrorType?

        dispatch_sync(queue) {
            do {
                try self.connection.savepoint(name) {
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

extension ConnectionQueue: Equatable {}

public func ==(lhs: ConnectionQueue, rhs: ConnectionQueue) -> Bool {
    return lhs.id == rhs.id
}
