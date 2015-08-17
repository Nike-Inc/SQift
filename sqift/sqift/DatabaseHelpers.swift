//
//  sqiftHelpers.swift
//  sqift
//
//  Created by Dave Camp on 3/19/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

/**
The ON CONFLICT clause applies to UNIQUE, NOT NULL, CHECK, and PRIMARY KEY constraints
https://www.sqlite.org/lang_conflict.html

- Rollback: Rollback the current transaction or abort if not in a transaction
- Abort:    Abort changes from this SQL statement. Default.
- Replace:  Replace conflicting rows.
- Fail:     Abort conflicting change. but not other changes in this SQL statement
- Ignore:   Skip conflicting rows and keep going.
*/
public enum OnConflict : String
{
    case Rollback
    case Abort
    case Replace
    case Fail
    case Ignore
    
    internal func sql() -> String {
        switch self {
        case .Rollback:
            return " OR ROLLBACK "
        case .Abort:
            return " OR ABORT "
        case .Replace:
            return " OR REPLACE "
        case .Fail:
            return " OR FAIL "
        case .Ignore:
            return " OR IGNORE "
        }
    }
}

public extension Database
{
    /**
    Create a new table from the array of column definitions
    
    :param: name:    Name of the table to create
    :param: columns: Array of column definitions
    */
    public func createTable(name: String, columns: [Column]) throws
    {
        assert(database != nil, "database is nil")
        
        var createString = "CREATE TABLE IF NOT EXISTS \(name.sqiftSanitize())"
        var columnStrings = [String]()
        
        for column in columns
        {
            columnStrings.append(column.createString())
        }
        
        createString += " (" + ",".join(columnStrings) + ");"
        
        try(sqError(sqlite3_exec(database, createString, nil, nil, nil)))
    }
    
    /**
    Drop a table
    
    :param: name: Name of table to drop
    */
    public func dropTable(name: String) throws
    {
        assert(database != nil, "database is nil")
        
        let dropString = "DROP TABLE IF EXISTS \(name.sqiftSanitize());"
        try(sqError(sqlite3_exec(database, dropString, nil, nil, nil)))
    }
    
    /**
    Determine if a table with the given name exists
    
    :param: name: Name of table
    
    :returns: true if table exists
    */
    public func tableExists(name: String) -> Bool
    {
        var exists = false
        assert(database != nil, "database is nil")
        
        do {
            let string = "SELECT name FROM sqlite_master WHERE type='table' AND name=\(name.sqiftSanitize());"
            var preparedStatement: COpaquePointer = nil
            
            // Prepare the statement
            try(sqError(sqlite3_prepare_v2(database, string, -1, &preparedStatement, nil)))
            defer {
                // Release the prepared statement
                if preparedStatement != nil
                {
                    sqlite3_finalize(preparedStatement)
                    preparedStatement = nil
                }
            }
            
            // Step
            try(sqResult(sqlite3_step(preparedStatement)))
            
            // Get the data
            let foundName = String.fromCString(UnsafePointer(sqlite3_column_text(preparedStatement, 0))) ?? ""
            if foundName == name
            {
                exists = true
            }
        }
        catch {
            
        }
        
        return exists
    }
    
    /**
    Insert a row into a table
    
    :param: unsafeTableName: Table name
    :param: unsafeColumns:   Optional list of column names. If nil, value array must match the column order
    :param: values:          Values to insert into the table. Must be in same order an the column list.
    :param: onConflict:      How to resolve conflicts
    */
    public func insertRowIntoTable(unsafeTableName: String, columns unsafeColumns: [String]? = nil, values: [Any], onConflict: OnConflict = .Abort) throws
    {
        assert(database != nil, "database is nil")
        assert(values.count != 0, "values array is empty")
       
        let table = unsafeTableName.sqiftSanitize()
        var string = "INSERT \(onConflict.sql()) INTO \(table)"
        
        if let unsafeColumns = unsafeColumns
        {
            let columns = ",".join(unsafeColumns.map( { $0.sqiftSanitize() } ))
            string += "(\(columns))"
        }
        
        let parameters = ",".join(values.map( { _ in "?" } ))
        
        string += " VALUES(\(parameters));"
        
        let statement = Statement(database: self, sqlStatement: string)
        statement.parameters = values
        
        try(statement.step())
    }
    
    /**
    Delete matching rows from a table
    
    :param: unsafeTableName: Table name
    :param: whereExpression: Expression to match rows. Use ? for expression parameters
    :param: values:          Values to bind to expression parameters
    */
    public func deleteFromTable(unsafeTableName: String, whereExpression: String, values: [Any]) throws
    {
        assert(database != nil, "database is nil")
        assert(values.count != 0, "values array is empty")
        
        let table = unsafeTableName.sqiftSanitize()
        var string = "DELETE FROM \(table)"
        
        string += " WHERE \(whereExpression);"
        
        let statement = Statement(database: self, sqlStatement: string)
        statement.parameters = values
        
        try(statement.step())
    }
    
    /**
    Delete all rows from a table
    
    :param: unsafeTableName: Table name
    */
    public func deleteAllRowsFromTable(unsafeTableName: String) throws
    {
        assert(database != nil, "database is nil")
        
        let table = unsafeTableName.sqiftSanitize()
        let string = "DELETE FROM \(table)"
        
        let statement = Statement(database: self, sqlStatement: string)
        
        try(statement.step())
    }
    
    /**
    Return the number of rows in a table
    
    :param: unsafeTableName: Table name
    
    :returns: Number of rows, or nil if there was an error.
    */
    public func numberOfRowsInTable(unsafeTableName: String) throws -> Int64?
    {
        assert(database != nil, "database is nil")
        
        let table = unsafeTableName.sqiftSanitize()
        let statement = Statement(database: self, sqlStatement: "SELECT count(*) FROM \(table);")
        let result = try(statement.step())
        
        var count: Int64? = nil
        if result == .More
        {
            count = statement[0] as Int64
        }
        
        return count
    }
    
    /**
    Update rows in a table. Rows matching the where expression will have columns listed in
    the values dictionary set to their correstponding values.
    
    :param: unsafeTableName: Table name
    :param: values:          Dictonary of column names and values
    :param: onConflict:      How to resolve conflicts
    :param: whereExpression: Expression to match rows. Use ? for expression parameters
    :param: values:          Values to bind to expression parameters
    */
    public func updateTable(unsafeTableName: String,  values: [String : Any], onConflict: OnConflict = .Abort, whereExpression: String? = nil, parameters: Any...) throws
    {
        assert(database != nil, "database is nil")
        assert(values.count != 0, "values array is empty")
        
        let table = unsafeTableName.sqiftSanitize()
        var string = "UPDATE \(onConflict.sql()) \(table) SET "
        
        var pairs = [String]()
        for (columnName, value) in values
        {
            switch value
            {
            case is Int, is Int32, is Int64, is Double:
                pairs.append("\(columnName.sqiftSanitize()) = \(value)")

            case is Bool:
                let boolValue = value as! Bool == true ? 1 : 0
                pairs.append("\(columnName.sqiftSanitize()) = \(boolValue)")
            
            case is String:
                let string = (value as! String).sqiftSanitize()
                pairs.append("\(columnName.sqiftSanitize()) = \(string)")
            
            default:
                ()
            }
        }
        
        string += ",".join(pairs)
        
        if let whereExpression = whereExpression
        {
            string += " WHERE \(whereExpression)"
        }
        string += ";"
        
        let statement = Statement(database: self, sqlStatement: string)
        statement.parameters = parameters
        
        try(statement.step())
    }
    
    /**
    Create a named index for a table

    :param: name:    Name of index to create. Name must be unique withiin the database.
    :param: table:   Table to create index on
    :param: columns: Columns to index

    :returns: Result
    */
    public func createIndex(name: String, table: String,  columns: [String]) throws
    {
        assert(database != nil, "database is nil")
        assert(columns.count != 0, "values array is empty")
        
        let safeName = name.sqiftSanitize()
        let safeTable = table.sqiftSanitize()
        let safeColumns = ",".join(columns.sanitize())
        try(executeSQLStatement("CREATE INDEX IF NOT EXISTS \(safeName) ON \(safeTable) (\(safeColumns));"))
    }
    
    /**
    Drop a named index
    
    :param: name: Name of index to drop
    */
    public func dropIndex(name: String) throws
    {
        assert(database != nil, "database is nil")
        
        let safeName = name.sqiftSanitize()
        try(executeSQLStatement("DROP INDEX IF EXISTS \(safeName);"))
    }
}