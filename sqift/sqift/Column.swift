//
//  Column.swift
//  sqift
//
//  Created by Dave Camp on 3/14/15.
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
Column types

- Int:    Integer number
- Float:  Floating point number (real)
- String: Text
- Blob:   Binary object
*/
public enum ColumnType : String
{
    case Integer = "INTEGER"
    case Float = "REAL"
    case String = "TEXT"
    case Blob = "BLOB"
    case Null = "NULL"
    
    func sqliteColumnType() -> Int
    {
        switch self
        {
        case .Integer:
            return Int(SQLITE_INTEGER)
            
        case .Float:
            return Int(SQLITE_FLOAT)
            
        case .String:
            return Int(SQLITE_TEXT)
            
        case .Blob:
            return Int(SQLITE_BLOB)
            
        case .Null:
            return Int(SQLITE_NULL)
        }
    }
    
    static func fromColumnType(type: Int32) -> ColumnType
    {
        switch type
        {
        case SQLITE_INTEGER:
            return .Integer
            
        case SQLITE_FLOAT:
            return .Float
            
        case SQLITE_TEXT:
            return .String
            
        case SQLITE_BLOB:
            return .Blob
            
        default:
            return .Null
        }
    }
}

/**
*  Column definition
*/
public struct Column
{
    public let name: String
    public let type: ColumnType
    public let notNull: Bool
    public let unique: Bool
    public let primaryKey: Bool
    public let foreignKey: Bool
    
    public init(name: String, type: ColumnType, notNull: Bool = true, unique: Bool = false, primaryKey: Bool = false, foreignKey: Bool = false)
    {
        self.name = name.sqiftSanitize()
        self.type = type
        self.notNull = notNull
        self.unique = unique
        self.primaryKey = primaryKey
        self.foreignKey = foreignKey
    }
    
    /**
    String needed to create the column in a CREATE TABLE statement
    
    :returns: String for creating this column
    */
    public func createString() -> String
    {
        var string = "\(name) \(type.rawValue)"
        
        if notNull
        {
            string += " NOT NULL"
        }
        
        if unique
        {
            string += " UNIQUE"
        }
        
        if primaryKey
        {
            string += " PRIMARY KEY"
        }
        
        if foreignKey
        {
            string += " FOREIGN KEY"
        }
        return string
    }
}

