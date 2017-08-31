//
//  StorageLocation.swift
//  SQift
//
//  Created by Christian Noon on 11/17/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// Used to specify the path of the database for initialization.
///
/// - onDisk:    Creates an [on-disk database](https://www.sqlite.org/uri.html).
/// - inMemory:  Creates an [in-memory database](https://www.sqlite.org/inmemorydb.html#sharedmemdb).
/// - temporary: Creates a [temporary on-disk database](https://www.sqlite.org/inmemorydb.html#temp_db).
public enum StorageLocation {
    case onDisk(String)
    case inMemory
    case temporary

    /// Returns the path of the database.
    public var path: String {
        switch self {
        case .onDisk(let path):
            return path

        case .inMemory:
            return ":memory:"

        case .temporary:
            return ""
        }
    }
}
