//
//  Statement.swift
//  sqift
//
//  Created by Dave Camp on 3/8/15.
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

internal let SQLITE_STATIC = unsafeBitCast(COpaquePointer(bitPattern: 0), sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(COpaquePointer(bitPattern: -1), sqlite3_destructor_type.self)

public class Statement : CustomDebugStringConvertible
{
    let database: Database
    let sqlStatement: String
    var preparedStatement: COpaquePointer = nil
    public var parameters: [Any] = [Any]()
    var columnNames: [String]? = nil
    
    // MARK: Initialization
    
    /**
    Initialize a statement with the supplied SQL
    
    :param: database:     Database to query
    :param: sqlStatement: Valid SQL statement.
    
    :returns: Statement object
    */
    public init(database: Database, sqlStatement: String, parameters: Any...)
    {
        self.database = database
        self.sqlStatement = sqlStatement
        self.parameters = parameters

        database.statements.addObject(self)
    }
    
    /**
    Convenience initializer for SELECT with no WHERE clause (i.e. all rows)
    
    :param: database                 Database to query.
    :param: unsafeTable              Table name to query.
    :param: unsafeColumnNames        Columns to return. nil will return all columns.
    :param: unsafeOrderByColumnNames Columns to order by. nil will return unordered.
    :param: ascending                Ascending or descending order. Ignored if unordered.
    :param: limit                    Maximum number of rows to return. 0 = no limit.
    
    :returns: Statement object
    */
    public convenience init(database: Database, table unsafeTable: String, columnNames unsafeColumnNames: [String]? = nil, orderByColumnNames unsafeOrderByColumnNames: [String]? = nil, ascending: Bool = true, limit: Int32 = 0)
    {
        let table = unsafeTable.sqiftSanitize()
        var columns = "*"
        var tempColumnNames: [String]? = nil
        
        if let unsafeColumnNames = unsafeColumnNames
        {
            tempColumnNames = unsafeColumnNames.map( { $0.sqiftSanitize() } )
            columns = ",".join(tempColumnNames!)
        }

        var statement = "SELECT \(columns) from \(table)"
        
        if let unsafeOrderByColumnNames = unsafeOrderByColumnNames
        {
            let orderBy = ",".join(unsafeOrderByColumnNames.map( { $0.sqiftSanitize() } ))
            statement += " ORDER BY \(orderBy)"
            statement += ascending ? " ASC" : " DESC"
        }
        
        if limit != 0
        {
            statement += " LIMIT \(limit)"
        }
        
        statement += ";"
        self.init(database: database, sqlStatement: statement)
        
        self.columnNames = tempColumnNames
        database.statements.addObject(self)
    }

    deinit
    {
        if preparedStatement != nil
        {
            sqlite3_finalize(preparedStatement)
            preparedStatement = nil
        }
    }
    
    public var debugDescription: String { get { return sqlStatement } }
    
    // MARK: Prepare
    
    internal func prepare() throws
    {
        if preparedStatement != nil
        {
            sqlite3_finalize(preparedStatement)
            preparedStatement = nil
        }
        try(database.sqError(sqlite3_prepare_v2(database.database, sqlStatement, -1, &preparedStatement, nil)))
    }
    
    // MARK: Bind
    
    /**
    Reset the prepared SQL statement. Allows you to re-use frequetnly used SQL statements or statements with bindings.
    */
    public func reset() throws
    {
        try(database.sqResult(sqlite3_reset(preparedStatement)))
    }
    
    /**
    Bind the passed parameters to the statement. Use this to pass in values to statements like
        SELECT * FROM myTable WHERE someColumn = ?
    
    :param: parameters: List of values to bind. Valid types are String, Int, Double, Bool, Int32, Int64.
    */
    public func bindParameters(parameters: Any...) throws
    {
        self.parameters = parameters
        try(bind())
    }
    
    internal func bind() throws
    {
        // Prepare or reset as needed
        preparedStatement == nil ? try(prepare()) : try(reset())
        
        let statementParameterCount = Int(sqlite3_bind_parameter_count(preparedStatement))
        if statementParameterCount != parameters.count
        {
            throw DatabaseError.InternalError(string: "Mismatched statement parameter count")
        }
        else if statementParameterCount != 0
        {
            // Iterate the statement parameters and call the correct bind method for the type
            var boundCount = 0
            for (index, value) in parameters.enumerate()
            {
                let bindIndex = Int32(index + 1)
                if let string = value as? String
                {
                    try(database.sqError(sqlite3_bind_text(preparedStatement, bindIndex, string, -1, SQLITE_TRANSIENT)))
                    boundCount++
                }
                else if let value = value as? Double
                {
                    try(database.sqError(sqlite3_bind_double(preparedStatement, bindIndex, value)))
                    boundCount++
                }
                else if let value = value as? Int32
                {
                    try(database.sqError(sqlite3_bind_int(preparedStatement, bindIndex, value)))
                    boundCount++
                }
                else if let value = value as? Int64
                {
                    try(database.sqError(sqlite3_bind_int64(preparedStatement, bindIndex, value)))
                    boundCount++
                }
                else if let value = value as? Bool
                {
                    try(database.sqError(sqlite3_bind_int(preparedStatement, bindIndex, value ? 1 : 0)))
                    boundCount++
                }
                else if let value = value as? Int
                {
                    try(database.sqError(sqlite3_bind_int64(preparedStatement, bindIndex, Int64(value))))
                    boundCount++
                }
                else
                {
                    assert(false, "Unsupported parameter type")
                }
            }

            assert(boundCount == statementParameterCount, "Failed to bind enough parameters");
        }
    }
    
    /**
    Step to next row.
    
    :returns: Result. .More = there are more rows to process, .Done = No more rows to process
    */
    public func step() throws -> DatabaseResult
    {
        var result = DatabaseResult.Done
        
        if preparedStatement == nil
        {
            try(prepare())
            try(bind())
        }
        
        // Step
        result = try(database.sqResult(sqlite3_step(preparedStatement)))
        
        return result
    }
    
    // MARK: Result Columns
    
    /**
    Number of columns in the result set
    
    :returns: Column count, may be zero for no results.
    */
    public func columnCount() -> Int
    {
        let count = Int(sqlite3_column_count(preparedStatement))
        return count
    }
    
    /**
    Contents of the column at the specified index as a String
    
    :param: index: Column number.
    
    :returns: Result as a String, may be nil if NULL data or conversion to a String fails.
    */
    public subscript(index: Int) -> String?
    {
        let value = String.fromCString(UnsafePointer(sqlite3_column_text(preparedStatement, Int32(index))))
        return value
    }
    
    /**
    Contents of the column at the specified index as a Double
    
    :param: index: Column number.
    
    :returns: Value as a Double
    */
    public subscript(index: Int) -> Double
    {
        let value = sqlite3_column_double(preparedStatement, Int32(index))
        return value
    }
    
    /**
    Contents of the column at the specified index as an Int
    
    :param: index: Column number.
    
    :returns: Value as an Int
    */
    public subscript(index: Int) -> Int
        {
            let value = Int(sqlite3_column_int(preparedStatement, Int32(index)))
            return value
    }
    
    /**
    Contents of the column at the specified index as an Int32
    
    :param: index: Column number.
    
    :returns: Value as an Int32
    */
    public subscript(index: Int) -> Int32
    {
        let value = sqlite3_column_int(preparedStatement, Int32(index))
        return value
    }
    
    /**
    Contents of the column at the specified index as an Int64
    
    :param: index: Column number.
    
    :returns: Value as an Int64
    */
    public subscript(index: Int) -> Int64
    {
        let value = sqlite3_column_int64(preparedStatement, Int32(index))
        return value
    }

    /**
    Contents of the column at the specified index as a Bool
    
    :param: index: Column number.
    
    :returns: Value as a Bool. Any value that is non-zero will return true.
    */
    public subscript(index: Int) -> Bool
    {
        let value = sqlite3_column_int(preparedStatement, Int32(index)) == 0 ? false : true
        return value
    }
    
    /**
    Cache the column names for this statement if not already cached
    */
    internal func cacheColumnNames() throws
    {
        guard columnNames == nil else { return }
        let count = columnCount()
        guard count != 0 else { return }

        var names = [String]()
        for index in 0 ..< count
        {
            guard let name = String.fromCString(UnsafePointer(sqlite3_column_name(preparedStatement, Int32(index)))) else {
                // Something is wrong...
                throw DatabaseError.InternalError(string: "Unable to load column names")
            }
            
            // Cache the name
            names.append(name)
        }

        // Save the names if the counts match
        if names.count == count
        {
            columnNames = names
        }
    }
    
    /**
    Name of the column at the specified index
    
    :param: index: Column number.
    
    :returns: Name of the column, or nil.
    */
    public func columnNameForIndex(index: Int) throws -> String?
    {
        try(cacheColumnNames())

        guard let columnNames = columnNames where index < columnNames.count else { return nil }
        
        let name = columnNames[index]

        return name
    }
    
    /**
    Type of the column at the specified index
    
    :param: index: Column number.
    
    :returns: Type of the column.
    */
    public func columnTypeForIndex(index: Int) -> ColumnType
    {
        let value = sqlite3_column_type(preparedStatement, Int32(index))
        let type = ColumnType.fromColumnType(value)
        return type
    }
}
