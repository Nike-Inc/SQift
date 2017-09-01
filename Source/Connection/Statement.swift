//
//  Statement.swift
//  SQift
//
//  Created by Dave Camp on 3/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQLite3

/// The `Statement` class represents a prepared SQL statement to bind parameters to and execute.
public class Statement {

    // MARK: - Properties

    /// Returns true if the statement has been stepped at least once, but has neither run to completion nor been reset.
    public var isBusy: Bool { return sqlite3_stmt_busy(handle) != 0 }

    /// Returns true if the statement makes no direct changes to the content of the database file.
    ///
    /// Note that there are some cases where this API can return true even though the database is actually modified.
    /// These cases include virtual tables and transactions. For more information, refer to the
    /// SQLite [documentation](https://www.sqlite.org/c3ref/stmt_readonly.html).
    public var isReadOnly: Bool { return sqlite3_stmt_readonly(handle) != 0 }

    /// Returns the SQL text used to create the statement.
    public var sql: SQL { return SQL(cString: sqlite3_sql(handle)) }

    /// Returns the SQL text used to create the statement with the bound parameters expanded.
    ///
    /// Note that this API can return `nil` if there is insufficient memory to hold the result, or if the result would
    /// exceed the maximum string length determined by the [SQLITE_LIMIT_LENGTH].
    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    public var expandedSQL: SQL? {
        guard let expandedSQL = sqlite3_expanded_sql(handle) else { return nil }
        return SQL(cString: expandedSQL)
    }

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
    public init(connection: Connection, sql: SQL) throws {
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

    /// Returns the single value result of a SQL query as the specified type.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars")
    ///     let synchronous: Int? = try db.query("PRAGMA synchronous")
    ///
    /// - Returns: The single value result of the SQL query as type `T` if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: Extractable>() throws -> T? {
        guard try step() else { return nil }

        let value = Row(statement: self).value(at: 0)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    /// Returns the single row result of a SQL query as a `Row` to extract the column values from.
    ///
    /// Querying for a single row can be convenient in cases where you are attempting to SELECT a result set that
    /// should only have a single result. For example, using a LIMIT filter of 1.
    ///
    ///     let row = try db.fetch("SELECT * FROM cars WHERE type='Sedan' LIMIT 1")
    ///
    /// - Returns: The single row result of the SQL query if a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query() throws -> Row? {
        guard try step() else { return nil }
        return Row(statement: self)
    }

    /// Returns an `ExpressibleByRow` result type from a SQL query.
    ///
    /// Querying for an `ExpressibleByRow` type is intended to be used for SELECT and PRAGMA statements that return
    /// a single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = 'Sedan' LIMIT 1")
    ///
    /// - Returns: An `ExpressibleByRow` result type from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: ExpressibleByRow>() throws -> T? {
        guard try step() else { return nil }
        let row = Row(statement: self)

        return try T(row: row)
    }

    /// Returns a result of type `T` from a SQL query using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return a
    /// single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object (or tuple) representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = 'Sedan' LIMIT 1") { try Car(row: $0) }
    ///
    /// - Parameter body: A closure containing the row to use to create the result type.
    ///
    /// - Returns: A result of type `T` from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T>(_ body: (Row) throws -> T) throws -> T? {
        guard try step() else { return nil }
        let row = Row(statement: self)

        return try body(row)
    }

    // MARK: - Query Collection

    /// Returns the result set of a SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// The `query` method is designed for extracting a result set of `Extractable` instances from SELECT and PRAGMA
    /// statements.
    ///
    ///     let names: [String] = try db.query("SELECT name FROM cars")
    ///
    /// - Returns: The result set of the SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: Extractable>() throws -> [T] {
        var results: [T] = []

        while let result: T = try query() {
            results.append(result)
        }

        return results
    }

    /// Returns the result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// Querying for a result set of `ExpressibleByRow` types is intended to be used for SELECT statements that return
    /// rows consisting of multiple columns. Generally these columns are best represented as a single model object
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars")
    ///
    /// - Returns: The result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T: ExpressibleByRow>() throws -> [T] {
        var results: [T] = []

        while try step() {
            let row = Row(statement: self)
            let object = try T(row: row)

            results.append(object)
        }

        return results
    }

    /// Returns the result set of a SQL query as an array of `T` instances generated using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return rows
    /// consisting of multiple columns. Generally these columns are best represented as a model object (or tuple)
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars") { try Car(row: $0) }
    ///
    /// - Parameter body: A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as an array of `T` instances.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<T>(_ body: (Row) throws -> T) throws -> [T] {
        var results: [T] = []

        while try step() {
            let row = Row(statement: self)
            let object = try body(row)

            results.append(object)
        }

        return results
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    ///     let prices: [String: UInt] = try db.query("SELECT name, price FROM cars") { ($0[0], $0[1]) }
    ///
    /// - Parameter body: A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func query<Key: Hashable, Value>(_ body: (Row) throws -> (Key, Value)) throws -> [Key: Value] {
        var results: [Key: Value] = [:]

        while try step() {
            let row = Row(statement: self)
            let (key, value) = try body(row)

            results[key] = value
        }

        return results
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    /// This variant of the `query` method is useful when building a dictionary of dictionaries. It passes the results
    /// to the closure as the collection is being built.
    ///
    ///     let sql = "SELECT name, price, passengers FROM cars"
    ///
    ///     let prices: [UInt: [String: UInt]] = try db.query(sql) { results, row in
    ///         let name: String = row[0]
    ///         let price: UInt = row[1]
    ///         let passengers: UInt = row[2]
    ///
    ///         var result = results[passengers] ?? [:]
    ///         result[name] = price
    ///
    ///         return (passengers, result)
    ///     }
    ///
    /// - Parameter body: A closure containing the result set and row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
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
