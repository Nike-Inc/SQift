//
//  DatabaseQueue.swift
//  SQift
//
//  Created by Dave Camp on 3/21/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public class DatabaseQueue {
    private let database: Database
    private let queue = dispatch_queue_create("com.nike.fetch.database-queue-\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)

    // MARK: - Initialization

    public init(database: Database) {
        self.database = database
    }

    // MARK: - Execution

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
