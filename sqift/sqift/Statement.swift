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

internal let SQLITE_STATIC = sqlite3_destructor_type(COpaquePointer(bitPattern: 0))
internal let SQLITE_TRANSIENT = sqlite3_destructor_type(COpaquePointer(bitPattern: -1))

public class Statement
{
    let database: Database
    let sqlStatement: String
    var preparedStatement: COpaquePointer = nil
    public var parameters: [Any] = [Any]()
    var columnNames: [String]? = nil
    
    // MARK: Initialization
    
    /**
    Initialize a statement with the supplied SQL
    
    :param: database     Database to query
    :param: sqlStatement Valid SQL statement.
    
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
    
    :param: database                 Database to query
    :param: unsafeTable              Table name to query
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
            columns = join(",", tempColumnNames!)
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
    
    // MARK: Prepare
    
    func prepare() -> DatabaseResult
    {
        if preparedStatement != nil
        {
            sqlite3_finalize(preparedStatement)
            preparedStatement = nil
        }
        let result = database.sqResult(sqlite3_prepare_v2(database.database, sqlStatement, -1, &preparedStatement, nil))
        return result;
    }
    
    // MARK: Bind
    
    /**
    Reset the prepared SQL statement. Allows you to re-use frequetnly used SQL statements or statements with bindings.
    
    :returns: Result
    */
    public func reset() -> DatabaseResult
    {
        let result = database.sqResult(sqlite3_reset(preparedStatement))
        return result
    }
    
    /**
    Bind the passed parameters to the statement. Use this to pass in values to statements like
        SELECT * FROM myTable WHERE someColumn = ?
    
    :param: parameters List of values to bind. Valid types are String, Int, Double, Bool, Int32, Int64.
    
    :returns: Result
    */
    public func bindParameters(parameters: Any...) -> DatabaseResult
    {
        self.parameters = parameters
        let result = bind()
        return result
    }
    
    func bind() -> DatabaseResult
    {
        var result = DatabaseResult.Success
        
        // Prepare or reset as needed
        result = preparedStatement == nil ? prepare() : reset()
        
        if result == .Success
        {
            let statementParameterCount = Int(sqlite3_bind_parameter_count(preparedStatement))
            if statementParameterCount != parameters.count
            {
                result = .Error("Mismatched statement parameter count")
            }
            else if statementParameterCount != 0
            {
                for (index, value) in enumerate(parameters)
                {
                    let bindIndex = Int32(index + 1)
                    if let string = value as? String
                    {
                        result = database.sqResult(sqlite3_bind_text(preparedStatement, bindIndex, string, -1, SQLITE_TRANSIENT))
                    }
                    else if let value = value as? Double
                    {
                        result = database.sqResult(sqlite3_bind_double(preparedStatement, bindIndex, value))
                    }
                    else if let value = value as? Int32
                    {
                        result = database.sqResult(sqlite3_bind_int(preparedStatement, bindIndex, value))
                    }
                    else if let value = value as? Int64
                    {
                        result = database.sqResult(sqlite3_bind_int64(preparedStatement, bindIndex, value))
                    }
                    else if let value = value as? Bool
                    {
                        result = database.sqResult(sqlite3_bind_int(preparedStatement, bindIndex, value ? 1 : 0))
                    }
                    else if let value = value as? Int
                    {
                        result = database.sqResult(sqlite3_bind_int64(preparedStatement, bindIndex, Int64(value)))
                    }
                }
            }
        }
        
        return result
    }
    
    /**
    Step to next row.
    
    :returns: Result. .More = there are more rows to process, .Done = No more rows to process
    */
    public func step() -> DatabaseResult
    {
        var result = DatabaseResult.Success
        
        if preparedStatement == nil
        {
            result = prepare()
            
            if result == .Success
            {
                result = bind()
            }
        }
        
        // Step
        if result == .Success
        {
            result = database.sqResult(sqlite3_step(preparedStatement))
        }

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
    
    :param: index Column number.
    
    :returns: Result as a String, may be nil if NULL data or conversion to a String fails.
    */
    public subscript(index: Int) -> String?
    {
        let value = String.fromCString(UnsafePointer(sqlite3_column_text(preparedStatement, Int32(index))))
        return value
    }
    
    /**
    Contents of the column at the specified index as a Double
    
    :param: index Column number.
    
    :returns: Value as a Double
    */
    public subscript(index: Int) -> Double
    {
        let value = sqlite3_column_double(preparedStatement, Int32(index))
        return value
    }
    
    /**
    Contents of the column at the specified index as an Int
    
    :param: index Column number.
    
    :returns: Value as an Int
    */
    public subscript(index: Int) -> Int
        {
            let value = Int(sqlite3_column_int(preparedStatement, Int32(index)))
            return value
    }
    
    /**
    Contents of the column at the specified index as an Int32
    
    :param: index Column number.
    
    :returns: Value as an Int32
    */
    public subscript(index: Int) -> Int32
    {
        let value = sqlite3_column_int(preparedStatement, Int32(index))
        return value
    }
    
    /**
    Contents of the column at the specified index as an Int64
    
    :param: index Column number.
    
    :returns: Value as an Int64
    */
    public subscript(index: Int) -> Int64
    {
        let value = sqlite3_column_int64(preparedStatement, Int32(index))
        return value
    }

    /**
    Contents of the column at the specified index as a Bool
    
    :param: index Column number.
    
    :returns: Value as a Bool. Any value that is non-zero will return true.
    */
    public subscript(index: Int) -> Bool
    {
        let value = sqlite3_column_int(preparedStatement, Int32(index)) == 0 ? false : true
        return value
    }
    
    /**
    Cache the column names for this statement if not already cached
    
    :returns: Result
    */
    func cacheColumnNames() -> DatabaseResult
    {
        var result = DatabaseResult.Success
        
        if columnNames == nil
        {
            var names = [String]()
            let count = columnCount()
            
            if count != 0
            {
                for index in 0 ..< count
                {
                    if let name = String.fromCString(UnsafePointer(sqlite3_column_name(preparedStatement, Int32(index))))
                    {
                        names.append(name)
                    }
                    else
                    {
                        // Something is wrong...
                        result = .Error("Unable to load column names")
                        break
                    }
                }

                // Save the names if the counts match
                if names.count == count
                {
                    columnNames = names
                }
            }
        }
        
        return result
    }
    
    /**
    Name of the column at the specified index
    
    :param: index Column number.
    
    :returns: Name of the column, or nil.
    */
    public func columnNameForIndex(index: Int) -> String?
    {
        var name: String? = nil
        
        if cacheColumnNames() == .Success
        {
            if let columnNames = columnNames where index < columnNames.count
            {
                name = columnNames[index]
            }
        }
        
        return name
    }
    
    /**
    Type of the column at the specified index
    
    :param: index Column number.
    
    :returns: Type of the column.
    */
    public func columnTypeForIndex(index: Int) -> ColumnType
    {
        let value = sqlite3_column_type(preparedStatement, Int32(index))
        let type = ColumnType.fromColumnType(value)
        return type
    }
}
