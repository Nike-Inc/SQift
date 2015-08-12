//
//  DatabaseTests.swift
//  sqift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 thinbits. All rights reserved.
//

import XCTest
import Foundation
@testable import sqift

class DatabaseTests: XCTestCase {
    
    var database: Database!
    
    override func setUp() {
        super.setUp()
        
        database = Database("/tmp/sqift.db")
        try!(database.open())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        fiftyRowTableStatement = nil
        try!(database.close())
    }
    
    func testSqiftVersion()
    {
        XCTAssertEqual(database.sqiftVersion(), "1.0.0", "Version is incorrect")
    }
    
    func testSanitize()
    {
        XCTAssert("hello".sqiftSanitize() == "\"hello\"", "Sanitize incorrect")
        XCTAssert("\"hello\"".sqiftSanitize() == "\"\"\"hello\"\"\"", "Sanitize incorrect")
        XCTAssert("he\"llo".sqiftSanitize() == "\"he\"\"llo\"", "Sanitize incorrect")
    }
    
    func testOneRowTable()
    {
        oneRowTable(database)
        XCTAssert(try!(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');")) == DatabaseResult.Done, "Exec failed")
    }
    
    func testFiftyRowTable()
    {
        fiftyRowTable(database)
    }
    
    func testFifityRowTablePerformance() {
        // This is an example of a performance test case.
        measureBlock() {
            for _ in 0 ..< 100
            {
                fiftyRowTable(self.database)
            }
        }
    }
    
    func testTransaction()
    {
        oneRowTable(database)
        
        try!(database.transaction { database in
            var transactionResult = TransactionResult.Commit
            
            do {
                try(database.executeSQLStatement("DELETE FROM table1;"))
                try(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');"))
            }
            catch {
                transactionResult = .Rollback
            }
            
            return transactionResult
            })
        
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1")
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            rowCount++
        }
        XCTAssert(rowCount == 1, "Incorrect number of rows")
    }
    
    func testTransactionFail()
    {
        oneRowTable(database)
        
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1")
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            rowCount++
        }
        XCTAssert(rowCount == 1, "Incorrect number of rows")
        
        try!(database.transaction { database in
            var transactionResult = TransactionResult.Commit
            
            try!(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(43, 'Bob 43');"))
            
            transactionResult = TransactionResult.Rollback
            
            return transactionResult
            })
        
        try!(statement.reset())
        rowCount = 0
        while try!(statement.step()) == .More
        {
            rowCount++
        }
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
    }
    
    func testSavepointCommit()
    {
        try!(database.dropTable("table1"))
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { database in
            oneRowTable(database)
            return .Commit
        }))
        
        validateTable(database, table: "table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testSavepointRollback()
    {
        try!(database.dropTable("table1"))
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { database in
            oneRowTable(database)
            return .Rollback
        }))
        
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
    }
    
    func testNestedSavepoint()
    {
        try!(database.dropTable("table1"))
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { transactionDatabase in
            oneRowTable(transactionDatabase)
            
            try!(transactionDatabase.executeInSavepoint("OtherSavepoint", transaction: { superNestedDatabase in
                try!(superNestedDatabase.dropTable("table1"))
                XCTAssertFalse(superNestedDatabase.tableExists("table1"), "Did not rollback")
                return .Rollback
            }))
            return .Commit
        }))
        
        XCTAssertTrue(database.tableExists("table1"), "Did not rollback")
        validateTable(database, table: "table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testUpdateRow1()
    {
        oneRowTable(database)
        
        try!(database.updateTable("table1", values: [ "A" : 44 ], whereExpression: "A = ?", parameters: 42))
        
        validateTable(database, table: "table1", rowID: 1, values: [ 44, "Bob"])
    }
    
    func testUpdateRow2()
    {
        oneRowTable(database)
        
        try!(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 42))
        
        validateTable(database, table: "table1", rowID: 1, values: [ 42, "Barfo"])
    }
    
    func testUpdateRowNoMatch()
    {
        oneRowTable(database)
        
        try!(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 99))
        
        validateTable(database, table: "table1", rowID: 1, values: [ 42, "Bob"])
    }
    
}
