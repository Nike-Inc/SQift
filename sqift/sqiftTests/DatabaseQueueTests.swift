//
//  DatabaseQueueTests.swift
//  sqift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 thinbits. All rights reserved.
//

import XCTest
@testable import sqift

class DatabaseQueueTests: XCTestCase {

    var database: Database!
    
    override func setUp() {
        super.setUp()
        
        database = Database("/Users/dave/Desktop/sqift.db")
        try!(database.open())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        fiftyRowTableStatement = nil
        try!(database.close())
    }

    func testQueue()
    {
        try!(database.dropTable("table1"))
        
        let queue = DatabaseQueue(path: database.path)
        let expect = expectationWithDescription("async")
        
        try!(queue.open())
        queue.execute( { transactionDatabase in
            XCTAssert(self.database !== transactionDatabase, "incorrect database")
            oneRowTable(transactionDatabase)
            expect.fulfill()
        })
        
        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            
        })
        validateTable(database, table: "table1", rowID: 1, values: [ 42, "Bob"])
    }
    
}
