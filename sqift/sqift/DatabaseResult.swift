//
//  DatabaseResult.swift
//  sqift
//
//  Created by Dave Camp on 3/14/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation
#if os(iOS)
#if arch(i386) || arch(x86_64)
    import sqlite3_ios_simulator
    #else
    import sqlite3_ios
#endif
#endif

/**
SQL STEP result.

- More: There is more data to step through.
- Done: No more data.
*/
public enum DatabaseResult
{
    case More
    case Done
}

/**
*  Error class thrown by sqift methods.
*/
public enum DatabaseError : ErrorType {
    case InternalError (string: String)
    case sqliteError (string: String, code: Int32)
}