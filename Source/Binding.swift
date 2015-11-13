//
//  Binding.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public enum BindingValue: Equatable {
    case Null
    case Integer(Int64)
    case Real(Double)
    case Text(String)
    case Blob(NSData)
}

public func ==(lhs: BindingValue, rhs: BindingValue) -> Bool {
    switch (lhs, rhs) {
    case (.Null, .Null):
        return true
    case let (.Integer(lhsValue), .Integer(rhsValue)):
        return lhsValue == rhsValue
    case let (.Real(lhsValue), .Real(rhsValue)):
        return lhsValue == rhsValue
    case let (.Text(lhsValue), .Text(rhsValue)):
        return lhsValue == rhsValue
    case let (.Blob(lhsValue), .Blob(rhsValue)):
        return lhsValue == rhsValue
    default:
        return false
    }
}

public protocol Bindable {
    var bindingValue: BindingValue { get }
}

public protocol UnBindable {
    typealias BindingType
    typealias DataType = Self
    static func fromBindingValue(value: Any) -> DataType
}

public protocol Binding: Bindable, UnBindable {}

// MARK: - Null Bindings

extension NSNull: Binding {
    public typealias BindingType = NSNull
    public var bindingValue: BindingValue { return .Null }
    public static func fromBindingValue(value: Any) -> NSNull { return NSNull() }
}

// MARK: - Integer Bindings

extension Bool: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self ? 1 : 0)) }
    public static func fromBindingValue(value: Any) -> Bool { return (value as! Int64) != 0 }
}

extension Int8: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> Int8 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int8.min) else { return Int8.min }
        guard castValue <= Int64(Int8.max) else { return Int8.max }

        return Int8(castValue)
    }
}

extension Int16: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> Int16 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int16.min) else { return Int16.min }
        guard castValue <= Int64(Int16.max) else { return Int16.max }

        return Int16(castValue)
    }
}

extension Int32: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> Int32 {
        let castValue = value as! Int64

        guard castValue >= Int64(Int32.min) else { return Int32.min }
        guard castValue <= Int64(Int32.max) else { return Int32.max }

        return Int32(castValue)
    }
}

extension Int64: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(self) }
    public static func fromBindingValue(value: Any) -> Int64 { return value as! Int64 }
}

extension Int: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> Int {
        let castValue = value as! Int64

        guard castValue >= Int64(Int.min) else { return Int.min }
        guard castValue <= Int64(Int.max) else { return Int.max }

        return Int(castValue)
    }
}

extension UInt8: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> UInt8 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt8.min) else { return UInt8.min }
        guard castValue <= Int64(UInt8.max) else { return UInt8.max }

        return UInt8(castValue)
    }
}

extension UInt16: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> UInt16 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt16.min) else { return UInt16.min }
        guard castValue <= Int64(UInt16.max) else { return UInt16.max }

        return UInt16(castValue)
    }
}

extension UInt32: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(self)) }
    public static func fromBindingValue(value: Any) -> UInt32 {
        let castValue = value as! Int64

        guard castValue >= Int64(UInt32.min) else { return UInt32.min }
        guard castValue <= Int64(UInt32.max) else { return UInt32.max }

        return UInt32(castValue)
    }
}

extension UInt64: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(bitPattern: self)) }
    public static func fromBindingValue(value: Any) -> UInt64 { return UInt64(bitPattern: value as! Int64) }
}

extension UInt: Binding {
    public typealias BindingType = Int64
    public var bindingValue: BindingValue { return .Integer(Int64(bitPattern: UInt64(self))) }
    public static func fromBindingValue(value: Any) -> UInt { return UInt(bitPattern: Int(value as! Int64)) }
}

// MARK: - Real Bindings

extension Float: Binding {
    public typealias BindingType = Double
    public var bindingValue: BindingValue { return .Real(Double(self)) }
    public static func fromBindingValue(value: Any) -> Float { return Float(value as! Double) }
}

extension Double: Binding {
    public typealias BindingType = Double
    public var bindingValue: BindingValue { return .Real(self) }
    public static func fromBindingValue(value: Any) -> Double { return value as! Double }
}

// MARK: - Text Bindings

extension String: Binding {
    public typealias BindingType = String
    public var bindingValue: BindingValue { return .Text(self) }
    public static func fromBindingValue(value: Any) -> String { return value as! String }
}

extension NSDate: Binding {
    public typealias BindingType = String
    public var bindingValue: BindingValue { return .Text(BindingDateFormatter.stringFromDate(self)) }
    public static func fromBindingValue(value: Any) -> NSDate { return BindingDateFormatter.dateFromString(value as! String)! }
}

public var BindingDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return formatter
}()

// MARK: - Blob Bindings

extension NSData: Binding {
    public typealias BindingType = NSData
    public var bindingValue: BindingValue { return .Blob(self) }
    public static func fromBindingValue(value: Any) -> NSData { return value as! NSData }
}
