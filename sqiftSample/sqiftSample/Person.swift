//
//  Person.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/22/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

public struct Person : CustomStringConvertible, CustomDebugStringConvertible
{
    public let firstName: String
    public let lastName: String
    public let address: String
    public let zipcode: Int
    
    public var description: String { return "\(firstName) \(lastName), \(address), \(zipcode)" }
    public var debugDescription: String { return "\(firstName) \(lastName), \(address), \(zipcode)" }
}

