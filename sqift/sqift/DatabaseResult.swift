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

public enum DatabaseResult
{
    case More
    case Done
}

public enum DatabaseError : ErrorType {
    case InternalError (string: String)
    case sqliteError (string: String, code: Int32)
}