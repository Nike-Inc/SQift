//
//  AuthorizerTests.swift
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

class AuthozierTestCase: BaseConnectionTestCase {

    // MARK: - Helper Types

    private struct Result: Equatable {
        let action: Connection.AuthorizerAction
        let p1: String?
        let p2: String?
        let p3: String?
        let p4: String?

        init(_ action: Connection.AuthorizerAction, _ p1: String?, _ p2: String?, _ p3: String?, _ p4: String?) {
            self.action = action
            self.p1 = p1
            self.p2 = p2
            self.p3 = p3
            self.p4 = p4
        }

        static func ==(lhs: Result, rhs: Result) -> Bool {
            return lhs.action == rhs.action && lhs.p1 == rhs.p1 && lhs.p2 == rhs.p2 && lhs.p3 == rhs.p3 && lhs.p4 == rhs.p4
        }
    }

    // MARK: - Tests

    func testThatConnectionCanSetAuthorizerAndAllowOperations() {
        do {
            // Given
            var results: [Result] = []

            try connection.authorizer { action, p1, p2, p3, p4 in
                if action != .read {
                    let result = Result(action, p1, p2, p3, p4)
                    results.append(result)
                }

                return .ok
            }

            // When
            try connection.execute("""
                CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
                INSERT INTO person(name) VALUES('Sterling Archer');
                UPDATE person SET name = 'Lana Kane' WHERE id = 1;
                SELECT * FROM person;
                CREATE INDEX name_index ON person (name);
                DROP INDEX name_index;
                DELETE FROM person
                """
            )

            let expectedResults = [
                Result(.insert, "sqlite_master", nil, "main", nil),
                Result(.createTable, "person", nil, "main", nil),
                Result(.update, "sqlite_master", "type", "main", nil),
                Result(.update, "sqlite_master", "name", "main", nil),
                Result(.update, "sqlite_master", "tbl_name", "main", nil),
                Result(.update, "sqlite_master", "rootpage", "main", nil),
                Result(.update, "sqlite_master", "sql", "main", nil),
                Result(.insert, "person", nil, "main", nil),
                Result(.update, "person", "name", "main", nil),
                Result(.select, nil, nil, nil, nil),
                Result(.insert, "sqlite_master", nil, "main", nil),
                Result(.createIndex, "name_index", "person", "main", nil),
                Result(.insert, "sqlite_master", nil, "main", nil),
                Result(.reindex, "name_index", nil, "main", nil),
                Result(.delete, "sqlite_master", nil, "main", nil),
                Result(.dropIndex, "name_index", "person", "main", nil),
                Result(.delete, "sqlite_master", nil, "main", nil),
                Result(.update, "sqlite_master", "rootpage", "main", nil),
                Result(.delete, "person", nil, "main", nil)
            ]

            // Then
            XCTAssertEqual(results.count, expectedResults.count)

            for (actual, expected) in zip(results, expectedResults) {
                XCTAssertEqual(actual, expected)
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanSetAuthorizerAndDenyOperations() {
        do {
            // Given
            try connection.authorizer { _, _, _, _, _ in return .deny }

            var authorizationError: Error?

            // When
            do {
                try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
            } catch {
                authorizationError = error
            }

            // Then
            XCTAssertNotNil(authorizationError)

            if let error = authorizationError as? SQLiteError {
                XCTAssertEqual(error.code, SQLITE_AUTH)
                XCTAssertEqual(error.message, "not authorized")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanSetAuthorizerAndIgnoreOperations() {
        do {
            // Given
            var results: [Result] = []

            try connection.authorizer { action, p1, p2, p3, p4 in
                if action != .read {
                    let result = Result(action, p1, p2, p3, p4)
                    results.append(result)
                }

                return action == .delete ? .ignore : .ok
            }

            // When
            try connection.execute("""
                CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
                INSERT INTO person(name) VALUES('Sterling Archer');
                DELETE FROM person WHERE id = 1
                """
            )

            let expectedResults = [
                Result(.insert, "sqlite_master", nil, "main", nil),
                Result(.createTable, "person", nil, "main", nil),
                Result(.update, "sqlite_master", "type", "main", nil),
                Result(.update, "sqlite_master", "name", "main", nil),
                Result(.update, "sqlite_master", "tbl_name", "main", nil),
                Result(.update, "sqlite_master", "rootpage", "main", nil),
                Result(.update, "sqlite_master", "sql", "main", nil),
                Result(.insert, "person", nil, "main", nil),
                Result(.delete, "person", nil, "main", nil)
            ]

            // Then
            XCTAssertEqual(results.count, expectedResults.count)

            for (actual, expected) in zip(results, expectedResults) {
                XCTAssertEqual(actual, expected)
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanSetAuthorizerAndReturnCustomResult() {
        do {
            // Given
            try connection.authorizer { _, _, _, _, _ in return .custom(SQLITE_FAIL) }

            var authorizationError: Error?

            // When
            do {
                try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
            } catch {
                authorizationError = error
            }

            // Then
            XCTAssertNotNil(authorizationError)

            if let error = authorizationError as? SQLiteError {
                XCTAssertEqual(error.code, SQLITE_ERROR)
                XCTAssertEqual(error.message, "authorizer malfunction")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
