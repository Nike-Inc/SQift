//
//  FunctionTests.swift
//  SQift
//
//  Created by Christian Noon on 6/23/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class FunctionTestCase: XCTestCase {

    // MARK: - Properties

    private let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/function_tests.db")
        return .onDisk(path)
    }()

    private let text = "dummy_value"
    private let textWithUnicode = "français, 日本語, العربية, 😃🤘🏻😎"

    private let errorMessage = "function failed"
    private let errorMessageWithUnicode = "fūnctïòñ fåìlęd wįth üńíçœdę"

    private let data = "dummy_data".data(using: .utf8)!
    private let zeroData = Data(count: 10)

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Tests - Function Values

    func testThatScalarFunctionCanOutputTheSameInputValues() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            let text = self.text
            let textWithUnicode = self.textWithUnicode
            let data = self.data

            connection.createScalarFunction(withName: "sq_echo") { values in
                guard let value = values.first else { return .null }

                switch value.type {
                case .null:    return .null
                case .integer: return .integer(value.integer)
                case .double:  return .double(value.double)
                case .text:    return .text(value.text)
                case .data:    return .data(value.data)
                }
            }

            // When
            let nilResult: Int? = try connection.prepare("SELECT sq_echo(?)", nil).query()
            let intResult: Int? = try connection.prepare("SELECT sq_echo(?)", 10).query()
            let doubleResult: Double? = try connection.prepare("SELECT sq_echo(?)", 1234.5678).query()
            let textResult: String? = try connection.prepare("SELECT sq_echo(?)", text).query()
            let textWithUnicodeResult: String? = try connection.prepare("SELECT sq_echo(?)", textWithUnicode).query()
            let dataResult: Data? = try connection.prepare("SELECT sq_echo(?)", data).query()

            // Then
            XCTAssertEqual(nilResult, nil)
            XCTAssertEqual(intResult, 10)
            XCTAssertEqual(doubleResult, 1234.5678)
            XCTAssertEqual(textResult, text)
            XCTAssertEqual(textWithUnicodeResult, textWithUnicode)
            XCTAssertEqual(dataResult, data)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatScalarFunctionCanAddMultipleInputValues() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            let data1 = "â".data(using: .utf8)!
            let data2 = "ć".data(using: .utf8)!
            let data3 = "âć".data(using: .utf8)!

            connection.createScalarFunction(withName: "sq_add", argumentCount: 2) { values in
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

            // When
            let nilResult: Int? = try connection.prepare("SELECT sq_add(?, ?)", nil, nil).query()
            let intResult: Int? = try connection.prepare("SELECT sq_add(?, ?)", 1, 2).query()
            let doubleResult: Double? = try connection.prepare("SELECT sq_add(?, ?)", 12.34, 56.78).query()
            let textResult: String? = try connection.prepare("SELECT sq_add(?, ?)", "a", "b").query()
            let textWithUnicodeResult: String? = try connection.prepare("SELECT sq_add(?, ?)", "á", "b").query()
            let dataResult: Data? = try connection.prepare("SELECT sq_add(?, ?)", data1, data2).query()

            // Then
            XCTAssertEqual(nilResult, nil)
            XCTAssertEqual(intResult, 3)
            XCTAssertEqual(doubleResult, 69.12)
            XCTAssertEqual(textResult, "ab")
            XCTAssertEqual(textWithUnicodeResult, "áb")
            XCTAssertEqual(dataResult, data3)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatFunctionValueValueAndQueryPropertiesAllWorkAsExpected() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            connection.createScalarFunction(withName: "sq_value") { values in
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
                    return .data(value2.data)

                case 6:
                    let buffer = value2.buffer
                    return .data(Data(bytes: buffer.map { $0 }, count: buffer.count))

                case 7:
                    return .integer(value2.isNull ? 1 : 0)

                case 8:
                    return .integer(value2.isInteger ? 1 : 0)

                case 9:
                    return .integer(value2.isDouble ? 1 : 0)

                case 10:
                    return .integer(value2.isText ? 1 : 0)

                case 11:
                    return .integer(value2.isData ? 1 : 0)

                default:
                    return .null
                }
            }

            // When
            let result1: Int? = try connection.prepare("SELECT sq_value(?, ?)", 1, 123).query()
            let result2: Int64? = try connection.prepare("SELECT sq_value(?, ?)", 2, 123_456_789).query()
            let result3: Double? = try connection.prepare("SELECT sq_value(?, ?)", 3, 1234.5678).query()
            let result4: String? = try connection.prepare("SELECT sq_value(?, ?)", 4, text).query()
            let result5: Data? = try connection.prepare("SELECT sq_value(?, ?)", 5, data).query()
            let result6: Data? = try connection.prepare("SELECT sq_value(?, ?)", 6, data).query()
            let result7: Bool? = try connection.prepare("SELECT sq_value(?, ?)", 7, nil).query()
            let result8: Bool? = try connection.prepare("SELECT sq_value(?, ?)", 8, 123).query()
            let result9: Bool? = try connection.prepare("SELECT sq_value(?, ?)", 9, 12.34).query()
            let result10: Bool? = try connection.prepare("SELECT sq_value(?, ?)", 10, text).query()
            let result11: Bool? = try connection.prepare("SELECT sq_value(?, ?)", 11, data).query()

            // Then
            XCTAssertEqual(result1, 123)
            XCTAssertEqual(result2, 123_456_789)
            XCTAssertEqual(result3, 1234.5678)
            XCTAssertEqual(result4, text)
            XCTAssertEqual(result5, data)
            XCTAssertEqual(result6, data)
            XCTAssertEqual(result7, true)
            XCTAssertEqual(result8, true)
            XCTAssertEqual(result9, true)
            XCTAssertEqual(result10, true)
            XCTAssertEqual(result11, true)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatFunctionValueNumericTypeCanConvertStringsToNumbers() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            let intData = "1".data(using: .utf8)!
            let doubleData = "12.34".data(using: .utf8)!

            connection.createScalarFunction(withName: "sq_num_value") { values in
                guard let value = values.first else { return .null }

                switch value.numericType {
                case .null:    return .null
                case .integer: return .integer(value.integer)
                case .double:  return .double(value.double)
                case .text:    return .text(value.text)
                case .data:    return .data(value.data)
                }
            }

            // When
            let result1: Int64? = try connection.prepare("SELECT sq_num_value(?)", "123").query()
            let result2: Int64? = try connection.prepare("SELECT sq_num_value(?)", intData).query()
            let result3: Double? = try connection.prepare("SELECT sq_num_value(?)", "1234.5678").query()
            let result4: Double? = try connection.prepare("SELECT sq_num_value(?)", doubleData).query()
            let result5: String? = try connection.prepare("SELECT sq_num_value(?)", "12.34").query()
            let result6: Data? = try connection.prepare("SELECT sq_num_value(?)", intData).query()
            
            // Then
            XCTAssertEqual(result1, 123)
            XCTAssertEqual(result2, nil)
            XCTAssertEqual(result3, 1234.5678)
            XCTAssertEqual(result4, nil)
            XCTAssertEqual(result5, nil)
            XCTAssertEqual(result6, intData)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    // MARK: - Tests - Function Results

    func testThatScalarFunctionCanReturnAllResultTypes() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            let text = self.text
            let data = self.data
            let zeroData = self.zeroData

            connection.createScalarFunction(withName: "sq_switch") { values in
                guard let value = values.first else { return .null }

                switch value.integer {
                case 0:  return .null
                case 1:  return .integer(123)
                case 2:  return .long(123_456_789)
                case 3:  return .double(1234.5678)
                case 4:  return .text(text)
                case 5:  return .data(data)
                case 6:  return .zeroData(10)
                default: return .null
                }
            }

            // When
            let nilResult: Int? = try connection.prepare("SELECT sq_switch(?)", 0).query()
            let intResult: Int? = try connection.prepare("SELECT sq_switch(?)", 1).query()
            let longResult: Int? = try connection.prepare("SELECT sq_switch(?)", 2).query()
            let doubleResult: Double? = try connection.prepare("SELECT sq_switch(?)", 3).query()
            let textResult: String? = try connection.prepare("SELECT sq_switch(?)", 4).query()
            let dataResult: Data? = try connection.prepare("SELECT sq_switch(?)", 5).query()
            let zeroDataResult: Data? = try connection.prepare("SELECT sq_switch(?)", 6).query()

            // Then
            XCTAssertEqual(nilResult, nil)
            XCTAssertEqual(intResult, 123)
            XCTAssertEqual(longResult, 123_456_789)
            XCTAssertEqual(doubleResult, 1234.5678)
            XCTAssertEqual(textResult, text)
            XCTAssertEqual(dataResult, data)
            XCTAssertEqual(zeroDataResult, zeroData)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatScalarFunctionCanThrowErrorMessagesAndCodes() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            let message = self.errorMessage
            let messageWithUnicode = self.errorMessageWithUnicode

            connection.createScalarFunction(withName: "sq_throw") { values in
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

            // When
            XCTAssertThrowsError(try connection.prepare("SELECT sq_throw(?)", 0).run(), "select should throw") { error in
                if let error = error as? SQLiteError {
                    XCTAssertEqual(error.message, message)
                    XCTAssertEqual(error.code, SQLITE_ERROR)
                } else {
                    XCTFail("error should be SQLiteError")
                }
            }

            XCTAssertThrowsError(try connection.prepare("SELECT sq_throw(?)", 1).run(), "select should throw") { error in
                if let error = error as? SQLiteError {
                    XCTAssertEqual(error.message, messageWithUnicode)
                    XCTAssertEqual(error.code, SQLITE_ERROR)
                } else {
                    XCTFail("error should be SQLiteError")
                }
            }

            XCTAssertThrowsError(try connection.prepare("SELECT sq_throw(?)", 2).run(), "select should throw") { error in
                if let error = error as? SQLiteError {
                    XCTAssertEqual(error.message, message)
                    XCTAssertEqual(error.code, SQLITE_ERROR)
                } else {
                    XCTFail("error should be SQLiteError")
                }
            }

            XCTAssertThrowsError(try connection.prepare("SELECT sq_throw(?)", 3).run(), "select should throw") { error in
                if let error = error as? SQLiteError {
                    XCTAssertEqual(error.message, message)
                    XCTAssertEqual(error.code, SQLITE_MISUSE)
                } else {
                    XCTFail("error should be SQLiteError")
                }
            }

            XCTAssertThrowsError(try connection.prepare("SELECT sq_throw(?)", 4).run(), "select should throw") { error in
                if let error = error as? SQLiteError {
                    XCTAssertEqual(error.message, messageWithUnicode)
                    XCTAssertEqual(error.code, SQLITE_CORRUPT)
                } else {
                    XCTFail("error should be SQLiteError")
                }
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    // MARK: - Tests - Function Memory Management

    func testThatMultipleFunctionsWithSameNumberAndDifferentArgumentCountCanBeAdded() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            connection.createScalarFunction(withName: "sq_echo", argumentCount: 1) { _ in return .integer(1) }
            connection.createScalarFunction(withName: "sq_echo", argumentCount: 2) { _ in return .integer(2) }
            connection.createScalarFunction(withName: "sq_echo", argumentCount: 3) { _ in return .integer(3) }
            connection.createScalarFunction(withName: "sq_echo", argumentCount: 4) { _ in return .integer(4) }

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
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatFunctionsCanBeRemovedAtRuntime() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            connection.createScalarFunction(withName: "sq_echo", argumentCount: 1) { _ in return .integer(1) }
            let result1: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

            connection.createScalarFunction(withName: "sq_echo", argumentCount: 1, function: nil)
            XCTAssertThrowsError(try connection.prepare("SELECT sq_echo(?)", 1).run())

            connection.createScalarFunction(withName: "sq_echo", argumentCount: 1) { _ in return .integer(1) }
            let result2: Int64? = try connection.prepare("SELECT sq_echo(?)", 1).query()

            // Then
            XCTAssertEqual(result1, 1)
            XCTAssertEqual(result2, 1)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
