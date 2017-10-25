//
//  Busy.swift
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
    /// A closure executed for a custom busy handler that takes a single argument: the number of times the busy
    /// handler was previously invoked for the same locking event. The closure should return `true` to continue invoking
    /// the busy handler, `false` to have SQLite throw a `SQLITE_BUSY` error instead.
    public typealias CustomBusyHandler = (_ invocationCount: Int32) -> Bool

    // MARK: - Helper Types

    /// Represents the type of busy handler to be used on the connection.
    ///
    /// - timeout:         Creates an internal busy handler in SQLite that sleeps for a specified amount of time when a
    ///                    table is locked. The handler will sleep multiple times until at least "ms" milliseconds of
    ///                    sleeping have accumulated. After at least "ms" milliseconds of sleeping, the handler returns
    ///                    `false` which causes `sqlite3_step()` to return `SQLITE_BUSY`. Setting the time interval to
    ///                    less than or equal to zero turns off all busy handlers. This can also be done by setting the
    ///                    busy handler to `.defaultBehavior`.
    ///
    /// - custom:          Invokes the custom busy handler whenever an attempt is made to access a database table
    ///                    associated with the connection when another thread or process has the table locked. The
    ///                    custom busy handler is passed the number of times the busy handler has been invoked
    ///                    previously for the same locking event. If the handler returns `false`, then no additional
    ///                    attempts are made to access the database and `SQLITE_BUSY` is returned to the application.
    ///                    If the handler returns `true`, then another attempt is made to access the database and the
    ///                    cycle repeats.
    ///
    /// - defaultBehavior: Clears all busy handlers from the connection. This results in all "busy" scenarios
    ///                    throwing a `SQLITE_BUSY` error when encountered.
    public enum BusyHandler {
        /// Prevents busy error from being thrown for the specified time interval.
        case timeout(TimeInterval)

        /// Invokes the custom busy handler when a table is locked.
        case custom(CustomBusyHandler)

        /// Clears any registered busy handler and throws `SQLITE_BUSY` errors when encountered.
        case defaultBehavior
    }

    private class BusyHandlerBox {
        let handler: CustomBusyHandler
        init(_ handler: @escaping CustomBusyHandler) { self.handler = handler }
    }

    // MARK: - Busy Handler

    /// Sets the busy handler for the connection.
    ///
    /// The presence of a busy handler does not guarantee that it will be invoked when there is lock contention. If
    /// SQLite determines that invoking the busy handler could result in a deadlock, it will go ahead and return
    /// `SQLITE_BUSY` to the application instead of invoking the busy handler. Consider a scenario where one process
    /// is holding a read lock that it is trying to promote to a reserved lock and a second process is holding a
    /// reserved lock that it is trying to promote to an exclusive lock.  The first process cannot proceed because it
    /// is blocked by the second and the second process cannot proceed because it is blocked by the first. If both
    /// processes invoke the busy handlers, neither will make any progress. Therefore, SQLite returns `SQLITE_BUSY` for
    /// the first process, hoping that this will induce the first process to release its read lock and allow the second
    /// process to proceed.
    ///
    /// - Parameter handler: The busy handler to set on the connection.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when trying to set the timeout or busy handler.
    public func busyHandler(_ handler: BusyHandler) throws {
        var box: BusyHandlerBox?
        let result: Int32

        switch handler {
        case let .timeout(seconds):
            let milliseconds = Int32(floor(seconds * 1_000.0))
            result = sqlite3_busy_timeout(handle, milliseconds)

        case let .custom(handler):
            let busyHandlerBox = BusyHandlerBox(handler)
            box = busyHandlerBox

            result = sqlite3_busy_handler(
                handle,
                { (boxPointer: UnsafeMutableRawPointer?, invocationCount: Int32) -> Int32 in
                    guard let boxPointer = boxPointer else { return 0 }
                    let box = Unmanaged<BusyHandlerBox>.fromOpaque(boxPointer).takeUnretainedValue()
                    return box.handler(invocationCount) ? 1 : 0
                },
                Unmanaged<BusyHandlerBox>.passUnretained(busyHandlerBox).toOpaque()
            )

        case .defaultBehavior:
            result = sqlite3_busy_handler(handle, nil, nil)
        }

        busyHandlerBox = box
        try check(result)
    }
}
