//
//  DatabaseConvertable.swift
//  sqift
//
//  Created by Dave Camp on 3/21/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

public protocol DatabaseConvertable
{
    /// Table name of this class
    static var tableName: String { get }
    
    /// Column definitions for this class
    static var columnDefinitions: [Column] { get }
    
    /// Object properites turned into an array of values corresponding in table column order
    var columnValues: [Any] { get }
    
    /**
    Return an object based on the current columns of a statement
    
    :param: statement Current statement
    
    :returns: Object, or nil
    */
    static func objectFromStatement(statement: Statement) -> DatabaseConvertable?
}

public extension Database
{
    /**
    Create a table based on an encodable class
    
    :param: encodable Class to use as a template
    
    :returns: Result
    */
    public func createTable<T: DatabaseConvertable>(encodable: T.Type) -> DatabaseResult
    {
        return createTable(T.tableName, columns: T.columnDefinitions)
    }
    
    /**
    Insert a row with an encodable object
    
    :param: encodable Class to encode
    :param: instance  Instance of object to encode
    
    :returns: Result
    */
    public func insertRowIntoTable<T: DatabaseConvertable>(encodable: T.Type, _ instance: T) -> DatabaseResult
    {
        return insertRowIntoTable(encodable.tableName, values: instance.columnValues)
    }
    
    /**
    Determine if a table for the given class exists
    
    :param: encodable Class to use as a template
    
    :returns: Result
    */
    public func tableExists<T: DatabaseConvertable>(encodable: T.Type) -> Bool
    {
        return tableExists(T.tableName)
    }
    
    /**
    Return the number of rows in a table
    
    :param: encodable Class to use as a template
    
    :returns: Result
    */
    public func numberOfRowsInTable<T: DatabaseConvertable>(encodable: T.Type) -> Int64?
    {
        return numberOfRowsInTable(T.tableName)
    }
    
}

public extension Statement
{
    /**
    SELECT * FROM <objectClass.tableName> WHERE <whereExpression>
    
    :param: database        Database
    :param: objectClass     Class whose table to select from
    :param: whereExpression WHere expression. Use ? to bind parameters.
    :param: parameters      Parameters to bind
    
    :returns: Statement object
    */
    public convenience init<T: DatabaseConvertable>(database: Database, objectClass: T.Type, whereExpression: String, parameters: Any...)
    {
        let tableName = T.tableName.sqiftSanitize()
        let string = "SELECT * FROM \(tableName) WHERE \(whereExpression);"
        self.init(database: database, sqlStatement: string)
        self.parameters = parameters
    }
    
    /**
    Create an object for the current row
    
    :param: objectClass Class to create from the current row
    
    :returns: Object created or nil
    */
    public func objectForRow<T: DatabaseConvertable>(objectClass: T.Type) -> T?
    {
        return objectClass.objectFromStatement(self) as? T
    }
    
    /**
    Create an array of objects for all rows
    
    :param: objectClass Object class to return
    
    :returns: Array of objects
    */
    public func objectsForRows<T: DatabaseConvertable>(objectClass: T.Type) -> [T]
    {
        var objects = [T]()
        while step() == .More
        {
            if let object = objectForRow(T)
            {
                objects.append(object)
            }
        }
        return objects
    }
    
    public func validateColumnsForObject<T: DatabaseConvertable>(objectClass: T.Type) -> Bool
    {
        var result = false
        let columnDefinitions = T.columnDefinitions
        
        // Column count must match
        result = columnDefinitions.count == columnCount()
        
        // Column types must match
        if result == true
        {
            for (index, column) in enumerate(columnDefinitions)
            {
                if column.type != columnTypeForIndex(index)
                {
                    result = false
                    break
                }
            }
        }
        
        
        return result
    }
}