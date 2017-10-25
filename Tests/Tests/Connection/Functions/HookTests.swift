//
//  HookTests.swift
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

class HookTestCase: BaseConnectionTestCase {
    func testThatConnectionSupportsUpdateHooks() {
        do {
            // Given
            typealias Result = (type: Connection.UpdateHookType, databaseName: String?, tableName: String?, rowID: Int64)
            var results: [Result] = []

            connection.updateHook { type, databaseName, tableName, rowID in
                results.append((type, databaseName, tableName, rowID))
            }

            // When
            try connection.execute("""
                CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
                INSERT INTO person(name) VALUES('Sterling Archer');
                UPDATE person SET name = 'Lana Kane' WHERE id = 1;
                DELETE FROM person WHERE id = 1
                """
            )

            connection.updateHook(nil)

            try connection.execute("""
                INSERT INTO person(name) VALUES('Sterling Archer');
                UPDATE person SET name = 'Lana Kane' WHERE id = 1;
                DELETE FROM person WHERE id = 1
                """
            )

            // Then
            XCTAssertEqual(results.count, 3)

            if results.count == 3 {
                XCTAssertEqual(results[0].type, .insert)
                XCTAssertEqual(results[0].databaseName, "main")
                XCTAssertEqual(results[0].tableName, "person")
                XCTAssertEqual(results[0].rowID, 1)

                XCTAssertEqual(results[1].type, .update)
                XCTAssertEqual(results[1].databaseName, "main")
                XCTAssertEqual(results[1].tableName, "person")
                XCTAssertEqual(results[1].rowID, 1)

                XCTAssertEqual(results[2].type, .delete)
                XCTAssertEqual(results[2].databaseName, "main")
                XCTAssertEqual(results[2].tableName, "person")
                XCTAssertEqual(results[2].rowID, 1)
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionSupportsCommitHooks() {
        do {
            // Given
            var commitCount: Int = 0

            connection.commitHook {
                commitCount += 1
                return commitCount > 2
            }

            // When
            try connection.execute("""
                CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
                INSERT INTO person(name) VALUES('Sterling Archer')
                """
            )

            // Then
            XCTAssertEqual(commitCount, 2)
            XCTAssertThrowsError(try connection.execute("UPDATE person SET name = 'Lana Kane' WHERE id = 1"))
            XCTAssertEqual(commitCount, 3)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionSupportsRollbackHooks() {
        do {
            // Given
            var commitCount: Int = 0
            var rollbackCount: Int = 0

            connection.commitHook {
                commitCount += 1
                return commitCount > 2
            }

            connection.rollbackHook {
                rollbackCount += 1
            }

            // When
            try connection.execute("""
                CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
                INSERT INTO person(name) VALUES('Sterling Archer')
                """
            )

            // Then
            XCTAssertEqual(commitCount, 2)
            XCTAssertEqual(rollbackCount, 0)

            XCTAssertThrowsError(try connection.execute("UPDATE person SET name = 'Lana Kane' WHERE id = 1"))

            XCTAssertEqual(commitCount, 3)
            XCTAssertEqual(rollbackCount, 1)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
