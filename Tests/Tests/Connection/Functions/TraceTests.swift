//
//  TraceTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
@testable import SQift
import XCTest

class TraceTestCase: BaseTestCase {
    func testThatConnectionCanTraceStatementExecution() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)

            var statements: [String] = []

            // When
            connection.trace { SQL in
                statements.append(SQL)
            }

            try connection.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
            try connection.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()
            try connection.stepAll("SELECT * FROM agents")

            connection.trace(nil)

            // Then
            if statements.count == 4 {
                XCTAssertEqual(statements[0], "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                XCTAssertEqual(statements[1], "INSERT INTO agents VALUES(1, 'Sterling Archer')")
                XCTAssertEqual(statements[2], "INSERT INTO agents VALUES(2, 'Lana Kane')")
                XCTAssertEqual(statements[3], "SELECT * FROM agents")
            } else {
                XCTFail("statements count should be 4")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanTraceStatementEventExecution() {
        if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *) {
            do {
                // Given
                var connection: Connection? = try Connection(storageLocation: storageLocation)

                let mask = (
                    Connection.TraceEvent.statementMask |
                    Connection.TraceEvent.profileMask |
                    Connection.TraceEvent.rowMask |
                    Connection.TraceEvent.connectionClosedMask
                )

                var traceEvents: [Connection.TraceEvent] = []

                // When
                connection?.traceEvent(mask: mask) { event in
                    traceEvents.append(event)
                }

                try connection?.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()
                try connection?.stepAll("SELECT * FROM agents")

                connection = nil

                // Then
                if traceEvents.count == 11 {
                    XCTAssertEqual(traceEvents[0].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[1].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[2].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[3].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[4].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[5].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[6].rawValue, "Statement")
                    XCTAssertEqual(traceEvents[7].rawValue, "Row")
                    XCTAssertEqual(traceEvents[8].rawValue, "Row")
                    XCTAssertEqual(traceEvents[9].rawValue, "Profile")
                    XCTAssertEqual(traceEvents[10].rawValue, "ConnectionClosed")

                    if case let .statement(statement, sql) = traceEvents[0] {
                        XCTAssertEqual(statement, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                        XCTAssertEqual(sql, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[1] {
                        XCTAssertEqual(statement, "CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[2] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(1, \'Sterling Archer\')")
                        XCTAssertEqual(sql, "INSERT INTO agents VALUES(?, ?)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[3] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(1, \'Sterling Archer\')")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[4] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(2, \'Lana Kane\')")
                        XCTAssertEqual(sql, "INSERT INTO agents VALUES(?, ?)")
                    }

                    if case let .profile(statement, seconds) = traceEvents[5] {
                        XCTAssertEqual(statement, "INSERT INTO agents VALUES(2, \'Lana Kane\')")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }

                    if case let .statement(statement, sql) = traceEvents[6] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                        XCTAssertEqual(sql, "SELECT * FROM agents")
                    }

                    if case let .row(statement) = traceEvents[7] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                    }

                    if case let .row(statement) = traceEvents[8] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                    }

                    if case let .profile(statement, seconds) = traceEvents[9] {
                        XCTAssertEqual(statement, "SELECT * FROM agents")
                        XCTAssertGreaterThanOrEqual(seconds, 0.0)
                    }
                } else {
                    XCTFail("traceEvents count should be 11")
                }
            } catch {
                XCTFail("Test encountered unexpected error: \(error)")
            }
        }
    }

    func testThatConnectionCanTraceStatementEventExecutionUsingMask() {
        if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *) {
            do {
                // Given
                var connection: Connection? = try Connection(storageLocation: storageLocation)
                var traceEvents: [Connection.TraceEvent] = []

                let mask = Connection.TraceEvent.statementMask | Connection.TraceEvent.profileMask

                // When
                connection?.traceEvent(mask: mask) { event in
                    traceEvents.append(event)
                }

                try connection?.execute("CREATE TABLE agents(id INTEGER PRIMARY KEY, name TEXT)")
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(1, "Sterling Archer").run()
                try connection?.prepare("INSERT INTO agents VALUES(?, ?)").bind(2, "Lana Kane").run()
                try connection?.stepAll("SELECT * FROM agents")

                connection = nil

                // Then
                XCTAssertEqual(traceEvents.count, 8)
            } catch {
                XCTFail("Test encountered unexpected error: \(error)")
            }
        }
    }
}

// MARK: -

@available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
extension Connection.TraceEvent {
    var rawValue: String {
        switch self {
        case .statement:        return "Statement"
        case .profile:          return "Profile"
        case .row:              return "Row"
        case .connectionClosed: return "ConnectionClosed"
        }
    }
}

// MARK: -

extension Statement {
    fileprivate func stepAll() throws {
        while try step() {}
    }
}

// MARK: -

extension Connection {
    fileprivate func stepAll(_ sql: SQL) throws {
        try prepare(sql).stepAll()
    }
}
