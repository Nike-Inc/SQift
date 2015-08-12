//
//  sqiftTests.swift
//  sqiftTests
//
//  Created by Dave Camp on 3/7/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import UIKit
import XCTest
import sqift
import Foundation

class sqiftTests: XCTestCase {
    
    var database: Database!
    var fiftyRowTableStatement: Statement!
    
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
    
    func testCreateTable()
    {
        try!(database.dropTable("table1"))
        try!(database.createTable("table1", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B", type: .String)
            ]))
    }
    
    func testCreateTableAttack()
    {
        try!(database.dropTable("table2"))
        try!(database.createTable("table2", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B\"; DROP TABLE table1;", type: .String)
            ]))
    }
    
    func testTableExists()
    {
        oneRowTable()
        XCTAssert(database.tableExists("table1") == true, "Did not find table")
        XCTAssert(database.tableExists("NotHere") == false, "Found non-existant table")
    }
    
    func testStuff()
    {
        oneRowTable()
        XCTAssert(try!(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');")) == DatabaseResult.Done, "Exec failed")
    }
    
    func oneRowTable(database: Database? = nil)
    {
        let db = database == nil ? self.database : database!
        try!(db.dropTable("table1"))
        try!(db.createTable("table1", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B", type: .String)
            ]))
        XCTAssert(try!(db.executeSQLStatement("DELETE FROM table1;")) == DatabaseResult.Done, "Exec failed")
        XCTAssert(try!(db.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');")) == DatabaseResult.Done, "Exec failed")
    }
    
    func fiftyRowTable(database: Database? = nil)
    {
        let db = database == nil ? self.database : database!
        try!(db.transaction { (db) -> TransactionResult in
            try!(db.dropTable("table1"))
            try!(db.createTable("table1", columns: [
                Column(name: "A", type: .Integer),
                Column(name: "B", type: .String)
                ]))
            
            if self.fiftyRowTableStatement == nil
            {
                self.fiftyRowTableStatement = Statement(database: db, sqlStatement: "INSERT INTO table1(A, B) VALUES (?, ?);")
            }
            
            for index in 0 ..< 50
            {
                try!(self.fiftyRowTableStatement.bindParameters(index, "Bob \(index)"))
                XCTAssertEqual(try!(self.fiftyRowTableStatement.step()), .Done, "Step failed")
            }
            return .Commit
        })
    }
    
    func testFiftyRowTable()
    {
        fiftyRowTable()
    }
    
    func testStatement()
    {
        oneRowTable()
        
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1")
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            XCTAssert(statement.columnCount() == 2, "Wrong number of columns")
            XCTAssert(statement[0] as Int32 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as Int64 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as String! == "42", "Column A has incorrect value")
            XCTAssert(statement[0] as Double == 42.0, "Column A has incorrect value")
            XCTAssert(statement[0] as Bool == true, "Column A has incorrect value")
            
            XCTAssert(statement[1] as String! == "Bob", "Column B has incorrect value")
            
            XCTAssert(try!(statement.columnNameForIndex(0)) == "A", "Column A has incorrect name")
            XCTAssert(try!(statement.columnNameForIndex(1)) == "B", "Column B has incorrect name")
            XCTAssert(try!(statement.columnNameForIndex(2)) == nil, "Column X has incorrect name")
            
            XCTAssert(statement.columnTypeForIndex(0) == ColumnType.Integer, "Column A has incorrect type")
            XCTAssert(statement.columnTypeForIndex(1) == ColumnType.String, "Column B has incorrect type")
            XCTAssert(statement.columnTypeForIndex(2) == ColumnType.Null, "Column X has incorrect name")
            rowCount++
        }
        
        XCTAssert(rowCount == 1, "Incorrect number of rows")
   }
    
    func testStatementConvenience()
    {
        oneRowTable()
        
        let statement = Statement(database: database, table: "table1", columnNames: ["A", "B"])
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            XCTAssert(statement.columnCount() == 2, "Wrong number of columns")
            XCTAssert(statement[0] as Int32 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as Int64 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as String! == "42", "Column A has incorrect value")
            XCTAssert(statement[0] as Double == 42.0, "Column A has incorrect value")
            XCTAssert(statement[0] as Bool == true, "Column A has incorrect value")
            
            XCTAssert(statement[1] as String! == "Bob", "Column B has incorrect value")
            
            // Column names should be sanitized since they were passed in as parameters
            XCTAssertEqual(try!(statement.columnNameForIndex(0))!, "A".sqiftSanitize(), "Column A has incorrect name")
            XCTAssertEqual(try!(statement.columnNameForIndex(1))!, "B".sqiftSanitize(), "Column B has incorrect name")
            
            XCTAssert(statement.columnTypeForIndex(0) == ColumnType.Integer, "Column A has incorrect type")
            XCTAssert(statement.columnTypeForIndex(1) == ColumnType.String, "Column B has incorrect type")
            rowCount++
        }
        
        XCTAssert(rowCount == 1, "Incorrect number of rows")
    }
    
    func testStatementConvenienceAttack()
    {
        oneRowTable()
        
        let statement = Statement(database: database, table: "table1", columnNames: ["A", "B\"; DROP TABLE table1;"])
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            rowCount++
        }
        
        XCTAssert(rowCount == 1, "Incorrect number of rows")
    }
    
    func testConvenience2()
    {
        fiftyRowTable()
        
        let statement = Statement(database: database, table: "table1", columnNames: ["A", "B"], orderByColumnNames: ["A"], limit: 25)
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], rowCount, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(rowCount)", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 25, "Incorrect number of rows")
    }
    
    func testParameters()
    {
        fiftyRowTable()
        
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1 WHERE A = ?;")
        try!(statement.bindParameters(42))
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            let value = 42 + rowCount
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], value, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(value)", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
    }
    
    func testMultipleBind()
    {
        fiftyRowTable()
        
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1 WHERE A = ?;")
        try!(statement.bindParameters(42))
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            let value = 42 + rowCount
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], value, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(value)", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
        
        rowCount = 0;
        try!(statement.bindParameters(43))
        while try!(statement.step()) == .More
        {
            let value = 43 + rowCount
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], value, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(value)", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
    }
    
    func testTransaction()
    {
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
        oneRowTable()

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
    
    func testNumberedInsertParameters()
    {
        try!(database.transaction { (database) -> TransactionResult in
            try!(database.executeSQLStatement("DELETE FROM table1;"))
            
            let statement = Statement(database: database, sqlStatement: "INSERT INTO table1 VALUES (?1, ?2);")
            
            for index in 0 ..< 50
            {
                try!(statement.bindParameters(index, "Bob \(index)"))
                XCTAssertEqual(try!(statement.step()), .Done, "Step failed")
            }
            return .Commit
        })
        
        // Pull back in descending order, just for fun
        let statement = Statement(database: database, table: "table1", columnNames: ["A", "B"], orderByColumnNames: ["A"], ascending: false)
        var rowCount = 50
        while try!(statement.step()) == .More
        {
            rowCount--
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], rowCount, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(rowCount)", "Column B has incorrect value")
        }
        
        XCTAssertEqual(rowCount, 0, "Incorrect number of rows")
    }
    
    func testFifityRowTablePerformance() {
        // This is an example of a performance test case.
        measureBlock() {
            for _ in 0 ..< 100
            {
                self.fiftyRowTable()
            }
        }
    }
    
    func validateTable(table: String, rowID: Int64, values: [Any])
    {
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM \(table) WHERE rowid == ?", parameters: rowID)
        
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            XCTAssertEqual(statement.columnCount(), values.count, "Wrong number of columns")
            XCTAssertEqual(statement[0] as String!, "\(values[0])", "Column A has incorrect value")
            XCTAssertEqual(statement[1] as String!, "\(values[1])", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
    }
    
    func testInsertRow()
    {
        oneRowTable()
        
        // Insert, no column names
        try!(database.insertRowIntoTable("table1", values: [ 43, "Row2"]))
        var rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable("table1", rowID: rowID, values: [ 43, "Row2"])

    
        // Insert with columns mixed up
        try!(database.insertRowIntoTable("table1", columns: ["B", "A"], values: [ "Row3", 44 ]))
        rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 3, "unexpected row ID")
        
        validateTable("table1", rowID: rowID, values: [ 44, "Row3" ])
    }
    
    func testDeleteRow()
    {
        oneRowTable()
        
        // Insert, no column names
        try!(database.insertRowIntoTable("table1", values: [ 43, "Row2"]))
        let rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable("table1", rowID: rowID, values: [ 43, "Row2"])
        
        // Delete row
        try!(database.deleteFromTable("table1", whereExpression: "A == ?", values: [ 42 ]))
        
        
        // Look for the row
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1 WHERE A == ?", parameters: 42)
        
        var rowCount = 0
        while try!(statement.step()) == .More
        {
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 0, "Incorrect number of rows")
    }
    
    func testDeleteAllRows()
    {
        fiftyRowTable()
        
        var count: Int64? = nil
        count = try!(database.numberOfRowsInTable("table1"))
        XCTAssert(count != nil && count! == 50, "Incorrect row count")
        
        try!(database.deleteAllRowsFromTable("table1"))
        
        XCTAssertEqual(try!(database.numberOfRowsInTable("table1"))!, 0, "Incorrect row count")
        
        try!(database.dropTable("table1"))
        
        do {
            try(database.numberOfRowsInTable("table1"))
            XCTAssert(false, "Should have thrown an error")
        } catch {
            
        }
    }
    
    func testUpdateRow1()
    {
        oneRowTable()
        
        try!(database.updateTable("table1", values: [ "A" : 44 ], whereExpression: "A = ?", parameters: 42))
        
        validateTable("table1", rowID: 1, values: [ 44, "Bob"])
    }

    func testUpdateRow2()
    {
        oneRowTable()
        
        try!(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 42))
        
        validateTable("table1", rowID: 1, values: [ 42, "Barfo"])
    }

    func testUpdateRowNoMatch()
    {
        oneRowTable()
        
        try!(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 99))
        
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testCreateIndex()
    {
        fiftyRowTable()
        
        try!(database.createIndex("MyIndex", table: "table1", columns: ["A"]))
        try!(database.dropIndex("MyIndex"))
        try!(database.dropIndex("MyIndex"))
        try!(database.dropIndex("Foobar"))
    }
    
    func testQueue()
    {
        try!(database.dropTable("table1"))

        let queue = DatabaseQueue(path: database.path)
        let expect = expectationWithDescription("async")
        
        try!(queue.open())
        queue.execute( { transactionDatabase in
            XCTAssert(self.database !== transactionDatabase, "incorrect database")
            self.oneRowTable(transactionDatabase)
            expect.fulfill()
        })
        
        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            
        })
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testSavepointCommit()
    {
        try!(database.dropTable("table1"))
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { database in
            self.oneRowTable(database)
            return .Commit
        }))
        
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testSavepointRollback()
    {
        try!(database.dropTable("table1"))
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { database in
            self.oneRowTable(database)
            return .Rollback
        }))
        
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
    }
    
    func testNestedSavepoint()
    {
        try!(database.dropTable("table1"))
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
        
        try!(database.executeInSavepoint("MySavepoint", transaction: { transactionDatabase in
            self.oneRowTable(transactionDatabase)
            
            try!(transactionDatabase.executeInSavepoint("OtherSavepoint", transaction: { superNestedDatabase in
                try!(superNestedDatabase.dropTable("table1"))
                XCTAssertFalse(superNestedDatabase.tableExists("table1"), "Did not rollback")
                return .Rollback
                }))
            return .Commit
        }))
        
        XCTAssertTrue(database.tableExists("table1"), "Did not rollback")
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
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
