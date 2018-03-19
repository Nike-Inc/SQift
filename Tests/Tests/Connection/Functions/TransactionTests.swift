//
//  TransactionTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import XCTest

class TransactionTestCase: BaseConnectionTestCase {
    func testThatConnectionCanExecuteTransaction() throws {
        // Given
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        // When
        try connection.transaction {
            try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
            try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
        }

        let rows: [[Any?]] = try connection.query("SELECT * FROM cars") { $0.values }

        // Then
        if rows.count == 2 {
            XCTAssertEqual(rows[0][0] as? Int64, 1)
            XCTAssertEqual(rows[0][1] as? String, "Audi")
            XCTAssertEqual(rows[0][2] as? Int64, 52642)

            XCTAssertEqual(rows[1][0] as? Int64, 2)
            XCTAssertEqual(rows[1][1] as? String, "Mercedes")
            XCTAssertEqual(rows[1][2] as? Int64, 57127)
        } else {
            XCTFail("rows count should be 2")
        }
    }

    func testThatConnectionCanRollbackTransactionExecutionWhenTransactionThrows() throws {
        // Given
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        // When
        do {
            try connection.transaction {
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                try connection.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
            }
        } catch {
            // No-op: this is expected due to invalid SQL in second prepare statement
        }

        let count: Int? = try connection.query("SELECT count(*) FROM cars")

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - Tests - Savepoints

    func testThatConnectionCanExecuteSavepoint() throws {
        // Given
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        // When
        try connection.savepoint(named: "'savepoint-1'") {
            try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()

            try connection.savepoint(named: "'savepoint    2") {
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
            }
        }

        // When
        let rows: [[Any?]] = try connection.query("SELECT * FROM cars") { $0.values }

        // Then
        if rows.count == 2 {
            XCTAssertEqual(rows[0][0] as? Int64, 1)
            XCTAssertEqual(rows[0][1] as? String, "Audi")
            XCTAssertEqual(rows[0][2] as? Int64, 52642)

            XCTAssertEqual(rows[1][0] as? Int64, 2)
            XCTAssertEqual(rows[1][1] as? String, "Mercedes")
            XCTAssertEqual(rows[1][2] as? Int64, 57127)
        } else {
            XCTFail("rows count should be 2")
        }
    }

    func testThatConnectionCanRollbackToSavepointWhenSavepointExecutionThrows() throws {
        // Given
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        // When
        do {
            try connection.savepoint(named: "save-it-up") {
                try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
                try connection.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
            }
        } catch {
            // No-op: this is expected due to invalid SQL in second prepare statement
        }

        let count: Int? = try connection.query("SELECT count(*) FROM cars")

        // Then
        XCTAssertEqual(count, 0)
    }

    func testThatConnectionCanExecuteSavepointsWithCrazyCharactersInName() throws {
        // Given
        try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

        // When
        try connection.savepoint(named: "savè mę 😱 \n\r\n nõw \n plèãśę  ") {
            try connection.run("INSERT INTO cars VALUES(?, ?, ?)", 1, "Audi", 52642)

            try connection.savepoint(named: "  save with' random \" chàracters") {
                try connection.run("INSERT INTO cars VALUES(?, ?, ?)", 2, "Mercedes", 57127)
            }
        }

        // When
        let rows: [[Any?]] = try connection.query("SELECT * FROM cars") { $0.values }

        // Then
        if rows.count == 2 {
            XCTAssertEqual(rows[0][0] as? Int64, 1)
            XCTAssertEqual(rows[0][1] as? String, "Audi")
            XCTAssertEqual(rows[0][2] as? Int64, 52642)

            XCTAssertEqual(rows[1][0] as? Int64, 2)
            XCTAssertEqual(rows[1][1] as? String, "Mercedes")
            XCTAssertEqual(rows[1][2] as? Int64, 57127)
        } else {
            XCTFail("rows count should be 2")
        }
    }
}
