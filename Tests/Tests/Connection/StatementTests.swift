//
//  StatementTests.swift
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
@testable import SQift
import SQLite3
import XCTest

class StatementTestCase: BaseConnectionTestCase {
    func testThatStatementCanReturnWhetherItIsBusy() {
        do {
            // Given
            let statement = try connection.prepare("SELECT name FROM agents WHERE missions > ?", 2_000)

            // When
            let isBusyBeforeStep = statement.isBusy
            _ = try statement.step()
            let isBusyAfterFirstStep = statement.isBusy
            _ = try statement.step()
            let isBusyAfterSecondStep = statement.isBusy

            // Then
            XCTAssertEqual(isBusyBeforeStep, false)
            XCTAssertEqual(isBusyAfterFirstStep, true)
            XCTAssertEqual(isBusyAfterSecondStep, false)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatStatementCanReturnWhetherItIsReadOnly() {
        do {
            // Given
            try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, first_name TEXT NOT NULL)")

            // When
            let insertStatement = try connection.prepare("INSERT INTO person(first_name) VALUES('Sterling')")
            let updateStatement = try connection.prepare("UPDATE person SET first_name = 'Lana' WHERE id = 1")
            let deleteStatement = try connection.prepare("DELETE FROM person WHERE id = 1")
            let selectStatement = try connection.prepare("SELECT * FROM person")

            // Then
            XCTAssertEqual(insertStatement.isReadOnly, false)
            XCTAssertEqual(updateStatement.isReadOnly, false)
            XCTAssertEqual(deleteStatement.isReadOnly, false)
            XCTAssertEqual(selectStatement.isReadOnly, true)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatStatementCanReturnSQLBoundWithParameters() {
        do {
            // Given
            try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, first_name TEXT NOT NULL)")

            let insertStatement = try connection.prepare("INSERT INTO person(first_name) VALUES(?)", "Sterling")
            let updateStatement = try connection.prepare("UPDATE person SET first_name = ? WHERE id = ?", "Lana", 1)
            let deleteStatement = try connection.prepare("DELETE FROM person WHERE id = ?", 1)
            let selectStatement = try connection.prepare("SELECT * FROM person WHERE id = ?", 1)

            // When
            let insertSQL = insertStatement.sql
            let updateSQL = updateStatement.sql
            let deleteSQL = deleteStatement.sql
            let selectSQL = selectStatement.sql

            // Then
            XCTAssertEqual(insertSQL, "INSERT INTO person(first_name) VALUES(?)")
            XCTAssertEqual(updateSQL, "UPDATE person SET first_name = ? WHERE id = ?")
            XCTAssertEqual(deleteSQL, "DELETE FROM person WHERE id = ?")
            XCTAssertEqual(selectSQL, "SELECT * FROM person WHERE id = ?")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatStatementCanReturnExpandedSQLBoundWithParameters() {
        guard #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *) else { return }

        do {
            // Given
            try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, first_name TEXT NOT NULL)")

            let insertStatement = try connection.prepare("INSERT INTO person(first_name) VALUES(?)", "Sterling")
            let updateStatement = try connection.prepare("UPDATE person SET first_name = ? WHERE id = ?", "Lana", 1)
            let deleteStatement = try connection.prepare("DELETE FROM person WHERE id = ?", 1)
            let selectStatement = try connection.prepare("SELECT * FROM person WHERE id = ?", 1)

            // When
            let insertSQL = insertStatement.expandedSQL
            let updateSQL = updateStatement.expandedSQL
            let deleteSQL = deleteStatement.expandedSQL
            let selectSQL = selectStatement.expandedSQL

            // Then
            XCTAssertEqual(insertSQL, "INSERT INTO person(first_name) VALUES('Sterling')")
            XCTAssertEqual(updateSQL, "UPDATE person SET first_name = 'Lana' WHERE id = 1")
            XCTAssertEqual(deleteSQL, "DELETE FROM person WHERE id = 1")
            XCTAssertEqual(selectSQL, "SELECT * FROM person WHERE id = 1")
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
