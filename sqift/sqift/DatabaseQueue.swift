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
    let completionQueue: dispatch_queue_t
    
    /**
    Create a database queue
    
    :param: path            Path to database file
    :param: completionQueue Queue use for completion closures. Default is main queue.
    
    :returns: DatabaseQueue
    */
    public init(path: String, completionQueue: dispatch_queue_t? = nil)
    {
        self.database = Database(path)
        self.transactionQueue = dispatch_queue_create("com.thinbits.database.queue", DISPATCH_QUEUE_SERIAL)
        
        if let completionQueue = completionQueue
        {
            self.completionQueue = completionQueue
        }
        else
        {
            self.completionQueue = dispatch_get_main_queue()
        }
    }
    
    public init(database: Database, completionQueue: dispatch_queue_t? = nil)
    {
        self.database = Database(database.path)
        self.transactionQueue = dispatch_queue_create("com.thinbits.database.queue", DISPATCH_QUEUE_SERIAL)
        
        if let completionQueue = completionQueue
        {
            self.completionQueue = completionQueue
        }
        else
        {
            self.completionQueue = dispatch_get_main_queue()
        }
    }
    
    deinit
    {
        database.close()
    }
    
    /**
    Asynchronously execute a closure on this database queue.
    
    :param: transaction Closure to execute on the queue.
    :param: completion  Closure to execute when transaction is complete. Optional.
    */
    public func transaction(transaction: (database: Database) -> TransactionResult, completion: ((DatabaseResult) -> ())? = nil)
    {
        let openResult = database.open()
        if openResult == .Success
        {
            dispatch_async(transactionQueue, { () -> Void in
                var transactionResult = self.database.transaction(transaction)
                if let completion = completion
                {
                    dispatch_async(self.completionQueue, { () -> Void in
                        completion(transactionResult)
                    })
                }
            })
        }
        else
        {
            if let completion = completion
            {
                dispatch_async(self.completionQueue, { () -> Void in
                    completion(openResult)
                })
            }
        }
    }
}