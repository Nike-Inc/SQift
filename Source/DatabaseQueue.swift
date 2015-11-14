//
//  DatabaseQueue.swift
//  SQift
//
//  Created by Dave Camp on 3/21/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `DatabaseQueue` class creates a thread-safe way to access a `Database` connection across multiple threads using
/// a serial dispatch queue. For maximum thread-safety, use a single `Database` connection which is always accessed
/// through a single `DatabaseQueue`.
public class DatabaseQueue {
    private let database: Database
    private let queue = dispatch_queue_create("com.nike.fetch.database-queue-\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)

    // MARK: - Initialization

    /**
        Initializes the `DatabaseQueue` instance with the specified database.

        - parameter database: The database to be accessed solely through the database queue.

        - returns: The new `DatabaseQueue` instance.
    */
    public init(database: Database) {
        self.database = database
    }

    // MARK: - Execution

    /**
        Executes the specified closure on the serial dispatch queue.

        - parameter closure: A closure to execute.

        - throws: An `Error` if executing the closure encounters an error.
    */
    public func execute(closure: Database throws -> Void) throws {
        var executionError: ErrorType?

        dispatch_sync(queue) {
            do {
                try closure(self.database)
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
        transactionType: Database.TransactionType = .Deferred,
        closure: Database throws -> Void)
        throws
    {
        var executionError: ErrorType?

        dispatch_sync(queue) {
            do {
                try self.database.transaction(transactionType) {
                    try closure(self.database)
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
    public func executeInSavepoint(name: String, closure: Database throws -> Void) throws {
        var executionError: ErrorType?

        dispatch_sync(queue) {
            do {
                try self.database.savepoint(name) {
                    try closure(self.database)
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
