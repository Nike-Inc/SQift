//
//  Database.swift
//  SQift
//
//  Created by Dave Camp on 3/7/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public class Database {

    // MARK: - Helper Types

    private typealias TraceCallback = @convention(block) UnsafePointer<Int8> -> Void

    public enum DatabaseType {
        case OnDisk(String)
        case InMemory
        case Temporary

        public var path: String {
            switch self {
            case .OnDisk(let path):
                return path
            case .InMemory:
                return ":memory:"
            case .Temporary:
                return ""
            }
        }
    }

    public enum TransactionType: String {
        case Deferred = "DEFERRED"
        case Immediate = "IMMEDIATE"
        case Exclusive = "EXCLUSIVE"
    }

    // MARK: - Properties

    public var fileName: String { return String.fromCString(sqlite3_db_filename(handle, nil))! }
    public var readOnly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }
    public var threadSafe: Bool { return sqlite3_threadsafe() > 0 }

    public var lastInsertRowID: Int64? {
        let rowID = sqlite3_last_insert_rowid(handle)
        return rowID > 0 ? rowID : nil
    }

    public var changes: Int { return Int(sqlite3_changes(handle)) }
    public var totalChanges: Int { return Int(sqlite3_total_changes(handle)) }

    var handle: COpaquePointer = nil

    private var traceCallback: TraceCallback?

    // MARK: - Initialization

    public convenience init(
        databaseType: DatabaseType = .InMemory,
        readOnly: Bool = false,
        multiThreaded: Bool = true,
        sharedCache: Bool = true)
        throws
    {
        var flags: Int32 = 0

        flags |= readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        flags |= multiThreaded ? SQLITE_OPEN_NOMUTEX : SQLITE_OPEN_FULLMUTEX
        flags |= sharedCache ? SQLITE_OPEN_SHAREDCACHE : SQLITE_OPEN_PRIVATECACHE

        try self.init(databaseType: databaseType, flags: flags)
    }

    public init(databaseType: DatabaseType, flags: Int32) throws {
        try check(sqlite3_open_v2(databaseType.path, &handle, flags, nil))
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    // MARK: - Execution

    public func prepare(statement: String) throws -> Statement {
        return try Statement(database: self, SQL: statement)
    }

    public func execute(SQL: String) throws {
        try check(sqlite3_exec(handle, SQL, nil, nil, nil))
    }

    public func run(SQL: String, _ bindables: Bindable?...) throws {
        try prepare(SQL).bind(bindables).run()
    }

    public func run(SQL: String, bindables: [String: Bindable?]) throws {
        try prepare(SQL).bind(bindables).run()
    }

    public func fetch(SQL: String, _ bindables: Bindable?...) throws -> Row {
        return try prepare(SQL).bind(bindables).fetch()
    }

    public func query<T: Binding>(SQL: String, _ bindables: Bindable?...) throws -> T {
        return try prepare(SQL).bind(bindables).query()
    }

    public func query<T: Binding>(SQL: String, _ bindables: Bindable?...) throws -> T? {
        return try prepare(SQL).bind(bindables).query()
    }

    public func query<T: Binding>(SQL: String, bindables: [String: Bindable?]) throws -> T {
        return try prepare(SQL).bind(bindables).query()
    }

    public func query<T: Binding>(SQL: String, bindables: [String: Bindable?]) throws -> T? {
        return try prepare(SQL).bind(bindables).query()
    }

    // MARK: - Transactions

    public func transaction(transactionType: TransactionType = .Deferred, execution: () throws -> Void) throws {
        try execute("BEGIN \(transactionType.rawValue) TRANSACTION")

        do {
            try execution()
            try execute("COMMIT")
        } catch {
            try execute("ROLLBACK")
            throw error
        }
    }

    public func savepoint(var name: String, execution: () throws -> Void) throws {
        name = name.sanitize()

        try execute("SAVEPOINT \(name)")

        do {
            try execution()
            try execute("RELEASE SAVEPOINT \(name)")
        } catch {
            try execute("ROLLBACK TO SAVEPOINT \(name)")
            throw error
        }
    }

    // MARK: - Attach Database

    public func attachDatabase(databaseType: DatabaseType, withName name: String) throws {
        try execute("ATTACH DATABASE \(databaseType.path.sanitize()) AS \(name.sanitize())")
    }

    public func detachDatabase(name: String) throws {
        try execute("DETACH DATABASE \(name.sanitize())")
    }

    // MARK: - Tracing

    public func trace(callback: (String -> Void)?) {
        guard let callback = callback else {
            sqlite3_trace(handle, nil, nil)
            traceCallback = nil
            return
        }

        traceCallback = { callback(String.fromCString($0)!) }
        let traceCallbackPointer = unsafeBitCast(traceCallback, UnsafeMutablePointer<Void>.self)

        sqlite3_trace(handle, { unsafeBitCast($0, TraceCallback.self)($1) }, traceCallbackPointer)
    }

    // MARK: - Internal - Check Result Code

    func check(code: Int32) throws -> Int32 {
        guard let error = Error(code: code, database: self) else { return code }
        throw error
    }
}
