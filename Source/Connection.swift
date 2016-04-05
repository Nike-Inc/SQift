//
//  Connection.swift
//  SQift
//
//  Created by Dave Camp on 3/7/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQLCipher

/// The `Connection` class represents a single connection to a SQLite database. For more details about using multiple
/// database connections to improve concurrency, see <https://www.sqlite.org/isolation.html>.
public class Connection {

    // MARK: - Helper Types

    /**
        Used to declare the transaction behavior when executing a transaction.

        For more info about transactions, see <https://www.sqlite.org/lang_transaction.html>.
    */
    public enum TransactionType: String {
        case Deferred = "DEFERRED"
        case Immediate = "IMMEDIATE"
        case Exclusive = "EXCLUSIVE"
    }

    private typealias TraceCallback = @convention(block) UnsafePointer<Int8> -> Void
    private typealias CollationCallback = @convention(block) (UnsafePointer<Void>, Int32, UnsafePointer<Void>, Int32) -> Int32

    // MARK: - Properties

    /// Returns the fileName of the database connection.
    /// For more details, please refer to <https://www.sqlite.org/c3ref/db_filename.html>.
    public var fileName: String { return String.fromCString(sqlite3_db_filename(handle, nil))! }

    /// Returns whether the database connection is readOnly.
    /// For more details, please refer to <https://www.sqlite.org/c3ref/stmt_readonly.html>.
    public var readOnly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }

    /// Returns whether the database connection is threadSafe.
    /// For more details, please refer to <https://www.sqlite.org/c3ref/threadsafe.html>.
    public var threadSafe: Bool { return sqlite3_threadsafe() > 0 }

    /// Returns the last insert row id of the database connection.
    /// For more details, please refer to <https://www.sqlite.org/c3ref/last_insert_rowid.html>.
    public var lastInsertRowID: Int64 { return sqlite3_last_insert_rowid(handle) }

    /// Returns the number of changes for the most recently completed INSERT, UPDATE or DELETE statement.
    /// For more details, please refer to: <https://www.sqlite.org/c3ref/changes.html>.
    public var changes: Int { return Int(sqlite3_changes(handle)) }

    /// Returns the total number of changes for all INSERT, UPDATE or DELETE statements since the connection was opened.
    /// For more details, please refer to: <https://www.sqlite.org/c3ref/total_changes.html>.
    public var totalChanges: Int { return Int(sqlite3_total_changes(handle)) }

    var handle: COpaquePointer = nil

    private var traceCallback: TraceCallback?
    private var collations: [String: CollationCallback] = [:]

    // MARK: - Initialization

    /**
        Initializes the database `Connection` with the specified storage location and initialization flags.

        For more details, please refer to: <https://www.sqlite.org/c3ref/open.html>.

        - parameter storageLocation: The storage location path to use during initialization.
        - parameter readOnly:        Whether the connection should be read-only. Default is `false`.
        - parameter multiThreaded:   Whether the connection should be multi-threaded. Default is `true`.
        - parameter sharedCache:     Whether the connection should use a shared cache. Default is `false`.

        - throws: An `Error` if SQLite encounters an error when opening the database connection.

        - returns: The new database `Connection` instance.
    */
    public convenience init(
        storageLocation: StorageLocation = .InMemory,
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

    /**
        Initializes the `Database` connection with the specified storage location and initialization flags.

        For more details, please refer to: <https://www.sqlite.org/c3ref/open.html>.

        - parameter storageLocation: The storage location path to use during initialization.
        - parameter flags:           The bitmask flags to use when initializing the connection.

        - throws: An `Error` if SQLite encounters an error when opening the database connection.

        - returns: The new database `Connection` instance.
    */
    public init(storageLocation: StorageLocation, flags: Int32) throws {
        try check(sqlite3_open_v2(storageLocation.path, &handle, flags, nil))
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    // MARK: - Execution

    /**
        Prepares a `Statement` instance by compiling the SQL statement and binding the parameter values.

            let statement = try db.prepare("INSERT INTO cars(name, price) VALUES(?, ?)")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to compile.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error compiling the SQL statement or binding the parameters.

        - returns: The new `Statement` instance.
    */
    public func prepare(SQL: String, _ parameters: Bindable?...) throws -> Statement {
        let statement = try Statement(connection: self, SQL: SQL)

        if !parameters.isEmpty {
            try statement.bind(parameters)
        }

        return statement
    }

    /**
        Prepares a `Statement` instance by compiling the SQL statement and binding the parameter values.

            let statement = try db.prepare("INSERT INTO cars(name, price) VALUES(?, ?)")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to compile.
        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if SQLite encounters and error compiling the SQL statement or binding the parameters.

        - returns: The new `Statement` instance.
    */
    public func prepare(SQL: String, _ parameters: [String: Bindable?]) throws -> Statement {
        let statement = try Statement(connection: self, SQL: SQL)

        if !parameters.isEmpty {
            try statement.bind(parameters)
        }

        return statement
    }

    /**
        Executes the SQL statement in a single-step by internally calling prepare, step and finalize.

            try db.execute("PRAGMA foreign_keys = true")
            try db.execute("PRAGMA journal_mode = WAL")

        For more details, please refer to: <https://www.sqlite.org/c3ref/exec.html>.

        - parameter SQL: The SQL string to execute.

        - throws: An `Error` if SQLite encounters and error when executing the SQL statement.
    */
    public func execute(SQL: String) throws {
        try check(sqlite3_exec(handle, SQL, nil, nil, nil))
    }

    /**
        Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.

            try db.run("INSERT INTO cars(name) VALUES(?)", "Honda")
            try db.run("UPDATE cars SET price = ? WHERE name = ?", 27_999, "Honda")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement.
    */
    public func run(SQL: String, _ parameters: Bindable?...) throws {
        try prepare(SQL).bind(parameters).run()
    }

    /**
        Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.

            try db.run("INSERT INTO cars(name) VALUES(?)", "Honda")
            try db.run("UPDATE cars SET price = ? WHERE name = ?", 27_999, "Honda")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement.
    */
    public func run(SQL: String, _ parameters: [Bindable?]) throws {
        try prepare(SQL).bind(parameters).run()
    }

    /**
        Runs the SQL statement in a single-step by internally calling prepare, bind, step and finalize.

            try db.run("INSERT INTO cars(name) VALUES(:name)", [":name": "Honda"])
            try db.run("UPDATE cars SET price = :price WHERE name = :name", [":price": 27_999, ":name": "Honda"])

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement.
    */
    public func run(SQL: String, _ parameters: [String: Bindable?]) throws {
        try prepare(SQL).bind(parameters).run()
    }

    /**
        Fetches the first `Row` from the database after running the SQL statement query.

        Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
        row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.

            let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement for fetching the `Row`.

        - returns: The first `Row` of the query.
    */
    public func fetch(SQL: String, _ parameters: Bindable?...) throws -> Row? {
        return try prepare(SQL).bind(parameters).fetch()
    }

    /**
        Fetches the first `Row` from the database after running the SQL statement query.

        Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
        row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.

            let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement for fetching the `Row`.

        - returns: The first `Row` of the query.
    */
    public func fetch(SQL: String, _ parameters: [Bindable?]) throws -> Row? {
        return try prepare(SQL).bind(parameters).fetch()
    }

    /**
        Fetches the first `Row` from the database after running the SQL statement query.

        Fetching the first row of a query can be convenient in cases where you are attempting to SELECT a single
        row. For example, using a LIMIT filter of 1 would be an excellent candidate for a `fetch`.

            let row = try db.fetch("SELECT * FROM cars WHERE type = 'sedan' LIMIT 1")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if SQLite encounters and error when running the SQL statement for fetching the `Row`.

        - returns: The first `Row` of the query.
    */
    public func fetch(SQL: String, _ parameters: [String: Bindable?]) throws -> Row? {
        return try prepare(SQL).bind(parameters).fetch()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
            let synchronous: Int = try db.query("PRAGMA synchronous")

        You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
        is `nil`. It is much safer to use the optional `query` counterpart method.

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: Bindable?...) throws -> T {
        return try prepare(SQL).bind(parameters).query()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
            let synchronous: Int = try db.query("PRAGMA synchronous")

        You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
        is `nil`. It is much safer to use the optional `query` counterpart method.

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: [Bindable?]) throws -> T {
        return try prepare(SQL).bind(parameters).query()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt = try db.query("SELECT avg(price) FROM cars WHERE price > :price", [":price": 40_000])

        You MUST be careful when using this method. It force unwraps the `Binding` even if the binding value
        is `nil`. It is much safer to use the optional `query` counterpart method.

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: [String: Bindable?]) throws -> T {
        return try prepare(SQL).bind(parameters).query()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
            let synchronous: Int? = try db.query("PRAGMA synchronous")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: Bindable?...) throws -> T? {
        return try prepare(SQL).bind(parameters).query()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
            let synchronous: Int? = try db.query("PRAGMA synchronous")

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: The parameters to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: [Bindable?]) throws -> T? {
        return try prepare(SQL).bind(parameters).query()
    }

    /**
        Runs the SQL query against the database and returns the first column value of the first row.

        The `query` method is designed for extracting single values from SELECT and PRAGMA statements. For example,
        using a SELECT min, max, avg functions or querying the `synchronous` value of the database.

            let min: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > :price", [":price": 40_000])

        For more details, please refer to documentation in the `Statement` class.

        - parameter SQL:        The SQL string to run.
        - parameter parameters: A dictionary of key/value pairs to bind to the statement.

        - throws: An `Error` if SQLite encounters and error in the prepare, bind, step or data extraction process.

        - returns: The first column value of the first row of the query.
    */
    public func query<T: Binding>(SQL: String, _ parameters: [String: Bindable?]) throws -> T? {
        return try prepare(SQL).bind(parameters).query()
    }

    // MARK: - Transactions

    /**
        Executes the specified closure inside of a transaction.

        If an error occurs when running the transaction, it is automatically rolled back before throwing.

        For more details, please refer to: <https://www.sqlite.org/c3ref/exec.html>.

        - parameter transactionType: The transaction type.
        - parameter closure:         The logic to execute inside the transaction.

        - throws: An `Error` if SQLite encounters an error running the transaction.
    */
    public func transaction(transactionType: TransactionType = .Deferred, closure: Void throws -> Void) throws {
        try execute("BEGIN \(transactionType.rawValue) TRANSACTION")

        do {
            try closure()
            try execute("COMMIT")
        } catch {
            do { try execute("ROLLBACK") } catch { /** No-op */ }
            throw error
        }
    }

    /**
        Executes the specified closure inside of a savepoint.

        If an error occurs when running the savepoint, it is automatically rolled back before throwing.

        For more details, please refer to: <https://www.sqlite.org/lang_savepoint.html>.

        - parameter name:    The name of the savepoint.
        - parameter closure: The logic to execute inside the savepoint.

        - throws: An `Error` if SQLite encounters an error running the savepoint.
    */
    public func savepoint(name: String, closure: Void throws -> Void) throws {
        let name = name.sq_stringByAddingSQLEscapes()

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

    /**
        Attaches another database with the specified name.

        For more details, please refer to: <https://www.sqlite.org/lang_attach.html>.

        - parameter storageLocation: The storage location of the database to attach.
        - parameter name:            The name of the database being attached.

        - throws: An `Error` if SQLite encounters an error attaching the database.
    */
    public func attachDatabase(storageLocation: StorageLocation, withName name: String) throws {
        let escapedStorageLocation = storageLocation.path.sq_stringByAddingSQLEscapes()
        let escapedName = name.sq_stringByAddingSQLEscapes()

        try execute("ATTACH DATABASE \(escapedStorageLocation) AS \(escapedName)")
    }

    /**
        Detaches a previously attached database connection.

        For more details, please refer to: <https://www.sqlite.org/lang_detach.html>.

        - parameter name: The name of the database connection to detach.

        - throws: An `Error` if SQLite encounters an error detaching the database.
    */
    public func detachDatabase(name: String) throws {
        try execute("DETACH DATABASE \(name.sq_stringByAddingSQLEscapes())")
    }

    // MARK: - Tracing

    /**
        Registers the callback with SQLite to be called each time a statement calls step.

        For more details, please refer to: <https://www.sqlite.org/c3ref/profile.html>.

        - parameter callback: The callback closure called when SQLite internally calls step on a statement.
    */
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

    // MARK: - Collation

    /**
        Registers the custom collation name with SQLite to execute the compare closure when collating.

        For more details, please refer to: <https://www.sqlite.org/datatype3.html#collation>.

        - parameter name:    The name of the custom collation.
        - parameter compare: The closure used to compare the two strings.
    */
    public func createCollation(name: String, compare: (lhs: String, rhs: String) -> NSComparisonResult) {
        let collation: CollationCallback = { lhsBytes, lhsLength, rhsBytes, rhsLength in
            let lhsUTF8 = String(data: NSData(bytes: lhsBytes, length: Int(lhsLength)), encoding: NSUTF8StringEncoding)
            let rhsUTF8 = String(data: NSData(bytes: rhsBytes, length: Int(rhsLength)), encoding: NSUTF8StringEncoding)

            guard let lhs = lhsUTF8, let rhs = rhsUTF8 else { return 0 }

            return Int32(compare(lhs: lhs, rhs: rhs).rawValue)
        }

        let collationPointer = unsafeBitCast(collation, UnsafeMutablePointer<Void>.self)

        sqlite3_create_collation_v2(
            handle,
            name,
            SQLITE_UTF8,
            collationPointer, { (callback, lhsLength, lhsBytes, rhsLength, rhsBytes) -> Int32 in
                unsafeBitCast(callback, CollationCallback.self)(lhsBytes, lhsLength, rhsBytes, rhsLength)
            },
            nil
        )

        collations[name] = collation
    }

    // MARK: - Encryption

    /**
        Sets the encryption passphrase on the database.

        The encryption passphrase MUST be set immediately after the `Connection` is initialized. If it is not called 
        before any other operations are performed on the database, the encryption passphrase is ignored and the
        database will NOT be encrypted.

            let connection = try Connection(storageType: .OnDisk("path_to_db"))
            try connection.setEncryptionPassphrase(passphrase)

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/#key>.

        - parameter passphrase: The passphrase to use for encrypting the database.

        - throws: An `Error` if SQLite or SQLCipher encounter an error setting the passphrase.
    */
    public func setEncryptionPassphrase(passphrase: String) throws {
        try execute("PRAGMA key = \(passphrase.sq_stringByAddingSQLEscapes())")
    }

    /**
        Sets the raw encryption key on the database.

        SQLCipher requires the raw encryption key to be a 64 character hex string. Anything else could result in
        undefined behavior from SQLCipher.

        The raw encryption key MUST be set immediately after the `Connection` is initialized. If it is not called
        before any other operations are performed on the database, the raw encryption key is ignored and the
        database will NOT be encrypted.

            let key = "2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99"
            let connection = try Connection(storageType: .OnDisk("path_to_db"))
            try connection.setRawEncryptionKey(key)

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/#key>.

        - parameter key: The 64 character hex string to use for encrypting the database.

        - throws: An `Error` if SQLite or SQLCipher encounter an error setting the key.
    */
    public func setRawEncryptionKey(key: String) throws {
        try execute("PRAGMA key = \"\(EncryptionKeyBlobCharacter)\(key.sq_stringByAddingSQLEscapes())\"")
    }

    /**
        Updates the encryption passphrase on the database.

        The current encryption passphrase MUST be set on the `Connection` before attempting to update the encryption
        passphrase. Otherwise the update is ignored.

            let connection = try Connection(storageType: .OnDisk("path_to_db"))
            try connection.setEncryptionPassphrase(currentPassphrase)
            try connection.updateEncryptionPassphrase(newPassphrase)

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_profile>.

        - parameter passphrase: The passphrase to use for encrypting the database.

        - throws: An `Error` if SQLite or SQLCipher encounter an error updating the passphrase.
    */
    public func updateEncryptionPassphrase(passphrase: String) throws {
        try execute("PRAGMA rekey = \(passphrase.sq_stringByAddingSQLEscapes())")
    }

    /**
        Updates the raw encryption key on the database.

        SQLCipher requires the raw encryption key to be a 64 character hex string. Anything else could result in
        undefined behavior from SQLCipher.

        The current raw encryption key MUST be set on the `Connection` before attempting to update the derived
        encryption key. Otherwise the update is ignored.

            let connection = try Connection(storageType: .OnDisk("path_to_db"))
            try connection.setRawEncryptionKey(currentKey)
            try connection.updateRawEncryptionKey(newKey)

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_profile>.

        - parameter key: The 64 character hex string to use for encrypting the database.

        - throws: An `Error` if SQLite or SQLCipher encounter an error updating the key.
    */
    public func updateRawEncryptionKey(key: String) throws {
        try execute("PRAGMA rekey = \"\(EncryptionKeyBlobCharacter)\(key.sq_stringByAddingSQLEscapes())\"")
    }

    /**
        Exports the current database to the specified path encrypted with the specified passphrase.

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/index.html#sqlcipher_export>.

        - parameter path:       The path to export the encrypted database to.
        - parameter passphrase: The passphrase to encrypt the exported database with.

        - throws: An `Error` if SQLite or SQLCipher encounter an error when exporting the database.
    */
    public func exportEncryptedDatabaseToPath(path: String, withEncryptionPassphrase passphrase: String) throws {
        let escapedPath = path.sq_stringByAddingSQLEscapes()
        let escapedName = "encrypted".sq_stringByAddingSQLEscapes()
        let escapedPassphrase = passphrase.sq_stringByAddingSQLEscapes()

        try execute("ATTACH DATABASE \(escapedPath) AS \(escapedName) KEY \(escapedPassphrase)")
        try execute("SELECT sqlcipher_export(\(escapedName))")
        try execute("DETACH DATABASE \(escapedName)")
    }

    /**
        Exports the current database to the specified path encrypted with the specified key.

        SQLCipher requires the derived encryption key to be a 64 character hex string. Anything else could result in
        undefined behavior from SQLCipher.

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/index.html#sqlcipher_export>.

        - parameter path: The path to export the encrypted database to.
        - parameter key:  The 64 character hex string to encrypt the exported database with.

        - throws: An `Error` if SQLite or SQLCipher encounter an error when exporting the database.
    */
    public func exportEncryptedDatabaseToPath(path: String, withRawEncryptionKey key: String) throws {
        let escapedPath = path.sq_stringByAddingSQLEscapes()
        let escapedName = "encrypted".sq_stringByAddingSQLEscapes()
        let escapedKey = key.sq_stringByAddingSQLEscapes()

        try execute("ATTACH DATABASE \(escapedPath) AS \(escapedName) KEY \"\(EncryptionKeyBlobCharacter)\(escapedKey)\"")
        try execute("SELECT sqlcipher_export(\(escapedName))")
        try execute("DETACH DATABASE \(escapedName)")
    }

    /**
        Exports a decrypted form of the current database to the specified path.

        If the current database is encrypted with a passphrase, the passphrase must first be set before the database
        can be exported.

        For more details, please refer to: <https://www.zetetic.net/sqlcipher/sqlcipher-api/index.html#sqlcipher_export>.

        - parameter path:       The path to export the decrypted database to.

        - throws: An `Error` if SQLite or SQLCipher encounter an error when exporting the database.
    */
    public func exportDecryptedDatabaseToPath(path: String) throws {
        let escapedPath = path.sq_stringByAddingSQLEscapes()
        let escapedName = "decrypted".sq_stringByAddingSQLEscapes()

        try execute("ATTACH DATABASE \(escapedPath) AS \(escapedName) KEY ''")
        try execute("SELECT sqlcipher_export(\(escapedName))")
        try execute("DETACH DATABASE \(escapedName)")
    }

    // MARK: - Internal - Check Result Code

    func check(code: Int32) throws -> Int32 {
        guard let error = Error(code: code, connection: self) else { return code }
        throw error
    }
}

private let EncryptionKeyBlobCharacter = "x"
