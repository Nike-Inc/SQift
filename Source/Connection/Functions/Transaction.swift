//
//  Transaction.swift
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
