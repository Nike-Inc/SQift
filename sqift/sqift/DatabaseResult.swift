//
//  DatabaseResult.swift
//  sqift
//
//  Created by Dave Camp on 3/14/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

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
    
    public func nserror() -> NSError {
        switch self {
        case .InternalError(let string):
            return NSError(domain: "com.thinbits.sqift", code: -1, userInfo: [NSLocalizedDescriptionKey : string])
        case .sqliteError(let string, let code):
            return NSError(domain: "com.thinbits.sqift", code: Int(code), userInfo: [NSLocalizedDescriptionKey : string])
        }
    }
}