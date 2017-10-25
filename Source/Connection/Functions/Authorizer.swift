//
//  Authorizer.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQLite3

extension Connection {
    /// A closure executed by SQLite to authorize a particular action being attempted.
    public typealias Authorizer = (AuthorizerAction, String?, String?, String?, String?) -> AuthorizerResult

    // MARK: - Helper Types

    /// Represents an action to be authorized by the authorizer.
    public enum AuthorizerAction {
        case createIndex
        case createTable
        case createTempIndex
        case createTempTable
        case createTempTrigger
        case createTempView
        case createTrigger
        case createView
        case delete
        case dropIndex
        case dropTable
        case dropTempIndex
        case dropTempTable
        case dropTempTrigger
        case dropTempView
        case dropTrigger
        case dropView
        case insert
        case pragma
        case read
        case select
        case transaction
        case update
        case attach
        case detach
        case alterTable
        case reindex
        case analyze
        case createVTable
        case dropVTable
        case function
        case savepoint
        case copy
        case recursive

        init(rawValue: Int32) {
            switch rawValue {
            case SQLITE_CREATE_INDEX:        self = .createIndex
            case SQLITE_CREATE_TABLE:        self = .createTable
            case SQLITE_CREATE_TEMP_INDEX:   self = .createTempIndex
            case SQLITE_CREATE_TEMP_TABLE:   self = .createTempTable
            case SQLITE_CREATE_TEMP_TRIGGER: self = .createTempTrigger
            case SQLITE_CREATE_TEMP_VIEW:    self = .createTempView
            case SQLITE_CREATE_TRIGGER:      self = .createTrigger
            case SQLITE_CREATE_VIEW:         self = .createView
            case SQLITE_DELETE:              self = .delete
            case SQLITE_DROP_INDEX:          self = .dropIndex
            case SQLITE_DROP_TABLE:          self = .dropTable
            case SQLITE_DROP_TEMP_INDEX:     self = .dropTempIndex
            case SQLITE_DROP_TEMP_TABLE:     self = .dropTempTable
            case SQLITE_DROP_TEMP_TRIGGER:   self = .dropTempTrigger
            case SQLITE_DROP_TEMP_VIEW:      self = .dropTempView
            case SQLITE_DROP_TRIGGER:        self = .dropTrigger
            case SQLITE_DROP_VIEW:           self = .dropView
            case SQLITE_INSERT:              self = .insert
            case SQLITE_PRAGMA:              self = .pragma
            case SQLITE_READ:                self = .read
            case SQLITE_SELECT:              self = .select
            case SQLITE_TRANSACTION:         self = .transaction
            case SQLITE_UPDATE:              self = .update
            case SQLITE_ATTACH:              self = .attach
            case SQLITE_DETACH:              self = .detach
            case SQLITE_ALTER_TABLE:         self = .alterTable
            case SQLITE_REINDEX:             self = .reindex
            case SQLITE_ANALYZE:             self = .analyze
            case SQLITE_CREATE_VTABLE:       self = .createVTable
            case SQLITE_DROP_VTABLE:         self = .dropVTable
            case SQLITE_FUNCTION:            self = .function
            case SQLITE_SAVEPOINT:           self = .savepoint
            case SQLITE_RECURSIVE:           self = .recursive
            default:                         self = .copy // no longer used
            }
        }
    }

    /// Represents an authorizer result as to whether to allow a SQL statement to proceed.
    ///
    /// - ok:     Allows the action.
    /// - deny:   Rejects the entire SQL statement with an error.
    /// - ignore: Disallows the specific action but allows the SQL statement to continue to be compiled.
    /// - custom: Throws `SQLiteError` with the specified code if not matching the three default values.
    public enum AuthorizerResult {
        case ok
        case deny
        case ignore
        case custom(Int32)

        var rawValue: Int32 {
            switch self {
            case .ok:                return SQLITE_OK
            case .deny:              return SQLITE_DENY
            case .ignore:            return SQLITE_IGNORE
            case .custom(let value): return value
            }
        }
    }

    private class AuthorizerBox {
        let authorizer: Authorizer

        init(authorizer: @escaping Authorizer) {
            self.authorizer = authorizer
        }

        func authorize(
            action: Int32,
            p1: UnsafePointer<Int8>?,
            p2: UnsafePointer<Int8>?,
            p3: UnsafePointer<Int8>?,
            p4: UnsafePointer<Int8>?)
            -> Int32
        {
            let authAction = AuthorizerAction(rawValue: action)
            let p1 = p1.flatMap { String(cString: $0) }
            let p2 = p2.flatMap { String(cString: $0) }
            let p3 = p3.flatMap { String(cString: $0) }
            let p4 = p4.flatMap { String(cString: $0) }

            return authorizer(authAction, p1, p2, p3, p4).rawValue
        }
    }

    // MARK: - Authorizer

    /// Registers the authorizer with the connection to authorize whether a SQL statement should be executed.
    ///
    /// The authorizer is invoked as SQL statements are being compiled by `prepare`. At various points during the
    /// compilation process, as logic is being created to perform various actions, the authorizer callback is invoked
    /// to see if those actions are allowed. The authorizer callback should return `.ok` to allow the action, `.ignore`
    /// to disallow the specific action but allow the SQL statement to continue to be compiled, or `.deny` to cause the
    /// entire SQL statement to be rejected with an error. If the authorizer callback returns a `.custom` result that
    /// doesn't match any of the three supports results, then the `prepare` or equivalent call that triggered the
    /// authorizer will fail with an error message.
    ///
    /// For more information about SQL authorization, please refer to the
    /// [documentation](https://sqlite.org/c3ref/set_authorizer.html).
    ///
    /// - Parameter authorizer: The closure to execute when SQLite calls the authorizer.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when setting the authorizer.
    public func authorizer(_ authorizer: Authorizer?) throws {
        guard let authorizer = authorizer else {
            sqlite3_set_authorizer(handle, nil, nil)
            authorizerBox = nil
            return
        }

        let box = AuthorizerBox(authorizer: authorizer)
        authorizerBox = box

        let result = sqlite3_set_authorizer(
            handle,
            { boxPointer, action, p1, p2, p3, p4 in
                guard let boxPointer = boxPointer else { return Connection.AuthorizerResult.deny.rawValue }
                let box = Unmanaged<AuthorizerBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.authorize(action: action, p1: p1, p2: p2, p3: p3, p4: p4)
            },
            Unmanaged<AuthorizerBox>.passUnretained(box).toOpaque()
        )

        try check(result)
    }
}
