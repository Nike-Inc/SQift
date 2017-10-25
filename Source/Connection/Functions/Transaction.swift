//
//  Transaction.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

extension Connection {

    // MARK: - Helper Types

    /// Used to declare the transaction behavior when executing a transaction.
    ///
    /// For more info about transactions, please see the [documentation](https://www.sqlite.org/lang_transaction.html).
    ///
    /// - deferred:  No locks are acquired on the database until the database is first accessed.
    /// - immediate: Other connections can read from the database, but cannot write until the transaction completes.
    /// - exclusive: Other connections cannot read from or write to the database until the transaction completes.
    public enum TransactionType: String {
        case deferred = "DEFERRED"
        case immediate = "IMMEDIATE"
        case exclusive = "EXCLUSIVE"
    }

    // MARK: - Transactions

    /// Executes the specified closure inside of a transaction.
    ///
    /// If an error occurs when running the transaction, it is automatically rolled back before throwing.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/exec.html).
    ///
    /// - Parameters:
    ///   - transactionType: The transaction type.
    ///   - closure:         The logic to execute inside the transaction.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error running the transaction.
    public func transaction(transactionType: TransactionType = .deferred, closure: () throws -> Void) throws {
        try execute("BEGIN \(transactionType.rawValue) TRANSACTION")

        do {
            try closure()
            try execute("COMMIT")
        } catch {
            do { try execute("ROLLBACK") } catch { /** No-op */ }
            throw error
        }
    }

    /// Executes the specified closure inside of a savepoint.
    ///
    /// If an error occurs when running the savepoint, it is automatically rolled back before throwing.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/lang_savepoint.html).
    ///
    /// - Parameters:
    ///   - name:    The name of the savepoint.
    ///   - closure: The logic to execute inside the savepoint.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error running the savepoint.
    public func savepoint(named name: String, closure: () throws -> Void) throws {
        let name = name.sqift.addingSQLEscapes()

        try execute("SAVEPOINT \(name)")

        do {
            try closure()
            try execute("RELEASE SAVEPOINT \(name)")
        } catch {
            do { try execute("ROLLBACK TO SAVEPOINT \(name)") } catch { /** No-op */ }
            throw error
        }
    }
}
