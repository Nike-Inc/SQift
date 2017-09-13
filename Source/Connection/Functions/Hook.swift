//
//  Hook.swift
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
import SQLite3

// MARK: Update Hook

extension Connection {
    /// A closure executed when a row is inserted, updated, or deleted in a rowID table that takes four parameters:
    /// the update hook type, the name of the database, the name of the table, and the rowID of the row being modified.
    public typealias UpdateHook = (UpdateHookType, _ databaseName: String?, _ tableName: String?, _ rowID: Int64) -> Void

    /// Represents the different types of update hooks operations that can be called.
    public enum UpdateHookType {
        case insert
        case update
        case delete

        var rawValue: Int32 {
            switch self {
            case .insert: return SQLITE_INSERT
            case .update: return SQLITE_UPDATE
            case .delete: return SQLITE_DELETE
            }
        }

        init?(rawValue: Int32) {
            switch rawValue {
            case UpdateHookType.insert.rawValue: self = .insert
            case UpdateHookType.update.rawValue: self = .update
            case UpdateHookType.delete.rawValue: self = .delete
            default:                             return nil
            }
        }
    }

    private class UpdateHookBox {
        let hook: UpdateHook
        init(hook: @escaping UpdateHook) { self.hook = hook }

        func execute(
            type: Int32,
            databaseName: UnsafePointer<Int8>?,
            tableName: UnsafePointer<Int8>?,
            rowID: sqlite3_int64)
        {
            guard let type = UpdateHookType(rawValue: type) else { return }

            let databaseName = databaseName != nil ? String(cString: databaseName!) : nil
            let tableName = tableName != nil ? String(cString: tableName!) : nil

            hook(type, databaseName, tableName, rowID)
        }
    }

    /// Registers the hook to be invoked whenever a row is inserted, updated, or deleted in a rowID table.
    ///
    /// The update hook implementation must not do anything that will modify the database connection that invoked the
    /// update hook. Any actions to modify the database connection must be deferred until after the completion of the
    /// `step()` call that triggered the update hook.
    ///
    /// For more information about rollback hooks, please refer to the
    /// [documentation](https://sqlite.org/c3ref/update_hook.html).
    ///
    /// - Parameter hook: The closure to execute each time a row is inserted, updated, or deleted.
    public func updateHook(_ hook: UpdateHook?) {
        guard let hook = hook else {
            sqlite3_update_hook(handle, nil, nil)
            updateHookBox = nil
            return
        }

        let box = UpdateHookBox(hook: hook)
        updateHookBox = box

        sqlite3_update_hook(
            handle,
            { (boxPointer: UnsafeMutableRawPointer?, type, databaseName, tableName, rowID) in
                guard let boxPointer = boxPointer else { return }
                let box = Unmanaged<UpdateHookBox>.fromOpaque(boxPointer).takeUnretainedValue()
                box.execute(type: type, databaseName: databaseName, tableName: tableName, rowID: rowID)
            },
            Unmanaged<UpdateHookBox>.passUnretained(box).toOpaque()
        )
    }
}

// MARK: - Commit Hook

extension Connection {
    /// A closure executed when a transaction is committed. It does not take any parameters and should return `false`
    /// to allow the commit operation to continue, and `true` to convert the commit into a rollback operation.
    public typealias CommitHook = () -> Bool

    private class CommitHookBox {
        let hook: CommitHook
        init(hook: @escaping CommitHook) { self.hook = hook }
    }

    /// Registers the hook to be invoked whenever a transaction is committed.
    ///
    /// If the return value of the commit hook is `true`, then the commit is converted into a rollback operation. If
    /// the return value is `false`, the commit operation is allowed to continue normally. For more information about
    /// commit hooks, please refer to the [documentation](https://sqlite.org/c3ref/commit_hook.html).
    ///
    /// - Parameter hook: The closure to execute each time a transaction is committed.
    public func commitHook(_ hook: CommitHook?) {
        guard let hook = hook else {
            sqlite3_commit_hook(handle, nil, nil)
            commitHookBox = nil
            return
        }

        let box = CommitHookBox(hook: hook)
        commitHookBox = box

        sqlite3_commit_hook(
            handle,
            { (boxPointer: UnsafeMutableRawPointer?) -> Int32 in
                guard let boxPointer = boxPointer else { return 0 }
                let box = Unmanaged<CommitHookBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.hook() ? 1 : 0
            },
            Unmanaged<CommitHookBox>.passUnretained(box).toOpaque()
        )
    }
}

// MARK: - Rollback Hook

extension Connection {
    /// A closure executed when a transaction is rolled back.
    public typealias RollbackHook = () -> Void

    private class RollbackHookBox {
        let hook: RollbackHook
        init(hook: @escaping RollbackHook) { self.hook = hook }
    }

    /// Registers the hook to be invoked whenever a transaction is rolled back.
    ///
    /// For more information about rollback hooks, please refer to the
    /// [documentation](https://sqlite.org/c3ref/commit_hook.html).
    ///
    /// - Parameter hook: The closure to execute each time a transaction is rolled back.
    public func rollbackHook(_ hook: RollbackHook?) {
        guard let hook = hook else {
            sqlite3_rollback_hook(handle, nil, nil)
            rollbackHookBox = nil
            return
        }

        let box = RollbackHookBox(hook: hook)
        rollbackHookBox = box

        sqlite3_rollback_hook(
            handle,
            { (boxPointer: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return }
                let box = Unmanaged<RollbackHookBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.hook()
            },
            Unmanaged<RollbackHookBox>.passUnretained(box).toOpaque()
        )
    }
}
