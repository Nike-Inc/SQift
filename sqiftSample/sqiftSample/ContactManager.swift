//
//  ContactManager.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/23/15.
//  Copyright (c) 2015 Nike. All rights reserved.
//

import Foundation
import sqift

public class ContactManager
{
    public typealias PeopleClosure = ([Person]?, NSError?) -> ()
    
    var databaseQueue: DatabaseQueue? = nil

    public func openDatabaseAtPath(path: String) throws
    {
        databaseQueue = DatabaseQueue(path: path)
        try(databaseQueue?.open())
    }
    
    public func allContacts(completion: PeopleClosure)
    {
        databaseQueue?.execute({ database in
            // Query
            let statement = Statement(database: database, table: Person.tableName, orderByColumnNames: ["lastName"], ascending: true)
            
            var finalClosure: dispatch_block_t!
            do {
                let people = try(statement.objectsForRows(Person))
                finalClosure = { completion(people, nil) }
            } catch let error as DatabaseError {
                finalClosure = { completion(nil, error.nserror()) }
            } catch {
                finalClosure = { completion(nil, nil) }
            }
            dispatch_async(dispatch_get_main_queue(), finalClosure)
        })
    }
    
    public func contactsInZipcode(zipcode: Int, completion: PeopleClosure)
    {
        databaseQueue?.execute({ (database) -> () in
            let statement = Statement(database: database, objectClass: Person.self, whereExpression: "zipcode == ?", parameters: zipcode)

            var finalClosure: dispatch_block_t!
            do {
                let people = try(statement.objectsForRows(Person))
                finalClosure = { completion(people, nil) }
            } catch let error as DatabaseError {
                finalClosure = { completion(nil, error.nserror()) }
            } catch {
                finalClosure = { completion(nil, nil) }
            }
            dispatch_async(dispatch_get_main_queue(), finalClosure)
        })
    }
    
    public func addPeople(people: [Person], completion: (NSError?) -> Void)
    {
        databaseQueue?.execute({ database in
            var finalClosure: dispatch_block_t!
            do {
                // Perform a transaction
                try(database.transaction( { database in
                    
                    for person in people
                    {
                        try(database.insertRowIntoTable(Person.self, person))
                    }
                    return .Commit
                }))
                finalClosure = { completion(nil) }
            } catch let error as DatabaseError {
                finalClosure = { completion(error.nserror()) }
            } catch {
                finalClosure = { completion(nil) }
            }
            dispatch_async(dispatch_get_main_queue(), finalClosure)
        })
    }

    public func insertSampleData(completion: (NSError?) -> Void)
    {
        databaseQueue?.execute({ database in
            do {
                if database.tableExists(Person.self) == false
                {
                    try(database.createTable(Person))
                }
                
                if try database.numberOfRowsInTable(Person.self) == 0 {
                    let people = [
                        Person(firstName: "Bob", lastName: "Smith", address: "123 Anywhere", zipcode: 97229),
                        Person(firstName: "Jane", lastName: "Doe", address: "111 Blahville", zipcode: 97006)
                    ]
                    
                    self.addPeople(people, completion: { (result) -> Void in
                        completion(result)
                    })
                }
            } catch let error as DatabaseError {
                completion(error.nserror())
            } catch {
                completion(nil)
            }
        })
    }
}