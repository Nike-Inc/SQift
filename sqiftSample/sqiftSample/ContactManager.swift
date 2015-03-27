//
//  ContactManager.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/23/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation
import sqift

public class ContactManager
{
    public typealias PeopleClosure = ([Person]) -> ()
    
    var databaseQueue: DatabaseQueue? = nil

    public func openDatabaseAtPath(path: String)
    {
        databaseQueue = DatabaseQueue(path: path)
        databaseQueue?.open()
        insertSampleData()
    }
    
    public func allContacts(completion: PeopleClosure)
    {
        databaseQueue?.execute({ database in
            // Query
            let statement = Statement(database: database, table: Person.tableName, orderByColumnNames: ["lastName"], ascending: true)
            
            var people = statement.objectsForRows(Person)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(people)
            })
        })
    }
    
    public func contactsInZipcode(zipcode: Int, completion: PeopleClosure)
    {
        databaseQueue?.execute({ (database) -> () in
            let statement = Statement(database: database, objectClass: Person.self, whereExpression: "zipcode == ?", parameters: zipcode)
            var people = statement.objectsForRows(Person)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(people)
            })
        })
    }

    func insertSampleData()
    {
        databaseQueue?.execute({ database in
            var addData = database.tableExists(Person.tableName) == false || database.numberOfRowsInTable(Person.tableName) == 0
            
            if addData
            {
                let people = [
                    Person(firstName: "Bob", lastName: "Smith", address: "123 Anywhere", zipcode: 97229),
                    Person(firstName: "Jane", lastName: "Doe", address: "111 Blahville", zipcode: 97006)
                ]
                
                // Perform a transaction
                database.transaction( { database in
                    
                    var result = database.createTable(Person)
                    
                    if result == .Success
                    {
                        for person in people
                        {
                            result = database.insertRowIntoTable(Person.self, person)
                            if result != .Success
                            {
                                break
                            }
                        }
                    }
                    return .Commit
                })
            }
        })
    }
}