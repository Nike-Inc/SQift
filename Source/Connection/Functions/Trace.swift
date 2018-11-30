//
//  Trace.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQLite3

extension Connection {

    // MARK: - Helper Types

    /// Used to capture all information about a trace event.
    ///
    /// For more info about tracing, please see the [documentation](https://www.sqlite.org/c3ref/trace_v2.html).
    ///
    /// - statement:        Invoked when a prepared statement first begins running and possibly at other times during
    ///                     the execution of the prepared statement, such as the start of each trigger subprogram. The
    ///                     `statement` represents the expanded SQL statement. The `SQL` represents the unexpanded SQL
    ///                     text of the prepared statement or a SQL comment that indicates the invocation of a trigger.
    ///
    /// - profile:          Invoked when statement execution is complete. The `statement` represents the expanded SQL
    ///                     statement. The `seconds` represents the estimated number of seconds that the prepared
    ///                     statement took to run.
    ///
    /// - row:              Invoked whenever a prepared statement generates a single row of result. The `statement`
    ///                     represents the expanded SQL statement.
    ///
    /// - connectionClosed: Invoked when a database connection closes. The `connection` is a pointer to the database
    ///                     connection.
    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    public enum TraceEvent: CustomStringConvertible {
        case statement(statement: String, sql: SQL)
        case profile(statement: String, seconds: Double)
        case row(statement: String)
        case connectionClosed(connection: OpaquePointer)

        /// Returns the `.statement` bitwise mask.
        public static let statementMask = UInt32(SQLITE_TRACE_STMT)

        /// Returns the `.profile` bitwise mask.
        public static let profileMask = UInt32(SQLITE_TRACE_PROFILE)

        /// Returns the `.row` bitwise mask.
        public static let rowMask = UInt32(SQLITE_TRACE_ROW)

        /// Returns the `.connectionClosed` bitwise mask.
        public static let connectionClosedMask = UInt32(SQLITE_TRACE_CLOSE)

        /// A textual description of the `TraceEvent`.
        public var description: String {
            switch self {
            case let .statement(statement, sql):
                return "TraceEvent (Statement): statement: \"\(statement)\", SQL: \"\(sql)\""

            case let .profile(statement, seconds):
                return "TraceEvent (Profile): statement: \"\(statement)\", SQL: \"\(seconds)\""

            case let .row(statement):
                return "TraceEvent (Row): \"\(statement)\""

            case let .connectionClosed(connection):
                return "TraceEvent (ConnectionClosed): connection: \"\(connection)\""
            }
        }
    }

    private class TraceBox {
        let closure: (String) -> Void

        init(_ closure: @escaping (String) -> Void) {
            self.closure = closure
        }

        func trace(_ data: UnsafePointer<Int8>?) {
            let message = data != nil ? String(cString: data!) : ""
            closure(message)
        }
    }

    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    private class TraceEventBox {
        let closure: (TraceEvent) -> Void

        init(_ closure: @escaping (TraceEvent) -> Void) {
            self.closure = closure
        }

        func trace(mask: UInt32, arg1: UnsafeMutableRawPointer?, arg2: UnsafeMutableRawPointer?) -> Int32 {
            guard let arg1 = arg1 else { return 0 }

            let statementOrConnection = OpaquePointer(arg1)
            let event: TraceEvent

            switch mask {
            case UInt32(TraceEvent.statementMask):
                guard let arg2 = arg2 else { return 0 }

                let sql = String(cString: arg2.assumingMemoryBound(to: CChar.self))
                let statement = String(cString: sqlite3_expanded_sql(statementOrConnection))

                event = .statement(statement: statement, sql: sql)

            case UInt32(TraceEvent.profileMask):
                guard
                    let sql = sqlite3_expanded_sql(statementOrConnection),
                    let statement = String(validatingUTF8: sql),
                    let arg2 = arg2
                    else { return 0 }

                let nanoseconds = arg2.assumingMemoryBound(to: Int64.self).pointee
                let seconds = Double(nanoseconds) * 0.000_000_001

                event = .profile(statement: statement, seconds: seconds)

            case UInt32(TraceEvent.rowMask):
                guard
                    let sql = sqlite3_expanded_sql(statementOrConnection),
                    let statement = String(validatingUTF8: sql)
                    else { return 0 }

                event = .row(statement: statement)

            case UInt32(TraceEvent.connectionClosedMask):
                event = .connectionClosed(connection: statementOrConnection)

            default:
                return 0
            }

            closure(event)

            return 0
        }
    }

    // MARK: - Tracing

    /// Registers the callback with SQLite to be called each time a statement calls step.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/profile.html).
    ///
    /// - Parameter closure: The closure called when SQLite internally calls step on a statement.
    public func trace(_ closure: ((String) -> Void)?) {
        guard let closure = closure else {
            sqlite3_trace_v2(handle, 0, nil, nil)
            traceBox = nil
            return
        }

        let box = TraceBox(closure)
        traceBox = box

        sqlite3_trace_v2(
            handle,
            0,
            { (mask: UInt32, boxPointer: UnsafeMutableRawPointer?, arg1: UnsafeMutableRawPointer?, arg2: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return 0 }
                let box = Unmanaged<TraceEventBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.trace(mask: mask, arg1: arg1, arg2: arg2)
            },
            Unmanaged<TraceBox>.passUnretained(box).toOpaque()
        )
    }

    /// Registers the callback with SQLite to be called each time a statement calls step.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/c3ref/trace_v2.html).
    ///
    /// - Parameters:
    ///   - mask:    The bitwise OR-ed mask of trace event constants.
    ///   - closure: The closure called when SQLite internally calls step on a statement.
    @available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *)
    public func traceEvent(mask: UInt32? = nil, closure: ((TraceEvent) -> Void)?) {
        guard let closure = closure else {
            sqlite3_trace_v2(handle, 0, nil, nil)
            traceEventBox = nil
            return
        }

        let box = TraceEventBox(closure)
        traceEventBox = box

        let mask = mask ?? UInt32(SQLITE_TRACE_STMT | SQLITE_TRACE_PROFILE | SQLITE_TRACE_ROW | SQLITE_TRACE_CLOSE)

        sqlite3_trace_v2(
            handle,
            mask,
            { (mask: UInt32, boxPointer: UnsafeMutableRawPointer?, arg1: UnsafeMutableRawPointer?, arg2: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return 0 }
                let box = Unmanaged<TraceEventBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.trace(mask: mask, arg1: arg1, arg2: arg2)
            },
            Unmanaged<TraceEventBox>.passUnretained(box).toOpaque()
        )
    }
}
