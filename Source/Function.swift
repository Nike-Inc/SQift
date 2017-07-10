//
//  Function.swift
//  SQift
//
//  Created by Christian Noon on 6/23/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

// MARK: Scalar Functions

extension Connection {
    // TODO: docstring
    public typealias ScalarFunction = (ScalarFunctionContext, [FunctionValue]) -> FunctionResult

    // TODO: docstring
    @discardableResult
    public func addScalarFunction(
        named name: String,
        argumentCount: Int8,
        deterministic: Bool = false,
        function: @escaping ScalarFunction)
        -> Int32
    {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8

        class ScalarFunctionBox {
            let function: ScalarFunction
            init(_ function: @escaping ScalarFunction) { self.function = function }
        }

        let box = ScalarFunctionBox(function)

        return sqlite3_create_function_v2(
            handle,
            name,
            nArg,
            flags,
            Unmanaged<ScalarFunctionBox>.passRetained(box).toOpaque(),
            { (context: OpaquePointer?, count: Int32, values: UnsafeMutablePointer<OpaquePointer?>?) in
                let box: ScalarFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()
                let parameters = FunctionValue.functionValues(fromCount: Int(count), values: values)
                let functionContext = ScalarFunctionContext(context: context)

                let result = box.function(functionContext, parameters)
                result.apply(to: context)
            },
            nil,
            nil,
            { (boxPointer: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return }
                Unmanaged<ScalarFunctionBox>.fromOpaque(boxPointer).release()
            }
        )
    }

    // TODO: docstring
    @discardableResult
    public func removeFunction(named name: String, argumentCount: Int8) -> Int32 {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = SQLITE_UTF8

        return sqlite3_create_function_v2(handle, name, nArg, flags, nil, nil, nil, nil, nil)
    }
}

// MARK: - Aggregate Functions

extension Connection {
    // TODO: docstring
    public typealias AggregateFunction = (AggregateFunctionContext, [FunctionValue]) -> FunctionResult

    // TODO: docstring
    public typealias AggregrateContextObject = () -> AnyObject

    // TODO: docstring
    public typealias AggregrateStepFunction = (AggregateFunctionContext, [FunctionValue]) -> Void

    // TODO: docstring
    public typealias AggregateFinalFunction = (AggregateFunctionContext) -> FunctionResult

    // TODO: docstring
    @discardableResult
    public func addAggregateFunction(
        named name: String,
        argumentCount: Int8,
        deterministic: Bool = false,
        contextObject: @escaping AggregrateContextObject,
        stepFunction: @escaping AggregrateStepFunction,
        finalFunction: @escaping AggregateFinalFunction)
        -> Int32
    {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8

        class AggregateFunctionBox {
            let contextObject: AggregrateContextObject
            let stepFunction: AggregrateStepFunction
            let finalFunction: AggregateFinalFunction

            init(
                contextObject: @escaping AggregrateContextObject,
                stepFunction: @escaping AggregrateStepFunction,
                finalFunction: @escaping AggregateFinalFunction)
            {
                self.contextObject = contextObject
                self.stepFunction = stepFunction
                self.finalFunction = finalFunction
            }
        }

        let box = AggregateFunctionBox(contextObject: contextObject, stepFunction: stepFunction, finalFunction: finalFunction)

        return sqlite3_create_function_v2(
            handle,
            name,
            nArg,
            flags,
            Unmanaged<AggregateFunctionBox>.passRetained(box).toOpaque(),
            nil,
            { (context: OpaquePointer?, count: Int32, values: UnsafeMutablePointer<OpaquePointer?>?) in
                let box: AggregateFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()
                let parameters = FunctionValue.functionValues(fromCount: Int(count), values: values)
                let functionContext = AggregateFunctionContext(context: context, contextObject: box.contextObject)

                box.stepFunction(functionContext, parameters)
            },
            { (context: OpaquePointer?) in
                let box: AggregateFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()
                let functionContext = AggregateFunctionContext(context: context, contextObject: box.contextObject)

                let result = box.finalFunction(functionContext)
                result.apply(to: context)

                functionContext.deallocateAggregateContextObject()
            },
            { (boxPointer: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return }
                Unmanaged<AggregateFunctionBox>.fromOpaque(boxPointer).release()
            }
        )
    }
}

// MARK: - Function Values

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

        // TODO: docstring (and add tests)
        public var date: Date? {
            guard isText else { return nil }
            return bindingDateFormatter.date(from: text)
        }

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

        var blob: UnsafeRawPointer { return sqlite3_value_blob(value) }
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

// MARK: - Function Results

extension Connection {
    // TODO: docstring
    public enum FunctionResult {
        case null
        case integer(Int32)
        case long(Int64)
        case double(Double)
        case text(String)
        case date(Date)
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

            case .date(let date):
                let text = bindingDateFormatter.string(from: date)
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

// MARK: - Scalar Function Context

extension Connection {
    // TODO: docstring
    public class ScalarFunctionContext {
        // TODO: docstring
        public struct AuxilaryData {
            let context: OpaquePointer?

            // TODO: docstring
            public subscript(index: Int32) -> AnyObject? {
                get {
                    guard let opaque = sqlite3_get_auxdata(context, index) else { return nil }
                    return Unmanaged.fromOpaque(opaque).takeUnretainedValue()
                }
                set {
                    guard let context = context else { return }

                    if let newValue = newValue {
                        sqlite3_set_auxdata(
                            context,
                            index,
                            Unmanaged.passRetained(newValue).toOpaque(),
                            { (valuePointer: UnsafeMutableRawPointer?) in
                                guard let valuePointer = valuePointer else { return }
                                Unmanaged<AnyObject>.fromOpaque(valuePointer).release()
                            }
                        )
                    } else {
                        sqlite3_set_auxdata(context, index, nil, nil)
                    }
                }
            }
        }

        // TODO: docstring
        public var auxilaryData: AuxilaryData

        // TODO: docstring
        public init(context: OpaquePointer?) {
            self.auxilaryData = AuxilaryData(context: context)
        }

        // TODO: docstring
        public func subType(value: UInt8) {
            sqlite3_result_subtype(auxilaryData.context, UInt32(value))
        }
    }
}

// MARK: - Aggregate Function Context

extension Connection {
    // TODO: docstring
    public class AggregateFunctionContext {
        // TODO: docstring
        public var stepObject: AnyObject { return aggregateContextObject()! }

        // TODO: docstring
        public var finalObject: AnyObject? { return aggregateContextObject() }

        private let context: OpaquePointer?
        private let contextObject: AggregrateContextObject

        // TODO: docstring
        public init(context: OpaquePointer?, contextObject: @escaping AggregrateContextObject) {
            self.context = context
            self.contextObject = contextObject
        }

        func aggregateContextObject() -> AnyObject? {
            let length = MemoryLayout<AnyObject>.size
            let pointer = sqlite3_aggregate_context(context, Int32(length))

            guard let object = pointer?.assumingMemoryBound(to: AnyObject.self).pointee else {
                let object = contextObject()
                pointer?.initializeMemory(as: AnyObject.self, to: object)
                return object
            }

            return object
        }

        func deallocateAggregateContextObject() {
            let length = MemoryLayout<AnyObject>.size
            let pointer = sqlite3_aggregate_context(context, Int32(length))

            pointer?.assumingMemoryBound(to: AnyObject.self).deinitialize()
        }
    }
}
