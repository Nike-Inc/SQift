//
//  Row.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQLCipher

/// The `Row` struct represents a row returned by a database query. It uses numeric and text-based subscripts along with
/// internal generic methods to extract values from the database.
public struct Row {

    // MARK: - Properties

    private let statement: Statement
    private var handle: COpaquePointer { return statement.handle }

    // MARK: - Initialization

    init(statement: Statement) {
        self.statement = statement
    }

    //=========================== Column Index Subscripts ============================

    /// Returns an `NSNull` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSNull { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `NSNull` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSNull? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `Bool` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Bool { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Bool` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Bool? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `Int8` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int8 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Int8` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int8? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `Int16` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int16 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Int16` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int16? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `Int32` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int32 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Int32` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int32? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `Int64` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int64 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Int64` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int64? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `Int` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Int` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Int? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `UInt8` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt8 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `UInt8` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt8? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `UInt16` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt16 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `UInt16` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt16? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `UInt32` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt32 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `UInt32` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt32? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `UInt64` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt64 { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `UInt64` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt64? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `UInt` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `UInt` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> UInt? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `Float` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Float { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Float` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Float? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `Double` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Double { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `Double` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> Double? { return valueAtColumnIndex(columnIndex) }

    /// Returns a `String` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> String { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `String` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> String? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `NSDate` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSDate { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `NSDate` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSDate? { return valueAtColumnIndex(columnIndex) }

    /// Returns an `NSData` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSData { return valueAtColumnIndex(columnIndex)! }
    /// Returns an optional `NSData` instance extracted from the database at the given column index.
    public subscript(columnIndex: Int) -> NSData? { return valueAtColumnIndex(columnIndex) }

    //=========================== Column Name Subscripts ============================

    /// Returns an `NSNull` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSNull { return valueForColumnName(columnName)! }
    /// Returns an optional `NSNull` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSNull? { return valueForColumnName(columnName) }

    /// Returns a `Bool` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Bool { return valueForColumnName(columnName)! }
    /// Returns an optional `Bool` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Bool? { return valueForColumnName(columnName) }

    /// Returns an `Int8` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int8 { return valueForColumnName(columnName)! }
    /// Returns an optional `Int8` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int8? { return valueForColumnName(columnName) }

    /// Returns an `Int16` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int16 { return valueForColumnName(columnName)! }
    /// Returns an optional `Int16` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int16? { return valueForColumnName(columnName) }

    /// Returns an `Int32` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int32 { return valueForColumnName(columnName)! }
    /// Returns an optional `Int32` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int32? { return valueForColumnName(columnName) }

    /// Returns an `Int64` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int64 { return valueForColumnName(columnName)! }
    /// Returns an optional `Int64` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int64? { return valueForColumnName(columnName) }

    /// Returns an `Int` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int { return valueForColumnName(columnName)! }
    /// Returns an optional `Int` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Int? { return valueForColumnName(columnName) }

    /// Returns a `UInt8` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt8 { return valueForColumnName(columnName)! }
    /// Returns an optional `UInt8` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt8? { return valueForColumnName(columnName) }

    /// Returns a `UInt16` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt16 { return valueForColumnName(columnName)! }
    /// Returns an optional `UInt16` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt16? { return valueForColumnName(columnName) }

    /// Returns a `UInt32` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt32 { return valueForColumnName(columnName)! }
    /// Returns an optional `UInt32` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt32? { return valueForColumnName(columnName) }

    /// Returns a `UInt64` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt64 { return valueForColumnName(columnName)! }
    /// Returns an optional `UInt64` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt64? { return valueForColumnName(columnName) }

    /// Returns a `UInt` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt { return valueForColumnName(columnName)! }
    /// Returns an optional `UInt` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> UInt? { return valueForColumnName(columnName) }

    /// Returns a `Float` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Float { return valueForColumnName(columnName)! }
    /// Returns an optional `Float` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Float? { return valueForColumnName(columnName) }

    /// Returns a `Double` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Double { return valueForColumnName(columnName)! }
    /// Returns an optional `Double` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> Double? { return valueForColumnName(columnName) }

    /// Returns a `String` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> String { return valueForColumnName(columnName)! }
    /// Returns an optional `String` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> String? { return valueForColumnName(columnName) }

    /// Returns an `NSDate` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSDate { return valueForColumnName(columnName)! }
    /// Returns an optional `NSDate` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSDate? { return valueForColumnName(columnName) }

    /// Returns an `NSData` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSData { return valueForColumnName(columnName)! }
    /// Returns an optional `NSData` instance extracted from the database for the column index matching the given name.
    public subscript(columnName: String) -> NSData? { return valueForColumnName(columnName) }

    // MARK: - Values

    /**
        Returns the value at the given column index as an optional `Any` object.

        The value extraction logic uses the `sqlite3_column_type` method to determine what the underlying data type
        is at the column index location in the database. It then uses one of the four following functions to extract
        the data as the correct type:
    
            - sqlite3_column_int64:  `INTEGER` binding value.
            - sqlite3_column_double: `REAL` binding value.
            - sqlite3_column_text:   `TEXT` binding value.
            - sqlite3_column_blob:   `BLOB` binding value.

        For more information, please refer to the following: <https://www.sqlite.org/c3ref/column_blob.html>.

        - parameter columnIndex: The column index to extract the value from.

        - returns: The value at the given column index.
    */
    public func valueAtColumnIndex(columnIndex: Int) -> Any? {
        var value: Any?

        switch statement.columnTypeAtIndex(columnIndex) {
        case SQLITE_NULL:
            value = NSNull()
        case SQLITE_INTEGER:
            value = sqlite3_column_int64(handle, Int32(columnIndex))
        case SQLITE_FLOAT:
            value = sqlite3_column_double(handle, Int32(columnIndex))
        case SQLITE_TEXT:
            value = String.fromCString(UnsafePointer(sqlite3_column_text(handle, Int32(columnIndex)))) ?? ""
        case SQLITE_BLOB:
            let bytes = sqlite3_column_blob(handle, Int32(columnIndex))
            let length = Int(sqlite3_column_bytes(handle, Int32(columnIndex)))
            value = NSData(bytes: bytes, length: length)
        default:
            break
        }

        return value
    }

    /**
         Returns the value at the specified column index as the optional Binding.DataType.

         - parameter columnIndex: The column index to extract the value from.

         - returns: The value at the given column index.
     */
    public func valueAtColumnIndex<T: Binding>(columnIndex: Int) -> T? {
        let value = valueAtColumnIndex(columnIndex)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    /**
         Returns the value at the column index matching the specified name as the optional Binding.DataType.

         - parameter columnName: The column name to extract the value from.

         - returns: The value at the column index matching the specified name.
     */
    public func valueForColumnName<T: Binding>(columnName: String) -> T? {
        guard let columnIndex = statement.columnIndexForName(columnName) else { return nil }
        let value = valueAtColumnIndex(columnIndex)

        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }
}

// MARK: - SequenceType

extension Row: SequenceType {
    /// Returns all values in the `Row` for every column as an array of optional `Any` object.
    public var values: [Any?] { return map { $0 } }

    /// Returns an `AnyGenerator` satisfying the conformance requirements of the `SequenceType` protocol.
    public func generate() -> AnyGenerator<Any?> {
        var currentIndex = 0
        let statement = self.statement

        return anyGenerator {
            guard currentIndex < statement.columnCount else { return nil }

            let value = self.valueAtColumnIndex(currentIndex)
            ++currentIndex

            return value
        }
    }
}

// MARK: - CustomStringConvertible

extension Row: CustomStringConvertible {
    /// A textual description of the `Row` values.
    public var description: String {
        let stringValues: [String] = values.map { value in
            if let value = value as? String {
                return "'\(value)'"
            } else if let value = value {
                return String(value)
            } else {
                return "NULL"
            }
        }

        return "[" + stringValues.joinWithSeparator(", ") + "]"
    }
}
