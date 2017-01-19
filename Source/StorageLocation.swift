//
//  StorageLocation.swift
//  SQift
//
//  Created by Christian Noon on 11/17/15.
//  Copyright © 2015 Nike. All rights reserved.
//

//import Foundation
//
///**
//    Used to specify the path of the database for initialization.
//
//    - OnDisk:    Creates an on-disk database: <https://www.sqlite.org/uri.html>.
//    - InMemory:  Creates an in-memory database: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>.
//    - Temporary: Creates a temporary on-disk database: <https://www.sqlite.org/inmemorydb.html#temp_db>.
//*/
//public enum StorageLocation {
//    case OnDisk(String)
//    case InMemory
//    case Temporary
//
//    /// Returns the path of the database.
//    public var path: String {
//        switch self {
//        case .OnDisk(let path):
//            return path
//        case .InMemory:
//            return ":memory:"
//        case .Temporary:
//            return ""
//        }
//    }
//}
