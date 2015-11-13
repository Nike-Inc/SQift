//
//  Row.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public struct Row {

    // MARK: - Properties

    private let statement: Statement
    private var handle: COpaquePointer { return statement.handle }

    // MARK: - Initialization

    init(statement: Statement) {
        self.statement = statement
    }

    //=========================== Column Index Subscripts ============================

    public subscript(columnIndex: Int) -> NSNull { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> NSNull? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Bool { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Bool? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Int8 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Int8? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Int16 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Int16? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Int32 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Int32? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Int64 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Int64? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Int { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Int? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> UInt8 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> UInt8? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> UInt16 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> UInt16? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> UInt32 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> UInt32? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> UInt64 { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> UInt64? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> UInt { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> UInt? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Float { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Float? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> Double { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> Double? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> String { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> String? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> NSDate { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> NSDate? { return valueAtColumnIndex(columnIndex) }

    public subscript(columnIndex: Int) -> NSData { return valueAtColumnIndex(columnIndex)! }
    public subscript(columnIndex: Int) -> NSData? { return valueAtColumnIndex(columnIndex) }

    //=========================== Column Name Subscripts ============================

    public subscript(columnName: String) -> NSNull { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> NSNull? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Bool { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Bool? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Int8 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Int8? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Int16 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Int16? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Int32 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Int32? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Int64 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Int64? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Int { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Int? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> UInt8 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> UInt8? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> UInt16 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> UInt16? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> UInt32 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> UInt32? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> UInt64 { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> UInt64? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> UInt { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> UInt? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Float { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Float? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> Double { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> Double? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> String { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> String? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> NSDate { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> NSDate? { return valueForColumnName(columnName) }

    public subscript(columnName: String) -> NSData { return valueForColumnName(columnName)! }
    public subscript(columnName: String) -> NSData? { return valueForColumnName(columnName) }

    // MARK: - Values

    public func valueAtColumnIndex(columnIndex: Int) -> Any? {
        var value: Any?

        switch statement.columnTypeAtIndex(columnIndex) {
        case SQLITE_NULL:
            value = nil
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

    public func valueAtColumnIndex<T: Binding>(columnIndex: Int) -> T? {
        let value = valueAtColumnIndex(columnIndex)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    public func valueForColumnName<T: Binding>(columnName: String) -> T? {
        guard let columnIndex = statement.columnIndexForName(columnName) else { return nil }
        let value = valueAtColumnIndex(columnIndex)

        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }
}

// MARK: - SequenceType

extension Row: SequenceType {
    public var values: [Any?] { return map { $0 } }

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
