//
//  String+sqift.swift
//  sqift
//
//  Created by Dave Camp on 3/14/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

public extension String
{
    /**
    Sanitize a string for use in an sqlite statement
    
    :returns: Sanitized string
    */
    public func sqiftSanitize() -> String
    {
        var string = self
        string = string.stringByReplacingOccurrencesOfString("\"", withString:"\"\"", options: NSStringCompareOptions.LiteralSearch, range: nil)
        string = "\"" + string + "\""
        
        return string
    }
}

public func sanitizeStrings(strings: [String]) -> [String]
{
    let newStrings = strings.map( { $0.sqiftSanitize() } )
    
    return newStrings
}