//
//  Function.swift
//  SQift
//
//  Created by Christian Noon on 6/23/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

extension Connection {
    // TODO: docstring
    public typealias ScalarFunction = ([FunctionValue]) -> FunctionResult

    // TODO: docstring
    public func createScalarFunction(
        withName name: String,
        argumentCount: Int? = nil,
        deterministic: Bool = false,
        function: ScalarFunction?)
    {
        let nArg: Int32 = argumentCount.flatMap { Int32(exactly: $0) } ?? -1
        let flags = deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8

        guard let function = function else {
            sqlite3_create_function_v2(handle, name, nArg, flags, nil, nil, nil, nil, nil)
            return
        }

        class ScalarFunctionBox {
            let function: ScalarFunction
            init(_ function: @escaping ScalarFunction) { self.function = function }
        }

        let box = ScalarFunctionBox(function)

        sqlite3_create_function_v2(
            handle,
            name,
            nArg,
            flags,
            Unmanaged<ScalarFunctionBox>.passRetained(box).toOpaque(),
            { (context: OpaquePointer?, count: Int32, values: UnsafeMutablePointer<OpaquePointer?>?) in
                let box: ScalarFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()
                let parameters = FunctionValue.functionValues(fromCount: Int(count), values: values)
                let result = box.function(parameters)
                result.apply(to: context)
            },
            nil,
            nil,
            { Unmanaged<ScalarFunctionBox>.fromOpaque($0!).release() }
        )
    }
}

// MARK: -

extension Connection {
    // TODO: docstring
    public struct FunctionValue {
        // TODO: docstring
        public enum DataType {
            case null, integer, double, text, data

            init(_ value: Int32) {
                switch value {
                case SQLITE_INTEGER: self = .integer
                case SQLITE_FLOAT:   self = .double
                case SQLITE_TEXT:    self = .text
                case SQLITE_BLOB:    self = .data
                default:             self = .null
                }
            }
        }

        // TODO: docstring
        public var integer: Int32 { return sqlite3_value_int(value) }
        // TODO: docstring
        public var long: Int64 { return sqlite3_value_int64(value) }
        // TODO: docstring
        public var double: Double { return sqlite3_value_double(value) }
        // TODO: docstring
        public var text: String { return String(cString: sqlite3_value_text(value)) }
        // TODO: docstring
        public var data: Data { return Data(bytes: blob, count: byteLength) }
        // TODO: docstring
        public var buffer: UnsafeRawBufferPointer { return UnsafeRawBufferPointer(start: blob, count: byteLength) }

        // TODO: docstring
        public var type: DataType { return DataType(sqlite3_value_type(value)) }
        // TODO: docstring
        public var numericType: DataType { return DataType(sqlite3_value_numeric_type(value)) }

        // TODO: docstring
        public var isNull: Bool { return type == .null }
        // TODO: docstring
        public var isInteger: Bool { return type == .integer }
        // TODO: docstring
        public var isDouble: Bool { return type == .double }
        // TODO: docstring
        public var isText: Bool { return type == .text }
        // TODO: docstring
        public var isData: Bool { return type == .data }

        var blob: UnsafeRawPointer! { return sqlite3_value_blob(value) }
        var byteLength: Int { return Int(sqlite3_value_bytes(value)) }

        let value: OpaquePointer?

        init(_ value: OpaquePointer?) {
            self.value = value
        }

        static func functionValues(fromCount count: Int, values: UnsafeMutablePointer<OpaquePointer?>?) -> [FunctionValue] {
            guard let values = values else { return [] }
            return (0..<count).map { FunctionValue(values[$0]) }
        }
    }
}

// MARK: -

extension Connection {
    // TODO: docstring
    public enum FunctionResult {
        case null
        case integer(Int32)
        case long(Int64)
        case double(Double)
        case text(String)
        case data(Data)
        case zeroData(UInt64)
        case error(message: String, code: Int32?)

        func apply(to context: OpaquePointer?) {
            switch self {
            case .null:
                sqlite3_result_null(context)

            case .integer(let value):
                sqlite3_result_int(context, value)

            case .long(let value):
                sqlite3_result_int64(context, value)

            case .double(let value):
                sqlite3_result_double(context, value)

            case .text(let text):
                sqlite3_result_text64(context, text, UInt64(text.utf8.count), SQLITE_TRANSIENT, UInt8(SQLITE_UTF8))

            case .data(var data):
                data.withUnsafeBytes { sqlite3_result_blob64(context, $0, UInt64(data.count), SQLITE_TRANSIENT) }

            case .zeroData(let length):
                sqlite3_result_zeroblob64(context, length)

            case .error(let message, let code):
                sqlite3_result_error(context, message, Int32(message.utf8.count))
                if let code = code { sqlite3_result_error_code(context, code) }
            }
        }
    }
}
