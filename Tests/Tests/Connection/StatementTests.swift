//
//  StatementTests.swift
//  SQift
//
//  Created by Christian Noon on 8/13/17.
//  Copyright © 2017 Nike. All rights reserved.
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
