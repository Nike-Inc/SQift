//
//  Binding.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// Used to store a `Bindable` value representation prior to binding a parameter to a `Statement`.
///
/// For more information about parameter binding, please refer to <https://www.sqlite.org/c3ref/bind_blob.html>.
///
/// - null:    Represents a `NULL` value to bind to a `Statement` using `sqlite3_bind_null`.
/// - integer: Represents a `INTEGER` value to bind to a `Statement` using `sqlite3_bind_int64`.
/// - real:    Represents a `REAL` value to bind to a `Statement` using `sqlite3_bind_double`.
/// - text:    Represents a `TEXT` value to bind to a `Statement` using `sqlite3_bind_text`.
/// - blob:    Represents a `BLOB` value to bind to a `Statement` using `sqlite3_bind_blob`.
public enum BindingValue {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
}

extension BindingValue: Equatable {}

/// Returns whether the lhs and rhs `BindingValue` instances are equal.
///
/// - Parameters:
///   - lhs: The left-hand side `BindingValue` instance to compare.
///   - rhs: The right-hand side `BindingValue` instance to compare.
///
/// - Returns: `true` if the two instances are equal, `false` otherwise.
public func ==(lhs: BindingValue, rhs: BindingValue) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true

    case let (.integer(lhsValue), .integer(rhsValue)):
        return lhsValue == rhsValue

    case let (.real(lhsValue), .real(rhsValue)):
        return lhsValue == rhsValue

    case let (.text(lhsValue), .text(rhsValue)):
        return lhsValue == rhsValue

    case let (.blob(lhsValue), .blob(rhsValue)):
        return lhsValue == rhsValue

    default:
        return false
    }
}

/// The `Bindable` protocol represents any type that can be bound to a `Statement` as a parameter.
public protocol Bindable {
    /// The binding value representation of the type to be bound to a `Statement`.
    var bindingValue: BindingValue { get }
}

/// The `Extractable` protocol represents any type that can be extracted from the `Database`.
public protocol Extractable {
    /// The binding type of a parameter to bind to a statement.
    associatedtype BindingType

    /// The data type of the object to convert to after extracting an object from the database.
    associatedtype DataType = Self

    /// Converts the binding value `Any` object representation to an equivalent `DataType` representation.
    static func fromBindingValue(_ value: Any) -> DataType
}

/// The `Binding` protocol represents a type that is both `Bindable` as a parameter and `Extractable` from the database.
public protocol Binding: Bindable, Extractable {}

// MARK: - Null Bindable

extension NSNull: Bindable {
    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .null }
}

// MARK: - Integer Bindings

extension Bool: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self ? 1 : 0)) }

    /// Converts the binding value `Any` object representation to an equivalent `Bool` representation.
    public static func fromBindingValue(_ value: Any) -> Bool { return (value as! Int64) != 0 }
}

extension Int8: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Int8` representation.
    public static func fromBindingValue(_ value: Any) -> Int8 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int8.min) else { return Int8.min }
        guard castValue <= Int64(Int8.max) else { return Int8.max }

        return Int8(castValue)
    }
}

extension Int16: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Int16` representation.
    public static func fromBindingValue(_ value: Any) -> Int16 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int16.min) else { return Int16.min }
        guard castValue <= Int64(Int16.max) else { return Int16.max }

        return Int16(castValue)
    }
}

extension Int32: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Int32` representation.
    public static func fromBindingValue(_ value: Any) -> Int32 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int32.min) else { return Int32.min }
        guard castValue <= Int64(Int32.max) else { return Int32.max }

        return Int32(castValue)
    }
}

extension Int64: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(self) }

    /// Converts the binding value `Any` object representation to an equivalent `Int64` representation.
    public static func fromBindingValue(_ value: Any) -> Int64 { return value as! Int64 }
}

extension Int: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Int` representation.
    public static func fromBindingValue(_ value: Any) -> Int {
        let castValue = value as! Int64

        guard castValue >= Int64(Int.min) else { return Int.min }
        guard castValue <= Int64(Int.max) else { return Int.max }

        return Int(castValue)
    }
}

extension UInt8: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Int8` representation.
    public static func fromBindingValue(_ value: Any) -> UInt8 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt8.min) else { return UInt8.min }
        guard castValue <= Int64(UInt8.max) else { return UInt8.max }

        return UInt8(castValue)
    }
}

extension UInt16: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `UInt16` representation.
    public static func fromBindingValue(_ value: Any) -> UInt16 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt16.min) else { return UInt16.min }
        guard castValue <= Int64(UInt16.max) else { return UInt16.max }

        return UInt16(castValue)
    }
}

extension UInt32: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `UInt32` representation.
    public static func fromBindingValue(_ value: Any) -> UInt32 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt32.min) else { return UInt32.min }
        guard castValue <= Int64(UInt32.max) else { return UInt32.max }

        return UInt32(castValue)
    }
}

extension UInt64: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(bitPattern: self)) }

    /// Converts the binding value `Any` object representation to an equivalent `UInt64` representation.
    public static func fromBindingValue(_ value: Any) -> UInt64 { return UInt64(bitPattern: value as! Int64) }
}

extension UInt: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Int64

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .integer(Int64(bitPattern: UInt64(self))) }

    /// Converts the binding value `Any` object representation to an equivalent `UInt` representation.
    public static func fromBindingValue(_ value: Any) -> UInt { return UInt(UInt64(bitPattern: value as! Int64)) }
}

// MARK: - Real Bindings

extension Float: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Double

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .real(Double(self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Float` representation.
    public static func fromBindingValue(_ value: Any) -> Float { return Float(value as! Double) }
}

extension Double: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Double

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .real(self) }

    /// Converts the binding value `Any` object representation to an equivalent `Double` representation.
    public static func fromBindingValue(_ value: Any) -> Double { return value as! Double }
}

// MARK: - Text Bindings

extension String: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = String

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .text(self) }

    /// Converts the binding value `Any` object representation to an equivalent `String` representation.
    public static func fromBindingValue(_ value: Any) -> String { return value as! String }
}

extension URL: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = String

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .text(absoluteString) }

    /// Converts the binding value `Any` object representation to an equivalent `URL` representation.
    public static func fromBindingValue(_ value: Any) -> URL { return URL(string: value as! String)! }
}

extension Date: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = String

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .text(BindingDateFormatter.string(from: self)) }

    /// Converts the binding value `Any` object representation to an equivalent `Date` representation.
    public static func fromBindingValue(_ value: Any) -> Date {
        if let value = value as? String {
            return BindingDateFormatter.date(from: value)!
        } else if let value = value as? Int64 {
            return Date(timeIntervalSince1970: TimeInterval(value))
        } else if let value = value as? Double {
            return Date(timeIntervalSince1970: value)
        } else {
            fatalError("Cannot convert `\(type(of: value))` to Date")
        }
    }
}

/// Global date formatter to allow the `Date` binding to read and write dates as strings in the database. This makes
/// dates much more human readable and also works with all SQLite date functionality. For more information, please refer
/// to the following link: <https://www.sqlite.org/lang_datefunc.html>.
public var BindingDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    return formatter
}()

// MARK: - Blob Bindings

extension Data: Binding {
    /// The binding type of a parameter to bind to a statement.
    public typealias BindingType = Data

    /// The binding value representation of the type to be bound to a `Statement`.
    public var bindingValue: BindingValue { return .blob(self) }

    /// Converts the binding value `Any` object representation to an equivalent `Data` representation.
    public static func fromBindingValue(_ value: Any) -> Data { return value as! Data }
}
