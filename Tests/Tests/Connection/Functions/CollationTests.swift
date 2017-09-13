//
//  CollationTests.swift
//
//  Copyright (c) 2015-present Nike, Inc. (https://www.nike.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import SQift
import XCTest

class CollationTestCase: BaseTestCase {
    func testThatConnectionCanCreateAndExecuteCustomNumericCollationFunction() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            connection.createCollation(named: "NUMERIC") { lhs, rhs in
                return lhs.compare(rhs, options: .numeric, locale: .autoupdatingCurrent)
            }

            try connection.execute("DROP TABLE IF EXISTS test")
            try connection.execute("CREATE TABLE test(text TEXT COLLATE 'NUMERIC' NOT NULL)")

            let inserted = ["string 1", "string 21", "string 12", "string 11", "string 02"]
            let expected = ["string 1", "string 02", "string 11", "string 12", "string 21"]

            try inserted.forEach { try connection.run("INSERT INTO test(text) VALUES(?)", $0) }

            // When
            let extracted: [String] = try connection.query("SELECT * FROM test ORDER BY text")

            // Then
            XCTAssertEqual(extracted, expected)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCreateAndExecuteCustomDiacriticCollationFunction() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            let options: String.CompareOptions = [.literal, .widthInsensitive, .forcedOrdering]

            connection.createCollation(named: "DIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: options, locale: .autoupdatingCurrent)
            }

            try connection.execute("DROP TABLE IF EXISTS test")
            try connection.execute("CREATE TABLE test(text TEXT COLLATE 'DIACRITIC' NOT NULL)")

            let inserted = ["o", "ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"]
            let expected = ["o", "ó", "ò", "ô", "ö", "õ", "ø", "ō", "œ"]

            try inserted.forEach { try connection.run("INSERT INTO test(text) VALUES(?)", $0) }

            // When
            let extracted: [String] = try connection.query("SELECT * FROM test ORDER BY text")

            // Then
            XCTAssertEqual(extracted, expected)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanReplaceCustomCollationFunctionOnTheFly() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            // When
            connection.createCollation(named: "NODIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: .diacriticInsensitive, locale: .autoupdatingCurrent)
            }

            let equal1: Bool? = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            connection.createCollation(named: "NODIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: [], locale: .autoupdatingCurrent)
            }

            let equal2: Bool? = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            // Then
            XCTAssertEqual(equal1, true)
            XCTAssertEqual(equal2, false)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
