//
//  CollationTests.swift
//  SQift
//
//  Created by Christian Noon on 8/10/17.
//  Copyright © 2017 Nike. All rights reserved.
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
            XCTAssertEqual(extracted, expected, "extracted strings array should match expected strings array")
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
            XCTAssertEqual(extracted, expected, "extracted strings array should match expected strings array")
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

            let equal1: Bool = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            connection.createCollation(named: "NODIACRITIC") { lhs, rhs in
                return lhs.compare(rhs, options: [], locale: .autoupdatingCurrent)
            }

            let equal2: Bool = try connection.query("SELECT ? = ? COLLATE 'NODIACRITIC'", "e", "è")

            // Then
            XCTAssertTrue(equal1, "equal 1 should be true when using `.DiacriticInsensitiveSearch` compare options")
            XCTAssertFalse(equal2, "equal 2 should be false when using default compare options")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
