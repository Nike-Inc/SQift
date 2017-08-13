//
//  Statement.swift
//  SQift
//
//  Created by Dave Camp on 3/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `Statement` class represents a prepared SQL statement to bind parameters to and execute.
public class Statement {

    // MARK: - Properties

    var handle: OpaquePointer!

    lazy var columnCount: Int = Int(sqlite3_column_count(self.handle))

    lazy var columnNames: [String] = {
        return (0..<self.columnCount).map { String(cString: sqlite3_column_name(self.handle, Int32($0))) }
    }()

    private let connection: Connection

    // MARK: - Initialization

    /// Creates a `Statement` instance by compiling the SQL statement on the specified database.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/prepare.html).
    ///
    /// - Parameters:
    ///   - connection: The database connection to create a statement for.
    ///   - sql:        The SQL string to create the statement with.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error compiling the SQL statement.
    public init(connection: Connection, sql: String) throws {
        self.connection = connection

        var tempHandle: OpaquePointer?
        try connection.check(sqlite3_prepare_v2(connection.handle, sql, -1, &tempHandle, nil))

        handle = tempHandle!
    }

    deinit {
        sqlite3_finalize(handle)
    }

    // MARK: - Binding

    /// Binds the specified parameters to the statement in their specified order.
    ///
    /// Internally, the binding process leverages the following SQLite methods:
    ///
    /// - `sqlite3_bind_parameter_count`
    /// - `sqlite3_reset`
    /// - `sqlite3_clear_bindings`
    /// - `sqlite3_bind_null`
    /// - `sqlite3_bind_int64`
    /// - `sqlite3_bind_double`
    /// - `sqlite3_bind_text`
    /// - `sqlite3_bind_blob`
    ///
    /// For more information about parameter binding, please refer to the 
    /// [documentation](https://www.sqlite.org/c3ref/bind_blob.html).
    ///
    /// - Parameter parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The statement.
    ///
    /// - Throws: A `SQLiteError` if binding the parameters to the statement encounters an error.
    @discardableResult
    public func bind(_ parameters: Bindable?...) throws -> Statement {
        try bind(parameters)
        return self
    }

    /// Binds the specified parameters to the statement in their specified order.
    ///
    /// Internally, the binding process leverages the following SQLite methods:
    ///
    /// - `sqlite3_bind_parameter_count`
    /// - `sqlite3_reset`
    /// - `sqlite3_clear_bindings`
    /// - `sqlite3_bind_null`
    /// - `sqlite3_bind_int64`
    /// - `sqlite3_bind_double`
    /// - `sqlite3_bind_text`
    /// - `sqlite3_bind_blob`
    ///
    /// For more information about parameter binding, please refer to the 
    /// [documentation](https://www.sqlite.org/c3ref/bind_blob.html).
    ///
    /// - Parameter parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The statement.
    ///
    /// - Throws: A `SQLiteError` if binding the parameters to the statement encounters an error.
    @discardableResult
    public func bind(_ parameters: [Bindable?]) throws -> Statement {
        try reset()

        let parameterCount = Int(sqlite3_bind_parameter_count(handle))

        guard parameters.count == parameterCount else {
            var error = SQLiteError(code: SQLITE_MISUSE, connection: connection)!
            error.message = "Bind expected \(parameterCount) parameters, instead received \(parameters.count)"
            throw error
        }

        for (index, parameter) in parameters.enumerated() {
            try bind(parameter, atIndex: Int32(index + 1))
        }

        return self
    }

    /// Binds the specified parameters to the statement by name.
    ///
    /// Internally, the binding process leverages the following SQLite methods:
    ///
    /// - `sqlite3_bind_parameter_count`
    /// - `sqlite3_bind_parameter_index`
    /// - `sqlite3_reset`
    /// - `sqlite3_clear_bindings`
    /// - `sqlite3_bind_null`
    /// - `sqlite3_bind_int64`
    /// - `sqlite3_bind_double`
    /// - `sqlite3_bind_text`
    /// - `sqlite3_bind_blob`
    ///
    /// For more information about parameter binding, please refer to the 
    /// [documentation](https://www.sqlite.org/c3ref/bind_blob.html).
    ///
    /// - Parameter parameters: A dictionary of key-value pairs to bind to the statement.
    ///
    /// - Returns: The statement.
    ///
    /// - Throws: A `SQLiteError` if binding the parameters to the statement encounters an error.
    @discardableResult
    public func bind(_ parameters: [String: Bindable?]) throws -> Statement {
        try reset()

        for (key, parameter) in parameters {
            let index = Int32(sqlite3_bind_parameter_index(handle, key))

            guard index > 0 else {
                var error = SQLiteError(code: SQLITE_MISUSE, connection: connection)!
                error.message = "Bind could not find index for key: '\(key)'"
                throw error
            }

            try bind(parameter, atIndex: index)
        }

        return self
    }

    // MARK: - Execution

    /// Steps through the statement results until statement execution is done.
    ///
    /// - Returns: The statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error running the statement.
    @discardableResult
    public func run() throws -> Statement {
        while try step() {}
        return self
    }

    // MARK: - Query Value

    /// Returns the first column value of the first row by stepping through the statement once.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars")
    ///     let synchronous: Int = try db.query("PRAGMA synchronous")
    ///
    /// You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
    /// is `nil`. It is much safer to use the optional `query` counterpart method.
    ///
    /// - Returns: The first column value of the first row of the statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: Extractable>() throws -> T {
        let result: T? = try query()
        return result!
    }

    /// Returns the first column value of the first row by stepping through the statement once.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars")
    ///     let synchronous: Int? = try db.query("PRAGMA synchronous")
    ///
    /// - Returns: The first column value of the first row of the statement.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: Extractable>() throws -> T? {
        guard try step() else { return nil }

        let value = Row(statement: self).value(at: 0)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    // TODO: Change fetch to query and add ExpressibleByRow option for it as well

    /// Steps through the statement once and fetches the first `Row` of the query.
    ///
    /// Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
    /// row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.
    ///
    ///     let row = try db.fetch("SELECT * FROM cars WHERE type='sedan' LIMIT 1")
    ///
    /// - Returns: The first `Row` of the query.
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query() throws -> Row? {
        guard try step() else { return nil }
        return Row(statement: self)
    }

    // TODO: docstring and tests
    public func query<T: ExpressibleByRow>() throws -> T? {
        guard try step() else { return nil }
        let row = Row(statement: self)

        return try T(row: row)
    }

    public func query<T>(_ body: (Row) throws -> T) throws -> T? {
        guard try step() else { return nil }
        let row = Row(statement: self)

        return try body(row)
    }

    // MARK: - Query Collection

    // TODO: docstring and tests
    public func query<T: Extractable>() throws -> [T] {
        var results: [T] = []

        while let result: T = try query() {
            results.append(result)
        }

        return results
    }

    // TODO: docstring and tests
    public func query<T: ExpressibleByRow>() throws -> [T] {
        var results: [T] = []

        while try step() {
            let row = Row(statement: self)
            let object = try T(row: row)

            results.append(object)
        }

        return results
    }

    // TODO: docstring and tests
    public func query<T>(_ body: (Row) throws -> T) throws -> [T] {
        var results: [T] = []

        while try step() {
            let row = Row(statement: self)
            let object = try body(row)

            results.append(object)
        }

        return results
    }

    // TODO: docstring and tests
    public func query<Key: Hashable, Value>(_ body: (Row) throws -> (Key, Value)) throws -> [Key: Value] {
        var results: [Key: Value] = [:]

        while try step() {
            let row = Row(statement: self)
            let (key, value) = try body(row)

            results[key] = value
        }

        return results
    }

    // TODO: docstring and tests
    public func query<Key, Value>(_ body: ([Key: Value], Row) throws -> (Key, Value)) throws -> [Key: Value] {
        var results: [Key: Value] = [:]

        while try step() {
            let row = Row(statement: self)
            let (key, value) = try body(results, row)

            results[key] = value
        }

        return results
    }

    // MARK: - Internal - Columns

    func columnType(at index: Int) -> Int32 {
        return sqlite3_column_type(handle, Int32(index))
    }

    func columnName(at index: Int) -> String {
        return columnNames[index]
    }

    func columnIndex(forName name: String) -> Int? {
        for (index, columnName) in columnNames.enumerated() {
            if columnName == name { return index }
        }

        return nil
    }

    // MARK: - Internal - Step

    func step() throws -> Bool {
        return try connection.check(sqlite3_step(handle)) == SQLITE_ROW
    }

    // MARK: - Private - Execution and Binding

    private func reset() throws {
        try connection.check(sqlite3_reset(handle))
        try connection.check(sqlite3_clear_bindings(handle))
    }

    private func bind(_ parameter: Bindable?, atIndex index: Int32) throws {
        guard let parameter = parameter else {
            try connection.check(sqlite3_bind_null(handle, index))
            return
        }

        switch parameter.bindingValue {
        case .null:
            try connection.check(sqlite3_bind_null(handle, index))

        case .integer(let value):
            try connection.check(sqlite3_bind_int64(handle, index, value))

        case .real(let value):
            try connection.check(sqlite3_bind_double(handle, index, value))

        case .text(let value):
            try connection.check(sqlite3_bind_text(handle, index, value, -1, SQLITE_TRANSIENT))

        case .blob(let value):
            try value.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                try connection.check(sqlite3_bind_blob(handle, index, bytes, Int32(value.count), SQLITE_TRANSIENT))
            }
        }
    }
}

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
