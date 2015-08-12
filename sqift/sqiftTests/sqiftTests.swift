//
//  sqiftTests.swift
//  sqiftTests
//
//  Created by Dave Camp on 3/7/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import XCTest
import Foundation
@testable import sqift

class sqiftTests: XCTestCase {
    
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
    
//    func testInsertTrigger()
//    {
//        oneRowTable(database)
//        
//        let expectInsert = expectationWithDescription("trigger")
//        
//        // Add the trigger
//        XCTAssertEqual(database.whenTable("table1", changes: .Insert, perform: ("Trigger", { (change, rowid) -> () in
//            XCTAssertEqual(change, .Insert, "change type is incorrect")
//            XCTAssertEqual(rowid, 2, "rowid is incorrect")
//            
//            expectInsert.fulfill()
//        })), .Success, "Failed to add trigger")
//        
//        // Action
//        XCTAssertEqual(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(45, 'Bob');"), .Success, "Exec failed")
//        
//        // Wait...
//        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
//            
//        })
//        
//        // Remove
//        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
//        
//        // Action again
//        XCTAssertEqual(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(46, 'Bob');"), .Success, "Exec failed")
//    }

//    func testDeleteTrigger()
//    {
//        oneRowTable(database)
//        
//        let expectInsert = expectationWithDescription("trigger")
//        
//        // Add the trigger
//        XCTAssertEqual(database.whenTable("table1", changes: .Delete, perform: ("Trigger", { (change, rowid) -> () in
//            XCTAssertEqual(change, .Delete, "change type is incorrect")
//            XCTAssertEqual(rowid, 1, "rowid is incorrect")
//            expectInsert.fulfill()
//        })), .Success, "Failed to add trigger")
//        
//        // Action
//        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
//        
//        // Wait...
//        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
//            
//        })
//        
//        // Remove
//        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
//        
//        // Action again
//        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
//    }
    
//    func testUpdateTrigger()
//    {
//        oneRowTable(database)
//        
//        let expectInsert = expectationWithDescription("trigger")
//        
//        // Add the trigger
//        XCTAssertEqual(database.whenTable("table1", changes: .Update, perform: ("Trigger", { (change, rowid) -> () in
//            XCTAssertEqual(change, .Update, "change type is incorrect")
//            XCTAssertEqual(rowid, 1, "rowid is incorrect")
//            expectInsert.fulfill()
//        })), .Success, "Failed to add trigger")
//        
//        // Action
//        XCTAssertEqual(database.executeSQLStatement("UPDATE table1 SET A = 43 WHERE A == 42;"), .Success, "Exec failed")
//        
//        // Wait...
//        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
//            
//        })
//        
//        // Remove
//        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
//        
//        // Action again
//        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
//    }
    
//    func testInsertTriggerOnQueue()
//    {
//        let expectInsert = self.expectationWithDescription("trigger")
//        let queue = DatabaseQueue(path: database.path)
//        queue.open()
//        queue.execute { (database) -> () in
//            self.oneRowTable(database)
//            
//            // Add the trigger
//            XCTAssertEqual(database.whenTable("table1", changes: .Insert, perform: ("Trigger", { (change, rowid) -> () in
//                XCTAssertEqual(change, .Insert, "change type is incorrect")
//                XCTAssertEqual(rowid, 2, "rowid is incorrect")
//                XCTAssertNotEqual(NSThread.mainThread(), NSThread.currentThread(), "Should not be running on main thread")
//                expectInsert.fulfill()
//            })), .Success, "Failed to add trigger")
//            
//            // Action
//            XCTAssertEqual(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(45, 'Bob');"), .Success, "Exec failed")
//        }
//        
//        // Wait...
//        self.waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
//            
//        })
//    }
}
