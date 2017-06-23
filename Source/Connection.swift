//
//  Connection.swift
//  SQift
//
//  Created by Dave Camp on 3/7/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `Connection` class represents a single connection to a SQLite database. 
///
/// For more details about using multiple database connections to improve concurrency, please refer to the 
/// [documentation](https://www.sqlite.org/isolation.html).
public class Connection {

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

    /// Used to capture all information about a trace event.
    ///
    /// For more info about tracing, please see the [documentation](https://www.sqlite.org/c3ref/trace_v2.html).
    ///
    /// - statement:        Invoked when a prepared statement first begins running and possibly at other times during 
    ///                     the execution of the prepared statement, such as the start of each trigger subprogram. The 
    ///                     `statement` represents the expanded SQL statement. The `SQL` represents the unexpanded SQL 
    ///                     text of the prepared statement or a SQL comment that indicates the invocation of a trigger.
    ///
    /// - profile:          Invoked when statement execution is complete. The `statement` represents the expanded SQL 
    ///                     statement. The `seconds` represents the estimated number of seconds that the prepared 
    ///                     statement took to run.
    ///
    /// - row:              Invoked whenever a prepared statement generates a single row of result. The `statement` 
    ///                     represents the expanded SQL statement.
    ///
    /// - connectionClosed: Invoked when a database connection closes. The `connection` is a pointer to the database
    ///                     connection.
    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    public enum TraceEvent: CustomStringConvertible {
        case statement(statement: String, sql: String)
        case profile(statement: String, seconds: Double)
        case row(statement: String)
        case connectionClosed(connection: OpaquePointer)

        /// Returns the `.statement` bitwise mask.
        public static let statementMask = UInt32(SQLITE_TRACE_STMT)

        /// Returns the `.profile` bitwise mask.
        public static let profileMask = UInt32(SQLITE_TRACE_PROFILE)

        /// Returns the `.row` bitwise mask.
        public static let rowMask = UInt32(SQLITE_TRACE_ROW)

        /// Returns the `.connectionClosed` bitwise mask.
        public static let connectionClosedMask = UInt32(SQLITE_TRACE_CLOSE)

        /// A textual description of the `TraceEvent`.
        public var description: String {
            switch self {
            case let .statement(statement, sql):
                return "TraceEvent (Statement): statement: \"\(statement)\", SQL: \"\(sql)\""

            case let .profile(statement, seconds):
                return "TraceEvent (Profile): statement: \"\(statement)\", SQL: \"\(seconds)\""

            case let .row(statement):
                return "TraceEvent (Row): \"\(statement)\""

            case let .connectionClosed(connection):
                return "TraceEvent (ConnectionClosed): connection: \"\(connection)\""
            }
        }
    }

    private typealias TraceCallback = @convention(block) (UnsafePointer<Int8>?) -> Void
    private typealias TraceEventCallback = @convention(block) (UInt32, UnsafeRawPointer?, UnsafeRawPointer?) -> Int32
    private typealias CollationCallback = @convention(block) (UnsafeRawPointer?, Int32, UnsafeRawPointer?, Int32) -> Int32

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

    private var traceCallback: TraceCallback?
    private var traceEventCallback: TraceEventCallback?
    private var collations: [String: CollationCallback] = [:]

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
    public func prepare(_ sql: String, _ parameters: Bindable?...) throws -> Statement {
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
    public func prepare(_ sql: String, _ parameters: [String: Bindable?]) throws -> Statement {
        let statement = try Statement(connection: self, sql: sql)
        if !parameters.isEmpty { try statement.bind(parameters) }

        return statement
    }

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
    public func execute(_ sql: String) throws {
        try check(sqlite3_exec(handle, sql, nil, nil, nil))
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
    public func run(_ sql: String, _ parameters: Bindable?...) throws {
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
    public func run(_ sql: String, _ parameters: [Bindable?]) throws {
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
    public func run(_ sql: String, _ parameters: [String: Bindable?]) throws {
        try prepare(sql).bind(parameters).run()
    }

    /// Fetches the first `Row` from the database after running the SQL statement query.
    ///
    /// Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
    /// row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.
    ///
    ///     let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first `Row` of the query when a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement for fetching the `Row`.
    public func fetch(_ sql: String, _ parameters: Bindable?...) throws -> Row? {
        return try prepare(sql).bind(parameters).fetch()
    }

    /// Fetches the first `Row` from the database after running the SQL statement query.
    ///
    /// Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
    /// row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.
    ///
    ///     let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first `Row` of the query when a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement for fetching the `Row`.
    public func fetch(_ sql: String, _ parameters: [Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).fetch()
    }

    /// Fetches the first `Row` from the database after running the SQL statement query.
    ///
    /// Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
    /// row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.
    ///
    ///     let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Returns: The first `Row` of the query when a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error when running the SQL statement for fetching the `Row`.
    public func fetch(_ sql: String, _ parameters: [String: Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).fetch()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
    ///     let synchronous: Int = try db.query("PRAGMA synchronous")
    ///
    /// You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
    /// is `nil`. It is much safer to use the optional `query` counterpart method.
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: Bindable?...) throws -> T {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
    ///     let synchronous: Int = try db.query("PRAGMA synchronous")
    ///
    /// You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
    /// is `nil`. It is much safer to use the optional `query` counterpart method.
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: [Bindable?]) throws -> T {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > :price", [":price": 40_000])
    ///
    /// You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
    /// is `nil`. It is much safer to use the optional `query` counterpart method.
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: [String: Bindable?]) throws -> T {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
    ///     let synchronous: Int? = try db.query("PRAGMA synchronous")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query if found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: Bindable?...) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
    ///     let synchronous: Int? = try db.query("PRAGMA synchronous")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query if found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: [Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > :price", [":price": 40_000])
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Returns: The first column value of the first row of the query if found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step or data extraction process.
    public func query<T: Binding>(_ sql: String, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
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
    public func transaction(transactionType: TransactionType = .deferred, closure: (Void) throws -> Void) throws {
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
    public func savepoint(_ name: String, closure: (Void) throws -> Void) throws {
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

    // MARK: - Tracing

    /// Registers the callback with SQLite to be called each time a statement calls step.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/profile.html).
    ///
    /// - Parameter callback: The callback closure called when SQLite internally calls step on a statement.
    public func trace(_ callback: ((String) -> Void)?) {
        guard let callback = callback else {
            sqlite3_trace(handle, nil, nil)
            traceCallback = nil
            return
        }

        traceCallback = { cString in
            let trace = cString != nil ? String(cString: cString!) : ""
            callback(trace)
        }

        let rawPointer = unsafeBitCast(traceCallback, to: UnsafeMutableRawPointer.self)

        sqlite3_trace(
            handle,
            { rawPointer, data in
                let traceCallback = unsafeBitCast(rawPointer, to: TraceCallback.self)
                traceCallback(data)
            },
            rawPointer
        )
    }

    /// Registers the callback with SQLite to be called each time a statement calls step.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/trace_v2.html).
    ///
    /// - Parameters:
    ///   - mask:     The bitwise OR-ed mask of trace event constants.
    ///   - callback: The callback closure called when SQLite internally calls step on a statement.
    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    public func traceEvent(mask: UInt32? = nil, callback: ((TraceEvent) -> Void)?) {
        guard let callback = callback else {
            sqlite3_trace_v2(handle, 0, nil, nil)
            traceCallback = nil
            return
        }

        traceEventCallback = { mask, arg1, arg2 in
            guard let arg1 = arg1 else { return 0 }

            let statementOrConnection = OpaquePointer(arg1)
            let event: TraceEvent

            switch mask {
            case UInt32(TraceEvent.statementMask):
                guard let arg2 = arg2 else { return 0 }

                let sql = String(cString: arg2.assumingMemoryBound(to: CChar.self))
                let statement = String(cString: sqlite3_expanded_sql(statementOrConnection))

                event = .statement(statement: statement, sql: sql)

            case UInt32(TraceEvent.profileMask):
                guard
                    let sql = sqlite3_expanded_sql(statementOrConnection),
                    let statement = String(validatingUTF8: sql),
                    let arg2 = arg2
                else { return 0 }

                let nanoseconds = arg2.assumingMemoryBound(to: Int64.self).pointee
                let seconds = Double(nanoseconds) * 0.000_000_001

                event = .profile(statement: statement, seconds: seconds)

            case UInt32(TraceEvent.rowMask):
                guard
                    let sql = sqlite3_expanded_sql(statementOrConnection),
                    let statement = String(validatingUTF8: sql)
                else { return 0 }

                event = .row(statement: statement)

            case UInt32(TraceEvent.connectionClosedMask):
                event = .connectionClosed(connection: statementOrConnection)

            default:
                return 0
            }

            callback(event)

            return 0
        }

        let mask = mask ?? UInt32(SQLITE_TRACE_STMT | SQLITE_TRACE_PROFILE | SQLITE_TRACE_ROW | SQLITE_TRACE_CLOSE)
        let rawPointer = unsafeBitCast(traceEventCallback, to: UnsafeMutableRawPointer.self)

        sqlite3_trace_v2(
            handle,
            mask,
            { mask, rawPointer, arg1, arg2 in
                let traceEventCallback = unsafeBitCast(rawPointer, to: TraceEventCallback.self)
                return traceEventCallback(mask, arg1, arg2)
            },
            rawPointer
        )
    }

    // MARK: - Collations

    /// Registers the custom collation name with SQLite to execute the compare closure when collating.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/datatype3.html#collation).
    ///
    /// - Parameters:
    ///   - name:    The name of the custom collation.
    ///   - compare: The closure used to compare the two strings.
    public func createCollation(withName name: String, compare: @escaping (_ lhs: String, _ rhs: String) -> ComparisonResult) {
        let collationCallback: CollationCallback = { lhsBytes, lhsCount, rhsBytes, rhsCount in
            guard
                let lhsBytes = lhsBytes,
                let rhsBytes = rhsBytes,
                let lhs = String(data: Data(bytes: lhsBytes, count: Int(lhsCount)), encoding: .utf8),
                let rhs = String(data: Data(bytes: rhsBytes, count: Int(rhsCount)), encoding: .utf8)
            else { return Int32(ComparisonResult.orderedAscending.rawValue) }

            return Int32(compare(lhs, rhs).rawValue)
        }

        let rawPointer = unsafeBitCast(collationCallback, to: UnsafeMutableRawPointer.self)

        sqlite3_create_collation_v2(
            handle,
            name,
            SQLITE_UTF8,
            rawPointer,
            { rawPointer, lhsCount, lhsBytes, rhsCount, rhsBytes in
                let collationCallback = unsafeBitCast(rawPointer, to: CollationCallback.self)
                return collationCallback(lhsBytes, lhsCount, rhsBytes, rhsCount)
            },
            nil
        )

        collations[name] = collationCallback
    }

    // MARK: - Internal - Check Result Code

    @discardableResult
    func check(_ code: Int32) throws -> Int32 {
        guard let error = SQLiteError(code: code, connection: self) else { return code }
        throw error
    }
}
