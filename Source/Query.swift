//
//  Query.swift
//  SQift
//
//  Created by Christian Noon on 8/9/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

extension Connection {

    // MARK: - Query Extractable

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
    ///     let synchronous: Int = try db.query("PRAGMA synchronous")
    ///
    /// You MUST be careful when using this method. It force unwraps the `Extractable` even if the value is `nil`. It
    /// is much safer to use the optional `query` counterpart method.
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
    public func query<T: Extractable>(_ sql: String, _ parameters: Bindable?...) throws -> T {
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
    /// You MUST be careful when using this method. It force unwraps the `Extractable` even if the value is `nil`. It
    /// is much safer to use the optional `query` counterpart method.
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
    public func query<T: Extractable>(_ sql: String, _ parameters: [Bindable?]) throws -> T {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first column value of the first row.
    ///
    /// The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
    /// using a SELECT min, max, avg functions or querying the `synchronous` value of the database.
    ///
    ///     let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > :price", [":price": 40_000])
    ///
    /// You MUST be careful when using this method. It force unwraps the `Extractable` even if the value is `nil`. It
    /// is much safer to use the optional `query` counterpart method.
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
    public func query<T: Extractable>(_ sql: String, _ parameters: [String: Bindable?]) throws -> T {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Extractable Optional

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
    public func query<T: Extractable>(_ sql: String, _ parameters: Bindable?...) throws -> T? {
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
    public func query<T: Extractable>(_ sql: String, _ parameters: [Bindable?]) throws -> T? {
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
    public func query<T: Extractable>(_ sql: String, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Row

    /// Runs the SQL query against the database and returns the first `Row` of the result set.
    ///
    /// Querying for the first row of a result set can be convenient in cases where you are attempting to SELECT a 
    /// single row. For example, using a LIMIT filter of 1 would be an excellent candidate for a single row `query`.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
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
    public func query(_ sql: String, _ parameters: Bindable?...) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first `Row` of the result set.
    ///
    /// Querying for the first row of a result set can be convenient in cases where you are attempting to SELECT a
    /// single row. For example, using a LIMIT filter of 1 would be an excellent candidate for a single row `query`.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
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
    public func query(_ sql: String, _ parameters: [Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    /// Runs the SQL query against the database and returns the first `Row` of the result set.
    ///
    /// Querying for the first row of a result set can be convenient in cases where you are attempting to SELECT a
    /// single row. For example, using a LIMIT filter of 1 would be an excellent candidate for a single row `query`.
    ///
    ///     let row = try db.query("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")
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
    public func query(_ sql: String, _ parameters: [String: Bindable?]) throws -> Row? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query ExpressibleByRow

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: Bindable?...) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: [Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query T

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: Bindable?..., body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: [Bindable?], body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: [String: Bindable?], body: (Row) throws -> T) throws -> T? {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Array<Extractable>

    // TODO: test and docstring
    public func query<T: Extractable>(_ sql: String, _ parameters: Bindable?...) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: Extractable>(_ sql: String, _ parameters: [Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: Extractable>(_ sql: String, _ parameters: [String: Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Array<ExpressibleByRow>

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: Bindable?...) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: [Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // TODO: test and docstring
    public func query<T: ExpressibleByRow>(_ sql: String, _ parameters: [String: Bindable?]) throws -> [T] {
        return try prepare(sql).bind(parameters).query()
    }

    // MARK: - Query Array<T>

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: Bindable?..., body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: [Bindable?], body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<T>(_ sql: String, _ parameters: [String: Bindable?], body: (Row) throws -> T) throws -> [T] {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Dictionary

    // TODO: test and docstring
    public func query<Key: Hashable, Value>(
        _ sql: String,
        _ parameters: Bindable?...,
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<Key: Hashable, Value>(
        _ sql: String,
        _ parameters: [Bindable?],
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<Key: Hashable, Value>(
        _ sql: String,
        _ parameters: [String: Bindable?],
        body: (Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // MARK: - Query Dictionary with Result Injection

    // TODO: test and docstring
    public func query<Key, Value>(
        _ sql: String,
        _ parameters: Bindable?...,
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<Key, Value>(
        _ sql: String,
        _ parameters: [Bindable?],
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }

    // TODO: test and docstring
    public func query<Key, Value>(
        _ sql: String,
        _ parameters: [String: Bindable?],
        body: ([Key: Value], Row) throws -> (Key, Value))
        throws -> [Key: Value]
    {
        return try prepare(sql).bind(parameters).query(body)
    }
}
