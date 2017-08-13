//
//  Connection.swift
//  SQift
//
//  Created by Dave Camp on 3/7/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// Represents a SQL statement to be compiled as a string.
public typealias SQL = String

/// The `Connection` class represents a single connection to a SQLite database. 
///
/// For more details about using multiple database connections to improve concurrency, please refer to the 
/// [documentation](https://www.sqlite.org/isolation.html).
public class Connection {

    // MARK: - Properties

    /// Returns the fileName of the database connection.
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/db_filename.html).
    public var fileName: String { return String(cString: sqlite3_db_filename(handle, nil)) }

    /// Returns whether the database connection is readOnly.
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/stmt_readonly.html).
    public var readOnly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }

    /// Returns whether the database connection is threadSafe.
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/threadsafe.html).
    public var threadSafe: Bool { return sqlite3_threadsafe() > 0 }

    /// Returns the last insert row id of the database connection.
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/last_insert_rowid.html).
    public var lastInsertRowID: Int64 { return sqlite3_last_insert_rowid(handle) }

    /// Returns the number of changes for the most recently completed INSERT, UPDATE or DELETE statement.
    /// For more details, please refer to: the [documentation](https://www.sqlite.org/c3ref/changes.html).
    public var changes: Int { return Int(sqlite3_changes(handle)) }

    /// Returns the total number of changes for all INSERT, UPDATE or DELETE statements since the connection was opened.
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/total_changes.html).
    public var totalChanges: Int { return Int(sqlite3_total_changes(handle)) }

    var handle: OpaquePointer!

    // MARK: - Initialization

    /// Creates the database `Connection` with the specified storage location and initialization flags.
    ///
    /// - Parameters:
    ///   - storageLocation: The storage location path to use during initialization.
    ///   - readOnly:        Whether the connection should be read-only. `false` by default.
    ///   - multiThreaded:   Whether the connection should be multi-threaded. `true` by default.
    ///   - sharedCache:     Whether the connection should use a shared cache. `false` by default.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when opening the database connection.
    public convenience init(
        storageLocation: StorageLocation = .inMemory,
        readOnly: Bool = false,
        multiThreaded: Bool = true,
        sharedCache: Bool = false)
        throws
    {
        var flags: Int32 = 0

        flags |= readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        flags |= multiThreaded ? SQLITE_OPEN_NOMUTEX : SQLITE_OPEN_FULLMUTEX
        flags |= sharedCache ? SQLITE_OPEN_SHAREDCACHE : SQLITE_OPEN_PRIVATECACHE

        try self.init(storageLocation: storageLocation, flags: flags)
    }

    /// Creates the database `Connection` with the specified storage location and initialization flags.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/open.html).
    ///
    /// - Parameters:
    ///   - storageLocation: The storage location path to use during initialization.
    ///   - flags:           The bitmask flags to use when initializing the connection.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when opening the database connection.
    public init(storageLocation: StorageLocation, flags: Int32) throws {
        var tempHandle: OpaquePointer?
        try check(sqlite3_open_v2(storageLocation.path, &tempHandle, flags, nil))

        handle = tempHandle!
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    // MARK: - Execution

    /// Executes the SQL statement in a single-step by internally calling prepare, step and finalize.
    ///
    ///     try db.execute("PRAGMA foreign_keys = true")
    ///     try db.execute("PRAGMA journal_mode = WAL")
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/exec.html).
    ///
    /// - Parameter sql: The SQL string to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when executing the SQL statement.
    public func execute(_ sql: SQL) throws {
        try check(sqlite3_exec(handle, sql, nil, nil, nil))
    }

    /// Causes any active database operation to abort and return at its earliest opportunity.
    ///
    /// It is safe to call this routine from a different thread than is currently running the database operation. If
    /// a SQL operation is nearly fiished at the time it is interrupted, then it might not have an opportunity to
    /// be interrupted and might continue to completion.
    ///
    /// A SQL operation that is interrupted will return a SQLiteError with a [SQLITE_INTERRUPT] error code. If the
    /// interrupted SQL operation is an INSERT, UPDATE, or DELETE that is inside an explicit transaction, the entire
    /// transaction will be rolled back automatically.
    public func interrupt() {
        sqlite3_interrupt(handle)
    }

    // MARK: - Prepare Statement

    /// Prepares a `Statement` instance by compiling the SQL statement and binding the parameter values.
    ///
    ///     let statement = try db.prepare("INSERT INTO cars(name, price) VALUES(?, ?)")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to compile.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The new `Statement` instance.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error compiling the SQL statement or binding the parameters.
    public func prepare(_ sql: SQL, _ parameters: Bindable?...) throws -> Statement {
        let statement = try Statement(connection: self, sql: sql)
        if !parameters.isEmpty { try statement.bind(parameters) }

        return statement
    }

    // TODO: add docstring
    public func prepare(_ sql: SQL, parameters: [Bindable?]) throws -> Statement {
        let statement = try Statement(connection: self, sql: sql)
        if !parameters.isEmpty { try statement.bind(parameters) }

        return statement
    }

    /// Prepares a `Statement` instance by compiling the SQL statement and binding the parameter values.
    ///
    ///     let statement = try db.prepare("INSERT INTO cars(name, price) VALUES(?, ?)")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to compile.
    ///   - parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Returns: The new `Statement` instance.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error compiling the SQL statement or binding the parameters.
    public func prepare(_ sql: SQL, parameters: [String: Bindable?]) throws -> Statement {
        let statement = try Statement(connection: self, sql: sql)
        if !parameters.isEmpty { try statement.bind(parameters) }

        return statement
    }

    // MARK: - Run Statement

    /// Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.
    ///
    ///     try db.run("INSERT INTO cars(name) VALUES(?)", "Honda")
    ///     try db.run("UPDATE cars SET price = ? WHERE name = ?", 27_999, "Honda")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement.
    public func run(_ sql: SQL, _ parameters: Bindable?...) throws {
        try prepare(sql).bind(parameters).run()
    }

    /// Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.
    ///
    ///     try db.run("INSERT INTO cars(name) VALUES(?)", "Honda")
    ///     try db.run("UPDATE cars SET price = ? WHERE name = ?", 27_999, "Honda")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement.
    public func run(_ sql: SQL, parameters: [Bindable?]) throws {
        try prepare(sql).bind(parameters).run()
    }

    /// Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.
    ///
    ///     try db.run("INSERT INTO cars(name) VALUES(:name)", [":name": "Honda"])
    ///     try db.run("UPDATE cars SET price = :price WHERE name = :name", [":price": 27_999, ":name": "Honda"])
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement.
    public func run(_ sql: SQL, parameters: [String: Bindable?]) throws {
        try prepare(sql).bind(parameters).run()
    }

    // MARK: - Attach Database

    /// Attaches another database with the specified name.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/lang_attach.html).
    ///
    /// - Parameters:
    ///   - storageLocation: The storage location of the database to attach.
    ///   - name:            The name of the database being attached.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error attaching the database.
    public func attachDatabase(from storageLocation: StorageLocation, withName name: String) throws {
        let escapedStorageLocation = storageLocation.path.sqift.addingSQLEscapes()
        let escapedName = name.sqift.addingSQLEscapes()

        try execute("ATTACH DATABASE \(escapedStorageLocation) AS \(escapedName)")
    }

    /// Detaches a previously attached database connection.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/lang_detach.html).
    ///
    /// - Parameter name: The name of the database connection to detach.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error detaching the database.
    public func detachDatabase(named name: String) throws {
        try execute("DETACH DATABASE \(name.sqift.addingSQLEscapes())")
    }

    // MARK: - Internal - Check Result Code

    @discardableResult
    func check(_ code: Int32) throws -> Int32 {
        guard let error = SQLiteError(code: code, connection: self) else { return code }
        throw error
    }
}
