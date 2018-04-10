//
//  Function.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQLite3

// MARK: Scalar Functions

extension Connection {
    /// A closure representing a SQLite scalar function that takes a scalar function context and an array of function
    /// values and returns a function result.
    public typealias ScalarFunction = (ScalarFunctionContext, [FunctionValue]) -> FunctionResult

    /// Adds the scalar function to SQLite with the specified name, parameters, and implementation.
    ///
    /// If the `argumentCount` parameter is `-1`, then the scalar function may take any number of arguments between
    /// 0 and 127. If the number of arguments passed is greater than 127, the behavior is undefined.
    ///
    /// It is permitted to register multiple implementations of the same functions with the same name but differing 
    /// numbers of arguments. SQLite will use the implementation that most closely matches the way in which the SQL 
    /// function is used. A function implementation with a non-negative `argumentCount` parameter is a better match 
    /// than a function implementation with a negative `argumentCount`.
    ///
    /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/create_function.html).
    ///
    /// - Parameters:
    ///   - name:          The name of the scalar function to be created or redefined.
    ///   - argumentCount: The number of arguments the scalar function takes.
    ///   - deterministic: Whether the function will always return the same result given the same inputs within a 
    ///                    single SQL statement. `false` by default.
    ///   - function:      The closure representing the scalar function implementation.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when adding the scalar function.
    public func addScalarFunction(
        named name: String,
        argumentCount: Int8,
        deterministic: Bool = false,
        function: @escaping ScalarFunction)
        throws
    {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8

        class ScalarFunctionBox {
            let function: ScalarFunction
            init(_ function: @escaping ScalarFunction) { self.function = function }
        }

        let box = ScalarFunctionBox(function)

        try check(
            sqlite3_create_function_v2(
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
        )
    }

    /// Removes the function with the specified name and argument count from SQLite.
    ///
    /// This method should be used to remove both scalar and aggregate functions.
    ///
    /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/create_function.html).
    ///
    /// - Parameters:
    ///   - name:          The name of the SQL function to remove.
    ///   - argumentCount: The number of arguments the SQL function takes.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when removing the SQL function.
    public func removeFunction(named name: String, argumentCount: Int8) throws {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = SQLITE_UTF8

        try check(sqlite3_create_function_v2(handle, name, nArg, flags, nil, nil, nil, nil, nil))
    }
}

// MARK: - Aggregate Functions

extension Connection {
    /// A closure used as a factory to return an aggregate context object.
    public typealias AggregateContextObjectFactory = () -> AnyObject

    /// A closure representing a SQLite aggregate step function that takes an aggregate function context and an array 
    /// of function values and returns a function result.
    public typealias AggregateStepFunction = (AggregateFunctionContext, [FunctionValue]) -> Void

    /// A closure representing a SQLite aggregate final function that takes an aggregate function context and returns
    /// a function result.
    public typealias AggregateFinalFunction = (AggregateFunctionContext) -> FunctionResult

    /// Adds the aggregate function to SQLite with the specified name, parameters, object factory, and implementations.
    ///
    /// If the `argumentCount` parameter is `-1`, then the aggregate function may take any number of arguments between
    /// 0 and 127. If the number of arguments passed is greater than 127, the behavior is undefined.
    ///
    /// It is permitted to register multiple implementations of the same functions with the same name but differing 
    /// numbers of arguments. SQLite will use the implementation that most closely matches the way in which the SQL 
    /// function is used. A function implementation with a non-negative `argumentCount` parameter is a better match 
    /// than a function implementation with a negative `argumentCount`.
    ///
    /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/create_function.html).
    ///
    /// - Parameters:
    ///   - name:                 The name of the aggregate function to be created or redefined.
    ///   - argumentCount:        The number of arguments the aggregate function takes.
    ///   - deterministic:        Whether the function will always return the same result given the same inputs within a
    ///                           single SQL statement. `false` by default.
    ///   - contextObjectFactory: A closure which returns the a new aggregate context object for the function.
    ///   - stepFunction:         The closure executed when stepping through each of the results.
    ///   - finalFunction:        The closure executed after all the results have been stepped through.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when adding the aggregate function.
    public func addAggregateFunction(
        named name: String,
        argumentCount: Int8,
        deterministic: Bool = false,
        contextObjectFactory: @escaping AggregateContextObjectFactory,
        stepFunction: @escaping AggregateStepFunction,
        finalFunction: @escaping AggregateFinalFunction)
        throws
    {
        let nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        let flags = deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8

        class AggregateFunctionBox {
            let contextObjectFactory: AggregateContextObjectFactory
            let stepFunction: AggregateStepFunction
            let finalFunction: AggregateFinalFunction

            init(
                contextObjectFactory: @escaping AggregateContextObjectFactory,
                stepFunction: @escaping AggregateStepFunction,
                finalFunction: @escaping AggregateFinalFunction)
            {
                self.contextObjectFactory = contextObjectFactory
                self.stepFunction = stepFunction
                self.finalFunction = finalFunction
            }
        }

        let box = AggregateFunctionBox(
            contextObjectFactory: contextObjectFactory,
            stepFunction: stepFunction,
            finalFunction: finalFunction
        )

        try check(
            sqlite3_create_function_v2(
                handle,
                name,
                nArg,
                flags,
                Unmanaged<AggregateFunctionBox>.passRetained(box).toOpaque(),
                nil,
                { (context: OpaquePointer?, count: Int32, values: UnsafeMutablePointer<OpaquePointer?>?) in
                    let box: AggregateFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()
                    let parameters = FunctionValue.functionValues(fromCount: Int(count), values: values)

                    let functionContext = AggregateFunctionContext(
                        context: context,
                        contextObjectFactory: box.contextObjectFactory
                    )

                    box.stepFunction(functionContext, parameters)
                },
                { (context: OpaquePointer?) in
                    let box: AggregateFunctionBox = Unmanaged.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue()

                    let functionContext = AggregateFunctionContext(
                        context: context,
                        contextObjectFactory: box.contextObjectFactory
                    )

                    let result = box.finalFunction(functionContext)
                    result.apply(to: context)

                    functionContext.deallocateAggregateContextObject()
                },
                { (boxPointer: UnsafeMutableRawPointer?) in
                    guard let boxPointer = boxPointer else { return }
                    Unmanaged<AggregateFunctionBox>.fromOpaque(boxPointer).release()
                }
            )
        )
    }
}

// MARK: - Function Values

extension Connection {
    /// Represents a function value being passed into a scalar or aggregate function as an argument. Convenience
    /// properties exist to convert the function value into primitive types.
    ///
    /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/value.html).
    public struct FunctionValue {
        /// Represents the type of data stored within a function value.
        ///
        /// - null:    Represents a `NULL` value.
        /// - integer: Represents an `INTEGER` value.
        /// - float:  Represents a `FLOAT` value.
        /// - text:    Represents a `TEXT` value.
        /// - blob:    Represents a `BLOB` value.
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

        /// Returns the function value as an integer.
        ///
        /// The result is `0` if the value cannot be represented as an integer (i.e. non-numeric text or data). The
        /// result is floor'd if the underlying value is a double.
        public var integer: Int32 { return sqlite3_value_int(value) }

        /// Returns the function value as a long.
        ///
        /// The result is `0` if the value cannot be represented as a long (i.e. non-numeric text or data). The result
        /// is floor'd if the underlying value is a double.
        public var long: Int64 { return sqlite3_value_int64(value) }

        /// Returns the function value as a double.
        ///
        /// The result is `0.0` if the value cannot be represented as a double (i.e. non-numeric text or data). The
        /// result is floor'd if the underlying value is a double.
        public var double: Double { return sqlite3_value_double(value) }

        /// Returns the function value as a string.
        public var text: String { return String(cString: sqlite3_value_text(value)) }

        /// Returns the function value as data.
        public var data: Data { return Data(bytes: blob, count: byteLength) }

        /// Returns the function value as a buffer.
        public var buffer: UnsafeRawBufferPointer { return UnsafeRawBufferPointer(start: blob, count: byteLength) }

        /// Returns the function value as a date if the value can be converted with the binding date formatter.
        public var date: Date? {
            guard isText else { return nil }
            return bindingDateFormatter.date(from: text)
        }

        /// Returns the data type of the function value.
        public var type: DataType { return DataType(sqlite3_value_type(value)) }

        /// Returns the numeric type of the function value.
        ///
        /// Checking the numeric type attempts to convert the value to an integer or floating point number. If the
        /// conversion is possible without loss of information, then the conversion is performed. Otherwise, no
        /// conversion is performed. An example of such a conversion would be converting a "12.34" string into 
        /// a `.float` data type of `12.34`.
        public var numericType: DataType { return DataType(sqlite3_value_numeric_type(value)) }

        /// Whether the underlying value is a `.null` value.
        public var isNull: Bool { return type == .null }

        /// Whether the underlying value is an integer.
        public var isInteger: Bool { return type == .integer }

        /// Whether the underlying value is a double.
        public var isDouble: Bool { return type == .double }

        /// Whether the underlying value is text.
        public var isText: Bool { return type == .text }

        /// Whether the underlying value is data.
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
    /// Represents a result object passed back to SQLite in a scalar or aggregate function.
    ///
    /// - null:     Sets the return value of the function to `NULL`.
    /// - integer:  Sets the return value of the function to a 32-bit signed integer.
    /// - long:     Sets the return value of the function to a 64-bit signed integer.
    /// - double:   Sets the return value of the function to a double.
    /// - text:     Sets the return value of the function to a text string represented as UTF-8.
    /// - date:     Sets the return value of the function to a text string formatted with the binding date formatter.
    /// - data:     Sets the return value of the function to a data blob.
    /// - zeroData: Sets the return value of the function to a data blob of the specified size containing all zero bytes.
    /// - error:    Causes the function to throw an exception with the specified message and code.
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
                if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *) {
                    sqlite3_result_zeroblob64(context, length)
                } else {
                    let clampedLength = Int32(exactly: length) ?? Int32.max
                    sqlite3_result_zeroblob(context, clampedLength)
                }

            case .error(let message, let code):
                sqlite3_result_error(context, message, Int32(message.utf8.count))
                if let code = code { sqlite3_result_error_code(context, code) }
            }
        }
    }
}

// MARK: - Scalar Function Context

extension Connection {
    /// Represents the scalar function context for storing and retrieving auxilary data for scalar constant expressions.
    public class ScalarFunctionContext {
        /// Used to associate metadata with argument values in scalar function contexts. If the same value is passed
        /// to multiple invocations of the same SQL function during query execution, under some circumstances, the
        /// associated metadata may be preserved. An example of where this may be useful is in a date conversion
        /// function. The date formatter could be initialized once, then stored as metadata along with the date
        /// format string. Then as long as the format string remains the same, the same date formatter can be reused
        /// on multiple invocations of the same function.
        ///
        /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/get_auxdata.html).
        public struct AuxilaryData {
            let context: OpaquePointer?

            /// Gets and sets the auxilary data value for an argument value at the specified index.
            ///
            /// - Parameter index: The index of the object to get or set.
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

        /// The auxilary data associated with the function used to store metadata alongside argument values.
        public var auxilaryData: AuxilaryData

        init(context: OpaquePointer?) {
            self.auxilaryData = AuxilaryData(context: context)
        }
    }
}

// MARK: - Aggregate Function Context

extension Connection {
    /// Represents the aggregate function context responsible for allocating and deallocating the context object
    /// for step and final functions. Aggregate functions use the context object to store state between subsequent
    /// calls to the step function as well as the aggregating call to the final function.
    ///
    /// For more details, please refer to the [documentation](https://sqlite.org/c3ref/aggregate_context.html).
    public class AggregateFunctionContext {
        /// Returns the context object to be used in the step function. The context object is lazily instantiated
        /// and reused over multiple invocations of the same query.
        public var stepObject: AnyObject { return aggregateContextObject()! }

        /// Returns the context object to be used in the final function. The context object will only exist if it
        /// was created due to an invocation of the step function and the step object property.
        public var finalObject: AnyObject? { return aggregateContextObject() }

        private let context: OpaquePointer?
        private let contextObjectFactory: AggregateContextObjectFactory

        init(context: OpaquePointer?, contextObjectFactory: @escaping AggregateContextObjectFactory) {
            self.context = context
            self.contextObjectFactory = contextObjectFactory
        }

        func aggregateContextObject() -> AnyObject? {
            let length = MemoryLayout<AnyObject>.size
            guard let pointer = sqlite3_aggregate_context(context, Int32(length)) else { return nil }

            let object: AnyObject

            if pointer.assumingMemoryBound(to: Int.self).pointee == 0 {
                object = contextObjectFactory()
                pointer.initializeMemory(as: AnyObject.self, repeating: object, count: 1)
            } else {
                object = pointer.assumingMemoryBound(to: AnyObject.self).pointee
            }

            return object
        }

        func deallocateAggregateContextObject() {
            guard let pointer = sqlite3_aggregate_context(context, Int32(MemoryLayout<AnyObject>.size)) else { return }
            pointer.assumingMemoryBound(to: AnyObject.self).deinitialize(count: 1)
        }
    }
}
