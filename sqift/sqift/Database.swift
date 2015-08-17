//
//  Database.swift
//  Database
//
//  Created by Dave Camp on 3/7/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

// Closure that is executed while within a SQL transaction or named savepoint.
// Throwing an error is an automatic .Rollback
public typealias TransactionClosure = ((database: Database) throws -> (TransactionResult))

/**
TransactionClosure result type.

- Commit:   Work performed by the closure should be committed.
- Rollback: Work performed by the closure should be rolled back.
*/
public enum TransactionResult
{
    case Commit
    case Rollback
}

//public enum TableChange
//{
//    case Insert
//    case Update
//    case Delete
//    
//    func sql() -> String
//    {
//        switch self
//        {
//        case .Insert:
//            return "INSERT"
//        case .Update:
//            return "UPDATE"
//        case .Delete:
//            return "DELETE"
//        }
//    }
//}

/**
*  Main Database class
*/
public class Database
{
    public let path: String
    public var isOpen: Bool { get { return database != nil } }

    var database: COpaquePointer = nil
    let statements = WeakSet<Statement>()
    var inTransaction = false

    /**
    Init
    
    :param: path: Path to database file
    
    :returns: Object
    */
    public init(_ path: String)
    {
        self.path = path
    }
    
    /**
    Return the version of Database being used
    
    :returns: Version string
    */
    public func sqiftVersion() -> String
    {
        return "1.0.0"
    }
    

    /**
    Return the version of sqlite being used
    
    :returns: Version string
    */
    public func sqlite3Version() -> String
    {
        return String.fromCString(sqlite3_libversion())!
    }
    
    internal func sqResult(result: Int32) throws -> DatabaseResult
    {
        if result == SQLITE_ROW
        {
            return .More
        }
        else if result == SQLITE_DONE || result == SQLITE_OK
        {
            return .Done
        }
        else
        {
            let string = String.fromCString(sqlite3_errmsg(database)) ?? "Unknown error"
            print("Error: \(string)")
            throw DatabaseError.sqliteError(string: string, code: result)
        }
    }
    
    internal func sqError(result: Int32) throws
    {
        if result != SQLITE_OK
        {
            let string = String.fromCString(sqlite3_errmsg(database)) ?? "Unknown error"
            print("Error: \(string)")
            throw DatabaseError.sqliteError(string: string, code: result)
        }
    }
    

    /**
    Open a connection to the database
    */
    public func open() throws
    {
        try(sqError(sqlite3_open(path, &database)))
    }
    

    /**
    Close the connection to the database
    */
    public func close() throws
    {
        if statements.isEmpty == false {
            statements.dump()
        }
        assert(statements.isEmpty == true, "Closing database with active Statements")
        
        defer { database = nil }
        try(sqError(sqlite3_close(database)))
    }
    
    /**
    Enabled database tracing. Useful for tracking down odd problems.
    
    :param: tracing true to enable tracing
    */
    public func enableTracing(tracing: Bool)
    {
        DatabaseTrace.enableTrace(tracing, database: database)
    }
    

    /**
    Return the last error message from sqlite
    
    :returns: Last error message
    */
    public func lastErrorMessage() -> String?
    {
        assert(database != nil, "database is not open")
        return String.fromCString(sqlite3_errmsg(database))
    }
    
    
    /**
    Execute an SQL statement. This is the most basic level of database access.
    Using a Statement object is the preferred method of executing SQL statements.
    
    :param: statement: SQL statement to execute. No sanitzation is performed.
    
    :returns: Result. Only useful for the results of a STEP or other statement that uses the more/done
                pattern. Throws for any other result.
    */
    public func executeSQLStatement(statement: String) throws -> DatabaseResult
    {
        assert(database != nil, "database is not open")

        let result = try(sqResult(sqlite3_exec(database, statement, nil, nil, nil)))
        
        return result
    }
    
    /**
    Perform a closure within a database transaction.
    Note: You cannot nest transactions. For nestable operations, use named savepoints.
    Note: You cannot start a transaction while within a named savepoint.
    
    :param: transaction: Closure to execute inside the database transaction.
    */
    public func transaction(transaction: TransactionClosure) throws
    {
        assert(database != nil, "database is not open")
        assert(inTransaction == false, "Transactions cannot be nested")

        try(sqError(sqlite3_exec(database, "BEGIN TRANSACTION;", nil, nil, nil)))
        inTransaction = true
        defer { inTransaction = false }
        
        do {
            let result =  try(transaction(database: self))
            
            switch result
            {
            case .Commit:
                try(sqError(sqlite3_exec(database, "COMMIT TRANSACTION;", nil, nil, nil)))
                
            case .Rollback:
                try(sqError(sqlite3_exec(database, "ROLLBACK TRANSACTION;", nil, nil, nil)))
            }
        } catch {
            try(sqError(sqlite3_exec(database, "ROLLBACK TRANSACTION;", nil, nil, nil)))
        }
    }
    
    /**
    Execute a closure within a SAVEPOINT.
    Named savepoints can be nested. The results of inner savepoints are not saved unless enclosing
    savepoints are committed.
    
    :param: savepoint:   Name of savepoint to use
    :param: transaction: Closure to execute within the savepoint
    */
    public func executeInSavepoint(savepoint: String, transaction: TransactionClosure) throws
    {
        assert(database != nil, "database is not open")
        assert(inTransaction == false, "Transactions cannot be nested")

        try(sqError(sqlite3_exec(database, "SAVEPOINT \(savepoint);", nil, nil, nil)))
        do {
            let transactionResult = try(transaction(database: self))
            
            switch transactionResult
            {
            case .Commit:
                try(sqError(sqlite3_exec(database, "RELEASE SAVEPOINT \(savepoint);", nil, nil, nil)))
                
            case .Rollback:
                try(sqError(sqlite3_exec(database, "ROLLBACK TO SAVEPOINT \(savepoint);", nil, nil, nil)))
            }
        } catch {
            try(sqError(sqlite3_exec(database, "ROLLBACK TO SAVEPOINT \(savepoint);", nil, nil, nil)))
        }
    }
    
    /**
    Row ID of the last successful INSERT
    
    :returns: Row ID
    */
    public func lastRowInserted() -> Int64
    {
        assert(database != nil, "database is not open")

        let rowID = sqlite3_last_insert_rowid(database)
        return rowID
    }
    
//    public func whenTable(table: String, changes: TableChange, perform: (closureName: String, closure:(change: TableChange, rowid: Int64) -> ())) -> DatabaseResult
//    {
//        assert(database != nil, "database is not open")
//        
//        var result = DatabaseResult.Success
//        
//        // Add the block
//        let safeName = perform.closureName + "_sqift"
//        result = sqResult(DatabaseTrace.addBlock( { rowid in perform.closure(change: changes, rowid: rowid) }, withName: safeName, toDatabase: database))
//
//        if result == .Success
//        {
//            // Create the sql trigger
//            let safeTable = table.sqiftSanitize()
//            let rowString = changes == .Delete ? "old.rowid" : "new.rowid"
//            let statement = "CREATE TRIGGER IF NOT EXISTS \(safeName) AFTER \(changes.sql()) ON \(safeTable) BEGIN SELECT sqliteFunction(\"\(safeName)\", \(rowString)); END;"
//            result = executeSQLStatement(statement)
//        }
//
//        return result
//    }
//    
//    public func removeClosureWithName(name: String) -> DatabaseResult
//    {
//        assert(database != nil, "database is not open")
//        
//        var result = DatabaseResult.Success
//        
//        let safeName = name + "_sqift"
//        result = executeSQLStatement("DROP TRIGGER IF EXISTS \(safeName);")
//
//        // Only remove the function if the drop succeeded, otherwise there will be a trigger with no matching function
//        if result == .Success
//        {
//            DatabaseTrace.removeBlockForName(name, inDatabase: database)
//        }
//        
//        return result
//    }
}

