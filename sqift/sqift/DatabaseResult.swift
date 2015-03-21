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
Enum wrapper for sqlite results

- Success: Operation succeeded with no errors
- Error:   Operation failed, error string is associated value
*/
public enum DatabaseResult : Equatable
{
    case Success
    case More
    case Done
    case Error(String?)
    
    func isError() -> Bool
    {
        return self != .Error(nil)
    }
}

public func ==(a: DatabaseResult, b: DatabaseResult) -> Bool {
    switch (a, b)
    {
    case (.Success(), .Success()):
        return true
        
    case (.More(), .More()):
        return true
        
    case (.Done(), .Done()):
        return true
        
    case (.Error(let a), .Error(let b)) where a == nil || b == nil || a! == b!:
        return true
        
    default:
        return false
    }
}

public func !=(a: DatabaseResult, b: DatabaseResult) -> Bool {
    return (a == b) ? false : true
}

