//
//  DatabaseQueue.swift
//  sqift
//
//  Created by Dave Camp on 3/21/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import Foundation

public class DatabaseQueue
{
    let database: Database
    let transactionQueue: dispatch_queue_t
    
    /**
    Create a database queue
    
    :param: path:            Path to database file
    
    :returns: DatabaseQueue
    */
    public init(path: String)
    {
        self.database = Database(path)
        self.transactionQueue = dispatch_queue_create("com.thinbits.sqift.queue", DISPATCH_QUEUE_SERIAL)
    }
    
    deinit
    {
        do {
            try(database.close())
        }
        catch {
            
        }
    }
    
    /**
    Open a connection to the database
    */
    public func open() throws
    {
        try(database.open())
    }
    
    
    /**
    Close the connection to the database
    */
    public func close() throws
    {
        try(database.close())
    }
    
    /**
    Asynchronously execute a closure on this database queue.
    
    :param: closure: Closure to execute on the queue.
    */
    public func execute(closure: (database: Database) -> ())
    {
        assert(database.isOpen, "Database is not open")
        dispatch_async(transactionQueue, { () -> Void in
            closure(database: self.database)
        })
    }
}