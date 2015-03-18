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
    
    
    /**
    Create a new table from the array of column definitions
    
    :param: name    Name of the table to create
    :param: columns Array of column definitions
    
    :returns: Result
    */
    public func createTable(name: String, columns: [sqiftColumn]) -> sqiftResult
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        
        var createString = "CREATE TABLE IF NOT EXISTS \(name.sqiftSanitize())"
        var columnStrings = [String]()
        
        for column in columns
        {
            columnStrings.append(column.createString())
        }
        
        createString += " (" + ",".join(columnStrings) + ");"
        
        result = sqResult(sqlite3_exec(database, createString, nil, nil, nil))
        
        return result
    }
    
    /**
    Drop a table
    
    :param: name Name of table to drop
    
    :returns: Result
    */
    public func dropTable(name: String) -> sqiftResult
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        
        var dropString = "DROP TABLE IF EXISTS \(name.sqiftSanitize());"
        result = sqResult(sqlite3_exec(database, dropString, nil, nil, nil))
        
        return result
    }
    
    /**
    Determine if a table with the given name exists
    
    :param: name Name of table
    
    :returns: true if table exists
    */
    public func tableExists(name: String) -> Bool
    {
        var exists = false
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        
        let string = "SELECT name FROM sqlite_master WHERE type='table' AND name=\(name.sqiftSanitize());"
        var preparedStatement: COpaquePointer = nil
        
        // Prepare the statement
        result = sqResult(sqlite3_prepare_v2(database, string, -1, &preparedStatement, nil))
        
        // Step
        if result == .Success
        {
            result = sqResult(sqlite3_step(preparedStatement))
        }
        
        // Get the data
        if result != .Error(nil)
        {
            let foundName = String.fromCString(UnsafePointer(sqlite3_column_text(preparedStatement, 0))) ?? ""
            if foundName == name
            {
                exists = true
            }
        }
        
        // Release the prepared statement
        if preparedStatement != nil
        {
            result = sqResult(sqlite3_finalize(preparedStatement))
            preparedStatement = nil
        }
        
        return exists
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
}

