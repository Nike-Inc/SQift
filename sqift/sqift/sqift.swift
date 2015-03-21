//
//  sqift.swift
//  sqift
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

/**
*  Main sqift class
*/
public class sqift
{
    public let path: String
    var database: COpaquePointer = nil
    let statements = WeakSet<sqiftStatement>()

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
    Return the version of sqift being used
    
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
    internal func sqResult(result: Int32) -> sqiftResult
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
    public func open() -> sqiftResult
    {
        var result = sqiftResult.Success
        if database == nil
        {
            result = sqResult(sqlite3_open(path, &database))
        }
        
        return result
    }
    

    /**
    Close the connection to the database
    
    :returns: Result
    */
    public func close() -> sqiftResult
    {
        assert(statements.isEmpty == true, "Closing database with active sqiftStatements")
        
        var result = sqiftResult.Success
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
        return String.fromCString(sqlite3_errmsg(database))
    }
    
    
    public func executeSQLStatement(statement: String) -> sqiftResult
    {
        var result = sqiftResult.Success
        
        result = sqResult(sqlite3_exec(database, statement, nil, nil, nil))
        
        return result
    }
    
    public func transaction(transaction: (database: sqift) -> sqiftResult) -> sqiftResult
    {
        var result = sqiftResult.Success
        
        result = sqResult(sqlite3_exec(database, "BEGIN TRANSACTION;", nil, nil, nil))
        if result == .Success
        {
            result = transaction(database: self)
            
            if result != .Error(nil)
            {
                result = sqResult(sqlite3_exec(database, "COMMIT TRANSACTION;", nil, nil, nil))
            }
            else
            {
                result = sqResult(sqlite3_exec(database, "ROLLBACK TRANSACTION;", nil, nil, nil))
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
        let rowID = sqlite3_last_insert_rowid(database)
        return rowID
    }
}

