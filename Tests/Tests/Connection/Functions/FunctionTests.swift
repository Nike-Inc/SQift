//
//  FunctionTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import SQLite3
import XCTest

class FunctionTestCase: BaseTestCase {

    // MARK: - Helper Types

    private class MutableNumber {
        var number: Int64
        init(_ number: Int64 = 0) { self.number = number }
    }

    // MARK: - Properties

    private let text = "dummy_value"
    private let textWithUnicode = "français, 日本語, العربية, 😃🤘🏻😎"

    private let errorMessage = "function failed"
    private let errorMessageWithUnicode = "fūnctïòñ fåìlęd wįth üńíçœdę"

    private let data = "dummy_data".data(using: .utf8)!
    private let zeroData = Data(count: 10)

    // MARK: - Tests - Function Values

    func testThatFunctionValueValueAndQueryPropertiesAllWorkAsExpected() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        let date = Date(timeIntervalSince1970: 123456)

        try connection.addScalarFunction(named: "sq_value", argumentCount: 2) { _, values in
            guard values.count == 2, values[0].type == .integer else { return .null }

            let value1 = values[0]
            let value2 = values[1]

            switch value1.integer {
            case 1:
                return .integer(value2.integer)

            case 2:
                return .long(value2.long)

            case 3:
                return .double(value2.double)

            case 4:
                return .text(value2.text)

            case 5:
                guard let date = value2.date else { return .null }
                return .date(date)

            case 6:
                return .data(value2.data)

            case 7:
                let buffer = value2.buffer
                return .data(Data(bytes: buffer.map { $0 }, count: buffer.count))

            case 8:
                return .integer(value2.isNull ? 1 : 0)

            case 9:
                return .integer(value2.isInteger ? 1 : 0)

            case 10:
                return .integer(value2.isDouble ? 1 : 0)

            case 11:
                return .integer(value2.isText ? 1 : 0)

            case 12:
                return .integer(value2.isData ? 1 : 0)

            default:
                return .null
            }
        }

        let sql = "SELECT sq_value(?, ?)"

        // When
        let result1: Int? = try connection.prepare(sql, 1, 123).query()
        let result2: Int64? = try connection.prepare(sql, 2, 123_456_789).query()
        let result3: Double? = try connection.prepare(sql, 3, 1234.5678).query()
        let result4: String? = try connection.prepare(sql, 4, text).query()
        let result5: Date? = try connection.prepare(sql, 5, date).query()
        let result6: Data? = try connection.prepare(sql, 6, data).query()
        let result7: Data? = try connection.prepare(sql, 7, data).query()
        let result8: Bool? = try connection.prepare(sql, 8, nil).query()
        let result9: Bool? = try connection.prepare(sql, 9, 123).query()
        let result10: Bool? = try connection.prepare(sql, 10, 12.34).query()
        let result11: Bool? = try connection.prepare(sql, 11, text).query()
        let result12: Bool? = try connection.prepare(sql, 12, data).query()

        // Then
        XCTAssertEqual(result1, 123)
        XCTAssertEqual(result2, 123_456_789)
        XCTAssertEqual(result3, 1234.5678)
        XCTAssertEqual(result4, text)
        XCTAssertEqual(result5, date)
        XCTAssertEqual(result6, data)
        XCTAssertEqual(result7, data)
        XCTAssertEqual(result8, true)
        XCTAssertEqual(result9, true)
        XCTAssertEqual(result10, true)
        XCTAssertEqual(result11, true)
        XCTAssertEqual(result12, true)
    }

    func testThatFunctionValueNumericTypeCanConvertStringsToNumbers() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        let intData = "1".data(using: .utf8)!
        let doubleData = "12.34".data(using: .utf8)!

        try connection.addScalarFunction(named: "sq_num_value", argumentCount: 1) { _, values in
            guard let value = values.first else { return .null }

            switch value.numericType {
            case .null:    return .null
            case .integer: return .integer(value.integer)
            case .double:  return .double(value.double)
            case .text:    return .text(value.text)
            case .data:    return .data(value.data)
            }
        }

        let sql = "SELECT sq_num_value(?)"

        // When
        let result1: Int64? = try connection.prepare(sql, "123").query()
        let result2: Int64? = try connection.prepare(sql, intData).query()
        let result3: Double? = try connection.prepare(sql, "1234.5678").query()
        let result4: Double? = try connection.prepare(sql, doubleData).query()
        let result5: String? = try connection.prepare(sql, "12.34").query()
        let result6: Data? = try connection.prepare(sql, intData).query()

        // Then
        XCTAssertEqual(result1, 123)
        XCTAssertEqual(result2, nil)
        XCTAssertEqual(result3, 1234.5678)
        XCTAssertEqual(result4, nil)
        XCTAssertEqual(result5, nil)
        XCTAssertEqual(result6, intData)
    }

    // MARK: - Tests - Function Results

    func testThatScalarFunctionCanReturnAllResultTypes() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        let text = self.text
        let date = Date(timeIntervalSince1970: 123456)
        let data = self.data
        let zeroData = self.zeroData

        try connection.addScalarFunction(named: "sq_switch", argumentCount: 1) { _, values in
            guard let value = values.first else { return .null }

            switch value.integer {
            case 0:  return .null
            case 1:  return .integer(123)
            case 2:  return .long(123_456_789)
            case 3:  return .double(1234.5678)
            case 4:  return .text(text)
            case 5:  return .date(date)
            case 6:  return .data(data)
            case 7:  return .zeroData(10)
            default: return .null
            }
        }

        let sql = "SELECT sq_switch(?)"

        // When
        let nilResult: Int? = try connection.prepare(sql, 0).query()
        let intResult: Int? = try connection.prepare(sql, 1).query()
        let longResult: Int? = try connection.prepare(sql, 2).query()
        let doubleResult: Double? = try connection.prepare(sql, 3).query()
        let textResult: String? = try connection.prepare(sql, 4).query()
        let dateResult: Date? = try connection.prepare(sql, 5).query()
        let dataResult: Data? = try connection.prepare(sql, 6).query()
        let zeroDataResult: Data? = try connection.prepare(sql, 7).query()

        // Then
        XCTAssertEqual(nilResult, nil)
        XCTAssertEqual(intResult, 123)
        XCTAssertEqual(longResult, 123_456_789)
        XCTAssertEqual(doubleResult, 1234.5678)
        XCTAssertEqual(textResult, text)
        XCTAssertEqual(dateResult, date)
        XCTAssertEqual(dataResult, data)
        XCTAssertEqual(zeroDataResult, zeroData)
    }

    func testThatAggregateFunctionCanReturnAllResultTypes() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        let text = self.text
        let date = Date(timeIntervalSince1970: 123456)
        let data = self.data
        let zeroData = self.zeroData

        try connection.addAggregateFunction(
            named: "sq_switch",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard
                    let value = values.first,
                    let object = context.stepObject as? MutableNumber
                    else { return }

                object.number = Int64(value.integer)
            },
            finalFunction: { context in
                guard let object = context.finalObject as? MutableNumber else { return .null }

                switch object.number {
                case 0:  return .null
                case 1:  return .integer(123)
                case 2:  return .long(123_456_789)
                case 3:  return .double(1234.5678)
                case 4:  return .text(text)
                case 5:  return .date(date)
                case 6:  return .data(data)
                case 7:  return .zeroData(10)
                default: return .null
                }
            }
        )

        let sql = "SELECT sq_switch(value) FROM sq_values WHERE value = ?"

        // When
        let nilResult: Int? = try connection.prepare(sql, 0).query()
        let intResult: Int? = try connection.prepare(sql, 1).query()
        let longResult: Int? = try connection.prepare(sql, 2).query()
        let doubleResult: Double? = try connection.prepare(sql, 3).query()
        let textResult: String? = try connection.prepare(sql, 4).query()
        let dateResult: Date? = try connection.prepare(sql, 5).query()
        let dataResult: Data? = try connection.prepare(sql, 6).query()
        let zeroDataResult: Data? = try connection.prepare(sql, 7).query()

        // Then
        XCTAssertEqual(nilResult, nil)
        XCTAssertEqual(intResult, 123)
        XCTAssertEqual(longResult, 123_456_789)
        XCTAssertEqual(doubleResult, 1234.5678)
        XCTAssertEqual(textResult, text)
        XCTAssertEqual(dateResult, date)
        XCTAssertEqual(dataResult, data)
        XCTAssertEqual(zeroDataResult, zeroData)
    }

    func testThatScalarFunctionCanThrowErrorMessagesAndCodes() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        let message = self.errorMessage
        let messageWithUnicode = self.errorMessageWithUnicode

        try connection.addScalarFunction(named: "sq_throw", argumentCount: 1) { _, values in
            guard let value = values.first else { return .null }

            switch value.integer {
            case 0:  return .error(message: message, code: nil)
            case 1:  return .error(message: messageWithUnicode, code: nil)
            case 2:  return .error(message: message, code: SQLITE_ERROR)
            case 3:  return .error(message: message, code: SQLITE_MISUSE)
            case 4:  return .error(message: messageWithUnicode, code: SQLITE_CORRUPT)
            default: return .null
            }
        }

        let sql = "SELECT sq_throw(?)"

        // When, Then
        XCTAssertThrowsError(try connection.prepare(sql, 0).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 1).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, messageWithUnicode)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 2).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 3).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_MISUSE)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 4).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, messageWithUnicode)
                XCTAssertEqual(error.code, SQLITE_CORRUPT)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }
    }

    func testThatAggregateFunctionCanThrowErrorMessagesAndCodes() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        let message = self.errorMessage
        let messageWithUnicode = self.errorMessageWithUnicode

        try connection.addScalarFunction(named: "sq_throw", argumentCount: 1) { _, values in
            guard let value = values.first else { return .null }

            switch value.integer {
            case 0:  return .error(message: message, code: nil)
            case 1:  return .error(message: messageWithUnicode, code: nil)
            case 2:  return .error(message: message, code: SQLITE_ERROR)
            case 3:  return .error(message: message, code: SQLITE_MISUSE)
            case 4:  return .error(message: messageWithUnicode, code: SQLITE_CORRUPT)
            default: return .null
            }
        }

        try connection.addAggregateFunction(
            named: "sq_switch",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard
                    let value = values.first,
                    let object = context.stepObject as? MutableNumber
                    else { return }

                object.number = Int64(value.integer)
            },
            finalFunction: { context in
                guard let object = context.finalObject as? MutableNumber else { return .null }

                switch object.number {
                case 0:  return .error(message: message, code: nil)
                case 1:  return .error(message: messageWithUnicode, code: nil)
                case 2:  return .error(message: message, code: SQLITE_ERROR)
                case 3:  return .error(message: message, code: SQLITE_MISUSE)
                case 4:  return .error(message: messageWithUnicode, code: SQLITE_CORRUPT)
                default: return .null
                }
            }
        )

        let sql = "SELECT sq_throw(value) FROM sq_values WHERE value = ?"

        // When, Then
        XCTAssertThrowsError(try connection.prepare(sql, 0).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 1).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, messageWithUnicode)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 2).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_ERROR)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 3).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, message)
                XCTAssertEqual(error.code, SQLITE_MISUSE)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }

        XCTAssertThrowsError(try connection.prepare(sql, 4).run(), "select should throw") { error in
            if let error = error as? SQLiteError {
                XCTAssertEqual(error.message, messageWithUnicode)
                XCTAssertEqual(error.code, SQLITE_CORRUPT)
            } else {
                XCTFail("error should be SQLiteError")
            }
        }
    }

    func testThatScalarFunctionIsNotCalledAndShutsDownProperlyWhenNoResultsAreFound() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, _ in return .integer(1) }

        // When
        let result: Int64? = try connection.prepare("SELECT sq_echo(?) FROM sq_values WHERE value = 'invalid'").query()

        // Then
        XCTAssertEqual(result, nil)
    }

    func testThatAggregateFunctionIsNotCalledAndShutsDownProperlyWhenNoResultsAreFound() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .null }
        )

        // When
        let result: Int64? = try connection.prepare("SELECT sq_echo(?) FROM sq_values WHERE value = 'invalid'").query()

        // Then
        XCTAssertEqual(result, nil)
    }

    // MARK: - Tests - Add / Remove Functions

    func testThatMultipleScalarFunctionsWithSameNameAndDifferentArgumentCountCanBeAdded() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, _ in return .integer(1) }
        try connection.addScalarFunction(named: "sq_echo", argumentCount: 2) { _, _ in return .integer(2) }
        try connection.addScalarFunction(named: "sq_echo", argumentCount: 3) { _, _ in return .integer(3) }
        try connection.addScalarFunction(named: "sq_echo", argumentCount: 4) { _, _ in return .integer(4) }

        // When
        let result1: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()
        let result2: Int64? = try connection.prepare("SELECT sq_echo(?, ?)", 1, 2).query()
        let result3: Int64? = try connection.prepare("SELECT sq_echo(?, ?, ?)", 1, 2, 3).query()
        let result4: Int64? = try connection.prepare("SELECT sq_echo(?, ?, ?, ?)", 1, 2, 3, 4).query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 2)
        XCTAssertEqual(result3, 3)
        XCTAssertEqual(result4, 4)
    }

    func testThatMultipleAggregateFunctionsWithSameNameAndDifferentArgumentCountCanBeAdded() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(1) }
        )

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 2,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(2) }
        )

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 3,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(3) }
        )

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 4,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(4) }
        )

        // When
        let result1: Int64? = try connection.prepare("SELECT sq_echo(?) FROM sq_values", 1).query()
        let result2: Int64? = try connection.prepare("SELECT sq_echo(?, ?) FROM sq_values", 1, 2).query()
        let result3: Int64? = try connection.prepare("SELECT sq_echo(?, ?, ?) FROM sq_values", 1, 2, 3).query()
        let result4: Int64? = try connection.prepare("SELECT sq_echo(?, ?, ?, ?) FROM sq_values", 1, 2, 3, 4).query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 2)
        XCTAssertEqual(result3, 3)
        XCTAssertEqual(result4, 4)
    }

    func testThatScalarFunctionsCanBeRemovedAtRuntime() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When
        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, _ in return .integer(1) }
        let result1: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

        try connection.removeFunction(named: "sq_echo", argumentCount: 1)
        XCTAssertThrowsError(try connection.prepare("SELECT sq_echo(?)", 1).run())

        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, _ in return .integer(1) }
        let result2: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 1)
    }

    func testThatAggregateFunctionsCanBeRemovedAtRuntime() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        // When
        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(1) }
        )

        let result1: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

        try connection.removeFunction(named: "sq_echo", argumentCount: 1)
        XCTAssertThrowsError(try connection.prepare("SELECT sq_echo(?)", 1).run())

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .integer(1) }
        )

        let result2: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 1)
    }

    // MARK: - Scalar Functions

    func testThatScalarFunctionCanOutputTheSameInputValues() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        let text = self.text
        let textWithUnicode = self.textWithUnicode
        let data = self.data

        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, values in
            guard let value = values.first else { return .null }

            switch value.type {
            case .null:    return .null
            case .integer: return .integer(value.integer)
            case .double:  return .double(value.double)
            case .text:    return .text(value.text)
            case .data:    return .data(value.data)
            }
        }

        let sql = "SELECT sq_echo(?)"

        // When
        let nilResult: Int? = try connection.prepare(sql, nil).query()
        let intResult: Int? = try connection.prepare(sql, 10).query()
        let doubleResult: Double? = try connection.prepare(sql, 1234.5678).query()
        let textResult: String? = try connection.prepare(sql, text).query()
        let textWithUnicodeResult: String? = try connection.prepare(sql, textWithUnicode).query()
        let dataResult: Data? = try connection.prepare(sql, data).query()

        // Then
        XCTAssertEqual(nilResult, nil)
        XCTAssertEqual(intResult, 10)
        XCTAssertEqual(doubleResult, 1234.5678)
        XCTAssertEqual(textResult, text)
        XCTAssertEqual(textWithUnicodeResult, textWithUnicode)
        XCTAssertEqual(dataResult, data)
    }

    func testThatScalarFunctionCanAddMultipleInputValues() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        let data1 = "â".data(using: .utf8)!
        let data2 = "ć".data(using: .utf8)!
        let data3 = "âć".data(using: .utf8)!

        try connection.addScalarFunction(named: "sq_add", argumentCount: 2) { _, values in
            guard values.count == 2 else { return .null }

            let value1 = values[0]
            let value2 = values[1]

            switch (value1.type, value2.type) {
            case (.integer, .integer):
                return .integer(value1.integer + value2.integer)

            case (.double, .double):
                return .double(value1.double + value2.double)

            case (.text, .text):
                return .text(value1.text + value2.text)

            case (.data, .data):
                return .data(value1.data + value2.data)

            default:
                return .null
            }
        }

        let sql = "SELECT sq_add(?, ?)"

        // When
        let nilResult: Int? = try connection.prepare(sql, nil, nil).query()
        let intResult: Int? = try connection.prepare(sql, 1, 2).query()
        let doubleResult: Double? = try connection.prepare(sql, 12.34, 56.78).query()
        let textResult: String? = try connection.prepare(sql, "a", "b").query()
        let textWithUnicodeResult: String? = try connection.prepare(sql, "á", "b").query()
        let dataResult: Data? = try connection.prepare(sql, data1, data2).query()

        // Then
        XCTAssertEqual(nilResult, nil)
        XCTAssertEqual(intResult, 3)
        XCTAssertEqual(doubleResult, 69.12)
        XCTAssertEqual(textResult, "ab")
        XCTAssertEqual(textWithUnicodeResult, "áb")
        XCTAssertEqual(dataResult, data3)
    }

    func testThatScalarFunctionCanReuseAuxilaryDataForConstantExpressions() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        var dateFormattersInitializedCount = 0

        try connection.addScalarFunction(named: "format_date", argumentCount: 2) { context, values in
            guard values.count == 2 else { return .null }

            let value1 = values[0]
            let value2 = values[1]

            guard value1.isText, value2.isInteger, let integer = UInt32(exactly: value2.integer) else { return .null }

            let dateFormat = value1.text
            let date = Date(timeIntervalSince1970: 10_000.0 * TimeInterval(integer))

            let dateFormatter = context.auxilaryData[0] as? DateFormatter ?? {
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = dateFormat
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                context.auxilaryData[0] = dateFormatter

                dateFormattersInitializedCount += 1

                return dateFormatter
                }()

            return .text(dateFormatter.string(from: date))
        }

        let sql = "SELECT format_date(?, value) FROM sq_values"

        // When
        let results: [Date?] = try connection.query(sql, "yyyy-MM-dd'T'HH:mm:ss.SSS")

        // Then
        XCTAssertEqual(dateFormattersInitializedCount, 1)
        XCTAssertEqual(results.count, 10)
        results.forEach { XCTAssertNotNil($0) }
    }

    func testThatScalarFunctionThrowsWhenCalledWithInvalidNumberOfArguments() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)

        try connection.addScalarFunction(named: "sq_echo", argumentCount: 1) { _, _ in
            return .integer(1)
        }

        try connection.addScalarFunction(named: "sq_variable_echo", argumentCount: -1) { _, args in
            return .integer(Int32(args.count))
        }

        // When
        let result1: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()
        let result2: Int64? = try connection.prepare("SELECT sq_variable_echo(?)", 1).query()
        let result3: Int64? = try connection.prepare("SELECT sq_variable_echo(?, ?)", 1, 2).query()
        let result4: Int64? = try connection.prepare("SELECT sq_variable_echo(?, ?, ?)", 1, 2, 3).query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 1)
        XCTAssertEqual(result3, 2)
        XCTAssertEqual(result4, 3)

        XCTAssertThrowsError(try connection.prepare("SELECT sq_echo(?, ?)", 1, 2))
    }

    // MARK: - Aggregate Functions

    func testThatAggregateFunctionCanSumIntegerValuesWithOneFunctionValue() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_sum",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard
                    let value = values.first,
                    let sumNumber = context.stepObject as? MutableNumber,
                    value.type == .integer
                    else { return }

                sumNumber.number += value.long
            },
            finalFunction: { context in
                guard let sumNumber = context.finalObject as? MutableNumber else { return .null }
                return .long(sumNumber.number)
            }
        )

        // When
        let sumResult: Int64? = try connection.prepare("SELECT sq_sum(value) FROM sq_values").query()

        // Then
        XCTAssertEqual(sumResult, 45)
    }

    func testThatAggregateFunctionCanSumIntegerValuesWithOneFunctionValueAndGroupByClause() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_sum",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard
                    let value = values.first,
                    let sumNumber = context.stepObject as? MutableNumber,
                    value.type == .integer
                    else { return }

                sumNumber.number += value.long
            },
            finalFunction: { context in
                guard let sumNumber = context.finalObject as? MutableNumber else { return .null }
                return .long(sumNumber.number)
            }
        )

        let sql = "SELECT sq_sum(value) FROM sq_values GROUP BY grp"

        // When
        let sumResults: [Int64?] = try connection.query(sql)

        // Then
        XCTAssertEqual(sumResults.count, 4)

        if sumResults.count == 4 {
            XCTAssertEqual(sumResults[0], 3)
            XCTAssertEqual(sumResults[1], 7)
            XCTAssertEqual(sumResults[2], 18)
            XCTAssertEqual(sumResults[3], 17)
        }
    }

    func testThatAggregateFunctionCanSumIntegerValuesWithTwoFunctionValues() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_sum",
            argumentCount: 2,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard
                    values.count == 2,
                    values.filter({ $0.type == .integer }).count == 2,
                    let sumNumber = context.stepObject as? MutableNumber
                    else { return }

                sumNumber.number += values.reduce(0) { $0 + $1.long }
            },
            finalFunction: { context in
                guard let sumNumber = context.finalObject as? MutableNumber else { return .null }
                return .long(sumNumber.number)
            }
        )

        // When
        let sumResult: Int64? = try connection.prepare("SELECT sq_sum(grp, value) FROM sq_values").query()

        // Then
        XCTAssertEqual(sumResult, 59)
    }

    func testThatAggregateFunctionThrowsWhenCalledWithInvalidNumberOfArguments() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try loadTablesAndDataForAggregateFunctions(using: connection)

        try connection.addAggregateFunction(
            named: "sq_echo",
            argumentCount: 1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { _, _ in },
            finalFunction: { _ in return .long(1) }
        )

        try connection.addAggregateFunction(
            named: "sq_variable_echo",
            argumentCount: -1,
            contextObjectFactory: { return MutableNumber() },
            stepFunction: { context, values in
                guard let sumNumber = context.stepObject as? MutableNumber else { return }
                sumNumber.number = Int64(values.count)
            },
            finalFunction: { context in
                guard let sumNumber = context.stepObject as? MutableNumber else { return .null }
                return .long(sumNumber.number)
            }
        )

        // When
        let result1: Int64? = try connection.prepare("SELECT sq_echo(grp) FROM sq_values").query()
        let result2: Int64? = try connection.prepare("SELECT sq_variable_echo(grp) FROM sq_values").query()
        let result3: Int64? = try connection.prepare("SELECT sq_variable_echo(grp, value) FROM sq_values").query()
        let result4: Int64? = try connection.prepare("SELECT sq_variable_echo(grp, value, grp) FROM sq_values").query()

        // Then
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 1)
        XCTAssertEqual(result3, 2)
        XCTAssertEqual(result4, 3)

        XCTAssertThrowsError(try connection.prepare("SELECT sq_echo(grp, value) FROM sq_values"))
    }

    // MARK: - Private - Table Data Helpers

    private func loadTablesAndDataForAggregateFunctions(using connection: Connection) throws {
        try connection.execute("""
            CREATE TABLE sq_values(grp INTEGER NOT NULL, value INTEGER NOT NULL);
            INSERT INTO sq_values VALUES (0, 0);
            INSERT INTO sq_values VALUES (0, 1);
            INSERT INTO sq_values VALUES (0, 2);
            INSERT INTO sq_values VALUES (1, 3);
            INSERT INTO sq_values VALUES (1, 4);
            INSERT INTO sq_values VALUES (2, 5);
            INSERT INTO sq_values VALUES (2, 6);
            INSERT INTO sq_values VALUES (2, 7);
            INSERT INTO sq_values VALUES (3, 8);
            INSERT INTO sq_values VALUES (3, 9)
            """
        )
    }
}
