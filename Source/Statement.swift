//
//  Statement.swift
//  SQift
//
//  Created by Dave Camp on 3/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQLCipher

/// The `Statement` class represents a prepared SQL statement to bind parameters to and execute.
public class Statement {
    var handle: COpaquePointer = nil
    private let connection: Connection

    // MARK: - Initialization

    /**
        Initializes the `Statement` instance by compiling the SQL statement on the specified database.

        For more details, please refer to: <https://www.sqlite.org/c3ref/prepare.html>.

        - parameter connection: The database connection to create a statement for.
        - parameter SQL:        The SQL string to create the statement with.

        - throws: An `Error` if SQLite encounters and error compiling the SQL statement.

        - returns: The new `Statement` instance.
    */
    public init(connection: Connection, SQL: String) throws {
        self.connection = connection
        try connection.check(sqlite3_prepare_v2(connection.handle, SQL, -1, &handle, nil))
    }

    deinit {
        sqlite3_finalize(handle)
    }

    // MARK: - Binding

    /**
        Binds the specified parameters to the statement in their specified order.

        Internally, the binding process leverages the following SQLite methods:
    
            - `sqlite3_bind_parameter_count`
            - `sqlite3_reset`
            - `sqlite3_clear_bindings`
            - `sqlite3_bind_null`
            - `sqlite3_bind_int64`
            - `sqlite3_bind_double`
            - `sqlite3_bind_text`
            - `sqlite3_bind_blob`

        For more information about parameter binding, please refer to: <https://www.sqlite.org/c3ref/bind_blob.html>.

        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if binding the parameters to the statement encounters an error.

        - returns: The statement.
    */
    public func bind(parameters: Bindable?...) throws -> Statement {
        try bind(parameters)
        return self
    }

    /**
        Binds the specified parameters to the statement in their specified order.

        Internally, the binding process leverages the following SQLite methods:

            - `sqlite3_bind_parameter_count`
            - `sqlite3_reset`
            - `sqlite3_clear_bindings`
            - `sqlite3_bind_null`
            - `sqlite3_bind_int64`
            - `sqlite3_bind_double`
            - `sqlite3_bind_text`
            - `sqlite3_bind_blob`

        For more information about parameter binding, please refer to: <https://www.sqlite.org/c3ref/bind_blob.html>.

        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if binding the parameters to the statement encounters an error.

        - returns: The statement.
     */
    public func bind(parameters: [Bindable?]) throws -> Statement {
        try reset()

        let parameterCount = Int(sqlite3_bind_parameter_count(handle))

        guard parameters.count == parameterCount else {
            var error = Error(code: SQLITE_MISUSE, connection: connection)!
            error.message = "Bind expected \(parameterCount) parameters, instead received \(parameters.count)"
            throw error
        }

        for (index, parameter) in parameters.enumerate() {
            try bind(parameter, atIndex: Int32(index + 1))
        }

        return self
    }

    /**
        Binds the specified parameters to the statement by name.

        Internally, the binding process leverages the following SQLite methods:

            - `sqlite3_bind_parameter_count`
            - `sqlite3_bind_parameter_index`
            - `sqlite3_reset`
            - `sqlite3_clear_bindings`
            - `sqlite3_bind_null`
            - `sqlite3_bind_int64`
            - `sqlite3_bind_double`
            - `sqlite3_bind_text`
            - `sqlite3_bind_blob`

        For more information about parameter binding, please refer to: <https://www.sqlite.org/c3ref/bind_blob.html>.

        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if binding the parameters to the statement encounters an error.

        - returns: The statement.
     */
    public func bind(parameters: [String: Bindable?]) throws -> Statement {
        try reset()

        for (key, parameter) in parameters {
            let index = Int32(sqlite3_bind_parameter_index(handle, key))

            guard index > 0 else {
                var error = Error(code: SQLITE_MISUSE, connection: connection)!
                error.message = "Bind could not find index for key: '\(key)'"
                throw error
            }

            try bind(parameter, atIndex: index)
        }

        return self
    }

    // MARK: - Execution

    /**
        Steps through the statement results until statement execution is done.

        - throws: An `Error` if SQLite encounters an error running the statement.

        - returns: The statement.
    */
    public func run() throws -> Statement {
        repeat {} while try step()
        return self
    }

    /**
        Steps through the statement once and fetches the first `Row` of the query.

        Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
        row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.
     
            let row = try db.fetch("SELECT * FROM cars WHERE type='sedan' LIMIT 1")

        - throws: An `Error` if SQLite encounters an error stepping through the statement.

        - returns: The first `Row` of the query.
     */
    public func fetch() throws -> Row? {
        guard try step() else { return nil }
        return Row(statement: self)
    }

    /**
        Returns the first column value of the first row by stepping through the statement once.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt = try db.query("SELECT avg(price) FROM cars")
            let synchronous: Int = try db.query("PRAGMA synchronous")

        You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
        is `nil`. It is much safer to use the optional `query` counterpart method.

        - throws: An `Error` if SQLite encounters an error stepping through the statement.

        - returns: The first column value of the first row of the statement.
     */
    public func query<T: Binding>() throws -> T {
        try step()
        let value = Row(statement: self).valueAtColumnIndex(0)

        return T.fromBindingValue(value!) as! T
    }

    /**
        Returns the first column value of the first row by stepping through the statement once.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt? = try db.query("SELECT avg(price) FROM cars")
            let synchronous: Int? = try db.query("PRAGMA synchronous")

        - throws: An `Error` if SQLite encounters an error stepping through the statement.

        - returns: The first column value of the first row of the statement.
     */
    public func query<T: Binding>() throws -> T? {
        try step()

        let value = Row(statement: self).valueAtColumnIndex(0)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    // MARK: - Internal - Columns

    lazy var columnCount: Int = Int(sqlite3_column_count(self.handle))

    lazy var columnNames: [String] = {
        var names: [String] = []

        for index in 0..<self.columnCount {
            let columnName = String.fromCString(sqlite3_column_name(self.handle, Int32(index)))!
            names.append(columnName)
        }

        return names
    }()

    func columnTypeAtIndex(index: Int) -> Int32 {
        return sqlite3_column_type(handle, Int32(index))
    }

    func columnNameAtIndex(index: Int) -> String {
        return columnNames[index]
    }

    func columnIndexForName(name: String) -> Int? {
        for (index, columnName) in columnNames.enumerate() {
            if columnName == name { return index }
        }

        return nil
    }

    // MARK: - Private - Execution and Binding

    private func reset() throws {
        try connection.check(sqlite3_reset(handle))
        try connection.check(sqlite3_clear_bindings(handle))
    }

    private func step() throws -> Bool {
        return try connection.check(sqlite3_step(handle)) == SQLITE_ROW
    }

    private func bind(parameter: Bindable?, atIndex index: Int32) throws {
        guard let parameter = parameter else {
            try connection.check(sqlite3_bind_null(handle, index))
            return
        }

        switch parameter.bindingValue {
        case .Null:
            try connection.check(sqlite3_bind_null(handle, index))
        case .Integer(let value):
            try connection.check(sqlite3_bind_int64(handle, index, value))
        case .Real(let value):
            try connection.check(sqlite3_bind_double(handle, index, value))
        case .Text(let value):
            try connection.check(sqlite3_bind_text(handle, index, value, -1, SQLITE_TRANSIENT))
        case .Blob(let value):
            try connection.check(sqlite3_bind_blob(handle, index, value.bytes, Int32(value.length), SQLITE_TRANSIENT))
        }
    }
}

// MARK: - SequenceType

extension Statement: SequenceType {
    /**
         Returns an `AnyGenerator<Row>` to satisfy the `SequenceType` protocol conformance.

         This enables `Statement` objects to be iterated over using fast enumeration, map, flatMap, etc.

         - returns: The new `AnyGenerator<Row>` instance.
     */
    public func generate() -> AnyGenerator<Row> {
        return AnyGenerator { try! self.step() ? Row(statement: self) : nil }
    }
}

private let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
