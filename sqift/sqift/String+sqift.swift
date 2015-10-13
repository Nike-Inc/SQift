//
//  String+sqift.swift
//  sqift
//
//  Created by Dave Camp on 3/14/15.
//  Copyright (c) 2015 Nike. All rights reserved.
//

import Foundation

// String extension to sanitize SQL data.
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

// Array<String> extension to sanitize SQL data.
public extension Array where Element : StringLiteralConvertible {
    /**
    Return a new array of sanitized strings
    
    :returns: Array of strings
    */
    public func sanitize() -> [String]
    {
        let newStrings = self.map( { ($0 as! String).sqiftSanitize() } )
        
        return newStrings
    }
}

