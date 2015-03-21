//
//  sqiftHelpers.swift
//  sqift
//
//  Created by Dave Camp on 3/19/15.
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

public extension sqift
{
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
    
    public func insertRowIntoTable(table unsafeTableName: String, columns unsafeColumns: [String]? = nil, values: [Any]) -> sqiftResult
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        assert(values.count != 0, "values array is empty")
       
        let table = unsafeTableName.sqiftSanitize()
        var string = "INSERT INTO \(table)"
        
        if let unsafeColumns = unsafeColumns
        {
            let columns = ",".join(unsafeColumns.map( { $0.sqiftSanitize() } ))
            string += "(\(columns))"
        }
        
        let parameters = ",".join(values.map( { _ in "?" } ))
        
        string += " VALUES(\(parameters));"
        
        let statement = sqiftStatement(database: self, sqlStatement: string)
        statement.parameters = values
        
        result = statement.step()
        
        if result == .Done
        {
            result = .Success
        }
        
        return result
    }
    
    public func deleteFromTable(table unsafeTableName: String, whereExpression: String, values: [Any]) -> sqiftResult
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        assert(values.count != 0, "values array is empty")
        
        let table = unsafeTableName.sqiftSanitize()
        var string = "DELETE FROM \(table)"
        
        string += " WHERE \(whereExpression);"
        
        let statement = sqiftStatement(database: self, sqlStatement: string)
        statement.parameters = values
        
        result = statement.step()
        
        if result == .Done
        {
            result = .Success
        }
        
        return result
    }
    
    public func deleteAllRowsFromTable(table unsafeTableName: String) -> sqiftResult
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        
        let table = unsafeTableName.sqiftSanitize()
        var string = "DELETE FROM \(table)"
        
        let statement = sqiftStatement(database: self, sqlStatement: string)
        
        result = statement.step()
        
        if result == .Done
        {
            result = .Success
        }
        
        return result
    }
    
    public func numberOfRowsInTable(table unsafeTableName: String) -> Int64?
    {
        var result = sqiftResult.Success
        assert(database != nil, "database is nil")
        
        let table = unsafeTableName.sqiftSanitize()
        let statement = sqiftStatement(database: self, sqlStatement: "SELECT count(*) FROM \(table);")
        result = statement.step()
        
        var count: Int64? = nil
        if result == .More
        {
            count = statement[0] as Int64
        }
        
        return count
    }
}