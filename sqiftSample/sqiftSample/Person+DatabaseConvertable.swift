//
//  Person+DatabaseConvertable.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/23/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation
import sqift

extension Person : DatabaseConvertable
{
    public static var tableName: String { get { return "people" } }
    
    public static var columnDefinitions: [Column]
        {
        get
    {
        return [
            Column(name: "firstName", type: .String),
            Column(name: "lastName", type: .String),
            Column(name: "address", type: .String),
            Column(name: "zipcode", type: .Integer)
        ]
        }
    }
    
    public var columnValues: [Any]
        {
        get
        {
            return [
                firstName,
                lastName,
                address,
                zipcode
            ]
        }
    }
    
    public static func objectFromStatement(statement: Statement) -> DatabaseConvertable?
    {
        var object: Person? = nil
        
        // Make sure columns and types are correct
        var valid = statement.validateColumnsForObject(Person.self)
        
        if valid
        {
            // Make sure we have valid data
            if let firstName = statement[0] as String?,
                let lastName = statement[1] as String?,
                let address = statement[2] as String?
            {
                let zipcode = statement[3] as Int
                object = Person(firstName: firstName, lastName: lastName, address: address, zipcode: zipcode)
            }
            else
            {
                valid = false
            }
        }
        
        assert(valid, "Unable to construct Person object from statement columns")
        
        return object
    }
}

