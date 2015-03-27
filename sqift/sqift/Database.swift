//
//  Database.swift
//  Database
//
//  Created by Dave Camp on 3/7/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation
#if os(iOS)
    #if arch(i386) || arch(x86_64)
        import sqlite3_ios_simulator
    #else
        import sqlite3_ios
    #endif
#endif

public enum TransactionResult
{
    case Commit
    case Rollback(DatabaseResult)
}

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
    
    :param: path Path to database file
    
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
    

    /**
    Convert an sqlite result code to a sqifResult
    
    :param: result Result code from sqlite
    
    :returns: Result
    */
    internal func sqResult(result: Int32) -> DatabaseResult
    {
        if result == SQLITE_OK
        {
            return .Success
        }
        else if result == SQLITE_ROW
        {
            return .More
        }
        else if result == SQLITE_DONE
        {
            return .Done
        }
        else
        {
            return .Error(String.fromCString(sqlite3_errmsg(database)) ?? "Unknown error")
        }
    }
    

    /**
    Open a connection to the database
    
    :returns: Result
    */
    public func open(enableTracing: Bool = false) -> DatabaseResult
    {
        var result = DatabaseResult.Success
        if database == nil
        {
            result = sqResult(sqlite3_open(path, &database))
            if enableTracing
            {
                DatabaseTrace.enableTrace(database)
            }
        }
        
        return result
    }
    

    /**
    Close the connection to the database
    
    :returns: Result
    */
    public func close() -> DatabaseResult
    {
        assert(statements.isEmpty == true, "Closing database with active Statements")
        
        var result = DatabaseResult.Success
        if database != nil
        {
            result = sqResult(sqlite3_close(database))
            database = nil
        }
        
        return result
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
    Execute a SQL transaction.
    
    :param: statement SQL statement to execute. No sanitzation is performed.
    
    :returns: Result
    */
    public func executeSQLStatement(statement: String) -> DatabaseResult
    {
        assert(database != nil, "database is not open")

        var result = DatabaseResult.Success
        
        result = sqResult(sqlite3_exec(database, statement, nil, nil, nil))
        
        return result
    }
    
    /**
    Perform a closure within a database transaction.
    Note: You cannot nest transactions. For nestable operations, use named savepoints.
    Note: You cannot start a transaction while within a named savepoint.
    
    :param: transaction Closure to execute inside the database transaction.
    
    :returns: Result
    */
    public func transaction(transaction: (database: Database) -> TransactionResult) -> DatabaseResult
    {
        assert(database != nil, "database is not open")
        assert(inTransaction == false, "Transactions cannot be nested")

        var result = DatabaseResult.Success
        
        result = sqResult(sqlite3_exec(database, "BEGIN TRANSACTION;", nil, nil, nil))
        if result == .Success
        {
            inTransaction = true
            let transactionResult = transaction(database: self)
            
            switch transactionResult
            {
                case .Commit:
                    result = sqResult(sqlite3_exec(database, "COMMIT TRANSACTION;", nil, nil, nil))
                
                case let .Rollback(transactionError):
                    let rollbackResult = sqResult(sqlite3_exec(database, "ROLLBACK TRANSACTION;", nil, nil, nil))
                    if rollbackResult == .Success
                    {
                        result = transactionError
                    }
                    else
                    {
                        result = rollbackResult
                    }
            }
            inTransaction = false
        }
        
        return result
    }
    
    /**
    Execute a closure within a SAVEPOINT.
    Named savepoints can be nested. The results of inner savepoints are not saved unless enclosing
    savepoints are committed.
    
    :param: savepoint   Name of savepoint to use
    :param: transaction Closure to execute within the savepoint
    
    :returns: Result
    */
    public func executeInSavepoint(savepoint: String, transaction: (database: Database) -> TransactionResult) -> DatabaseResult
    {
        assert(database != nil, "database is not open")
        assert(inTransaction == false, "Transactions cannot be nested")

        var result = DatabaseResult.Success

        result = sqResult(sqlite3_exec(database, "SAVEPOINT \(savepoint);", nil, nil, nil))
        if result == .Success
        {
            let transactionResult = transaction(database: self)
            
            switch transactionResult
            {
            case .Commit:
                result = sqResult(sqlite3_exec(database, "RELEASE SAVEPOINT \(savepoint);", nil, nil, nil))
                
            case let .Rollback(transactionError):
                let rollbackResult = sqResult(sqlite3_exec(database, "ROLLBACK TO SAVEPOINT \(savepoint);", nil, nil, nil))
                if rollbackResult == .Success
                {
                    result = transactionError
                }
                else
                {
                    result = rollbackResult
                }
            }
        }
        
        return result
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
}

