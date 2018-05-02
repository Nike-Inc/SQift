//
//  TableLockPolicy.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

/// The `TableLockPolicy` enumeration defines whether table lock error handling should poll on the calling thread until
/// the table lock is released or immediately fail by throwing the `SQLITE_LOCKED` error.
///
/// When using a shared cache across multiple connections, SQLite is likely to throw `SQLITE_LOCKED` errors when
/// reading to and writing from the same table simultaneously. Without table lock error handling, `execute`, `prepare`,
/// and `step` operations can and will immediately fail. Instead of immediately failing, the table lock policy allows
/// the calling thread to poll the `execute`, `prepare`, or `step` operation at the specified interval until the table
/// lock has been released.
///
/// If a database is configured with a `WAL` journal mode and a shared cache, a `.poll` table lock policy should
/// generally be used to avoid having to handle the table lock errors directly. A poll interval value of 10 ms is
/// recommended.
///
/// - poll:     Table lock error handling is enabled and polls on table lock errors with the specified delay interval.
/// - fastFail: Table lock error handling is disabled and will throw table lock errors as soon as they are encountered.
public enum TableLockPolicy {
    case poll(TimeInterval)
    case fastFail

    var interval: TimeInterval? {
        switch self {
        case .poll(let interval): return interval
        case .fastFail:           return nil
        }
    }

    var intervalInMicroseconds: UInt32? {
        guard let interval = interval else { return nil }
        return UInt32(exactly: interval * 1_000_000)
    }
}
