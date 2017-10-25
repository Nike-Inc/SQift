//
//  Query.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

extension Connection {

    // MARK: - Query Extractable

    /// Returns the single value result of a SQL query as the specified type.
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
    /// - Returns: The single value result of the SQL query as type `T` if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: Bindable?...) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the single value result of a SQL query as the specified type.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", [40_000])
    ///     let synchronous: Int? = try db.query("PRAGMA synchronous")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The single value result of the SQL query as type `T` if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: [Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the single value result of a SQL query as the specified type.
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
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The single value result of the SQL query as type `T` if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Row

    /// Returns the single row result of a SQL query as a `Row` to extract the column values from.
    ///
    /// Querying for a single row can be convenient in cases where you are attempting to SELECT a result set that
    /// should only have a single result. For example, using a LIMIT filter of 1.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", "Sedan")
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The single row result of the SQL query if a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query(_ sql: SQL, _ parameters: Bindable?...) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the single row result of a SQL query as a `Row` to extract the column values from.
    ///
    /// Querying for a single row can be convenient in cases where you are attempting to SELECT a result set that
    /// should only have a single result. For example, using a LIMIT filter of 1.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", ["Sedan"])
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The single row result of the SQL query if a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query(_ sql: SQL, _ parameters: [Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the single row result of a SQL query as a `Row` to extract the column values from.
    ///
    /// Querying for a single row can be convenient in cases where you are attempting to SELECT a result set that
    /// should only have a single result. For example, using a LIMIT filter of 1.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = :type LIMIT 1", [":type": "Sedan"])
    ///
    /// For more details, please refer to documentation in the `Statement` class.
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The single row result of the SQL query if a result is found, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query(_ sql: SQL, _ parameters: [String: Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query ExpressibleByRow

    /// Returns an `ExpressibleByRow` result type from a SQL query.
    ///
    /// Querying for an `ExpressibleByRow` type is intended to be used for SELECT and PRAGMA statements that return
    /// a single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", "Sedan")
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: An `ExpressibleByRow` result type from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: Bindable?...) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns an `ExpressibleByRow` result type from a SQL query.
    ///
    /// Querying for an `ExpressibleByRow` type is intended to be used for SELECT and PRAGMA statements that return
    /// a single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", ["Sedan"])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: An `ExpressibleByRow` result type from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: [Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns an `ExpressibleByRow` result type from a SQL query.
    ///
    /// Querying for an `ExpressibleByRow` type is intended to be used for SELECT and PRAGMA statements that return
    /// a single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = :type LIMIT 1", [":type": "Sedan"])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: An `ExpressibleByRow` result type from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query T

    /// Returns a result of type `T` from a SQL query using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return a
    /// single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object (or tuple) representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", "Sedan") { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: A result of type `T` from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: Bindable?..., body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns a result of type `T` from a SQL query using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return a
    /// single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object (or tuple) representing the result.
    ///
    ///     let car: Car? = try db.query("SELECT * FROM cars WHERE type = ? LIMIT 1", ["Sedan"]) { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: A result of type `T` from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: [Bindable?], body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns a result of type `T` from a SQL query using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return a
    /// single row consisting of multiple columns. Generally these columns are best represented as a single model
    /// object (or tuple) representing the result.
    ///
    ///     let sql = "SELECT * FROM cars WHERE type = :type LIMIT 1"
    ///     let car: Car? = try db.query(sql, [":type": "Sedan"]) { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: A result of type `T` from a SQL query if possible, `nil` otherwise.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: [String: Bindable?], body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Array<Extractable>

    /// Returns the result set of a SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// The `query` method is designed for extracting a result set of `Extractable` instances from SELECT and PRAGMA
    /// statements.
    ///
    ///     let names: [String] = try db.query("SELECT name FROM cars WHERE price > ?", 20_000)
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of the SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: Bindable?...) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the result set of a SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// The `query` method is designed for extracting a result set of `Extractable` instances from SELECT and PRAGMA
    /// statements.
    ///
    ///     let names: [String] = try db.query("SELECT name FROM cars WHERE price > ?", [20_000])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of the SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: [Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the result set of a SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// The `query` method is designed for extracting a result set of `Extractable` instances from SELECT and PRAGMA
    /// statements.
    ///
    ///     let names: [String] = try db.query("SELECT name FROM cars WHERE price > :price", [":price": 20_000])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of the SQL query as an array of `Extractable` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: Extractable>(_ sql: SQL, _ parameters: [String: Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Array<ExpressibleByRow>

    /// Returns the result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// Querying for a result set of `ExpressibleByRow` types is intended to be used for SELECT statements that return
    /// rows consisting of multiple columns. Generally these columns are best represented as a single model object
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > ?", 20_000)
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: Bindable?...) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// Querying for a result set of `ExpressibleByRow` types is intended to be used for SELECT statements that return
    /// rows consisting of multiple columns. Generally these columns are best represented as a single model object
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > ?", [20_000])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: [Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    /// Returns the result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// Querying for a result set of `ExpressibleByRow` types is intended to be used for SELECT statements that return
    /// rows consisting of multiple columns. Generally these columns are best represented as a single model object
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > :price", [":price": 20_000])
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///
    /// - Returns: The result set of a SQL query as an array of `ExpressibleByRow` instances of type `T`.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T: ExpressibleByRow>(_ sql: SQL, _ parameters: [String: Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Array<T>

    /// Returns the result set of a SQL query as an array of `T` instances generated using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return rows
    /// consisting of multiple columns. Generally these columns are best represented as a model object (or tuple)
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > ?", 20_000) { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as an array of `T` instances.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: Bindable?..., body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as an array of `T` instances generated using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return rows
    /// consisting of multiple columns. Generally these columns are best represented as a model object (or tuple)
    /// representing the result.
    ///
    ///     let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > ?", [20_000]) { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as an array of `T` instances.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: [Bindable?], body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as an array of `T` instances generated using the specified closure.
    ///
    /// Querying for a `T` type using the specified closure is intended to be used for types that do not conform
    /// to `ExpressibleByRow` (such as tuples), but are generated from SELECT and PRAGMA statements that return rows
    /// consisting of multiple columns. Generally these columns are best represented as a model object (or tuple)
    /// representing the result.
    ///
    ///     let sql = "SELECT * FROM cars WHERE price > :price"
    ///     let cars: [Car] = try db.query(sql, [":price": 20_000]) { try Car(row: $0) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as an array of `T` instances.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<T>(_ sql: SQL, _ parameters: [String: Bindable?], body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Dictionary

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    ///     let sql = "SELECT name, price FROM cars WHERE price > ?"
    ///     let prices: [String: UInt] = try db.query(sql, 20_000) { ($0[0], $0[1]) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key: Hashable, Value>(
        _ sql: SQL,
        _ parameters: Bindable?...,
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    ///     let sql = "SELECT name, price FROM cars WHERE price > ?"
    ///     let prices: [String: UInt] = try db.query(sql, [20_000]) { ($0[0], $0[1]) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key: Hashable, Value>(
        _ sql: SQL,
        _ parameters: [Bindable?],
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    ///     let sql = "SELECT name, price FROM cars WHERE price > :price"
    ///     let prices: [String: UInt] = try db.query(sql, [":price": 20_000]) { ($0[0], $0[1]) }
    ///
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key: Hashable, Value>(
        _ sql: SQL,
        _ parameters: [String: Bindable?],
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Dictionary with Result Injection

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    /// This variant of the `query` method is useful when building a dictionary of dictionaries. It passes the results
    /// to the closure as the collection is being built.
    ///
    ///     let sql = "SELECT name, price, passengers FROM cars WHERE price > ?"
    ///
    ///     let prices: [UInt: [String: UInt]] = try db.query(sql, 20_000) { results, row in
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
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the result set and row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key, Value>(
        _ sql: SQL,
        _ parameters: Bindable?...,
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    /// This variant of the `query` method is useful when building a dictionary of dictionaries. It passes the results
    /// to the closure as the collection is being built.
    ///
    ///     let sql = "SELECT name, price, passengers FROM cars WHERE price > ?"
    ///
    ///     let prices: [UInt: [String: UInt]] = try db.query(sql, [20_000]) { results, row in
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
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the result set and row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key, Value>(
        _ sql: SQL,
        _ parameters: [Bindable?],
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    /// Returns the result set of a SQL query as a dictionary of key-value pairs using the specified closure.
    ///
    /// This variant of the `query` method is useful when building a dictionary of dictionaries. It passes the results
    /// to the closure as the collection is being built.
    ///
    ///     let sql = "SELECT name, price, passengers FROM cars WHERE price > :price"
    ///
    ///     let prices: [UInt: [String: UInt]] = try db.query(sql, [":price": 20_000]) { results, row in
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
    /// - Parameters:
    ///   - sql:        The SQL string to run.
    ///   - parameters: The parameters to bind to the statement.
    ///   - body:       A closure containing the result set and row to use to create the result type.
    ///
    /// - Returns: The result set of a SQL query as a dictionary of key-value pairs.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters and error in the prepare, bind, step, or data extraction process.
    public func query<Key, Value>(
        _ sql: SQL,
        _ parameters: [String: Bindable?],
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }
}
