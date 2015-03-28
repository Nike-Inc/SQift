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
        XCTAssertEqual(database.open(enableTracing: true), .Success, "Open failed")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        fiftyRowTableStatement = nil
        XCTAssertEqual(database.close(), .Success, "Close failed, \(database.lastErrorMessage())")
    }
    
    func testSqiftVersion()
    {
        XCTAssertEqual(database.sqiftVersion(), "1.0.0", "Version is incorrect")
    }
    
    func testSQLiteVersion()
    {
        var sqliteVersion = "3.7.13"    // iOS 8.1
        
        if UIDevice.currentDevice().systemVersion == "8.3"
        {
            sqliteVersion = "3.8.5"
        }
        XCTAssertEqual(database.sqlite3Version(), sqliteVersion, "Version is incorrect")
    }
    
    func testResult()
    {
        let result1 = DatabaseResult.Success
        let result2 = DatabaseResult.Success
        let result3 = DatabaseResult.Error("Foo")
        let result4 = DatabaseResult.Error("Bar")
        let result5 = DatabaseResult.Error("Bar")
        let result6 = DatabaseResult.Error(nil)
        
        XCTAssert(result1 == result2, "Compare test failed")
        XCTAssert(result1 != result3, "Compare test failed")
        XCTAssert(result3 != result4, "Compare test failed")
        XCTAssert(result4 == result5, "Compare test failed")
        XCTAssert(result4 == result6, "Compare test failed")
        XCTAssert(result1 != result6, "Compare test failed")
    }
    
    func testSanitize()
    {
        XCTAssert("hello".sqiftSanitize() == "\"hello\"", "Sanitize incorrect")
        XCTAssert("\"hello\"".sqiftSanitize() == "\"\"\"hello\"\"\"", "Sanitize incorrect")
        XCTAssert("he\"llo".sqiftSanitize() == "\"he\"\"llo\"", "Sanitize incorrect")
    }
    
    func testOpen()
    {

    }
    
    func testCreateTable()
    {
        XCTAssertEqual(database.dropTable("table1"), DatabaseResult.Success, "Drop table failed")
        XCTAssertEqual(database.createTable("table1", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B", type: .String)
            ]), DatabaseResult.Success, "Create failed")
    }
    
    func testCreateTableAttack()
    {
        XCTAssertEqual(database.dropTable("table2"), DatabaseResult.Success, "Drop table failed")
        XCTAssertEqual(database.createTable("table2", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B\"; DROP TABLE table1;", type: .String)
            ]), DatabaseResult.Success, "Create failed")
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
        XCTAssert(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');") == DatabaseResult.Success, "Exec failed")
    }
    
    func oneRowTable(_ database: Database? = nil)
    {
        var db = database == nil ? self.database : database!
        XCTAssertEqual(db.dropTable("table1"), DatabaseResult.Success, "Drop table failed")
        XCTAssertEqual(db.createTable("table1", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B", type: .String)
            ]), DatabaseResult.Success, "Create failed")
        XCTAssert(db.executeSQLStatement("DELETE FROM table1;") == DatabaseResult.Success, "Exec failed")
        XCTAssert(db.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');") == DatabaseResult.Success, "Exec failed")
    }
    
    func fiftyRowTable(_ database: Database? = nil)
    {
        var db = database == nil ? self.database : database!
        db.transaction { (db) -> TransactionResult in
            XCTAssertEqual(db.dropTable("table1"), DatabaseResult.Success, "Drop table failed")
            XCTAssertEqual(db.createTable("table1", columns: [
                Column(name: "A", type: .Integer),
                Column(name: "B", type: .String)
                ]), DatabaseResult.Success, "Create failed")
            
            if self.fiftyRowTableStatement == nil
            {
                self.fiftyRowTableStatement = Statement(database: db, sqlStatement: "INSERT INTO table1(A, B) VALUES (?, ?);")
            }
            
            for index in 0 ..< 50
            {
                XCTAssertEqual(self.fiftyRowTableStatement.bindParameters(index, "Bob \(index)"), .Success, "Bind failed")
                XCTAssertEqual(self.fiftyRowTableStatement.step(), .Done, "Step failed")
            }
            return .Commit
        }
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
        while statement.step() == .More
        {
            XCTAssert(statement.columnCount() == 2, "Wrong number of columns")
            XCTAssert(statement[0] as Int32 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as Int64 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as String! == "42", "Column A has incorrect value")
            XCTAssert(statement[0] as Double == 42.0, "Column A has incorrect value")
            XCTAssert(statement[0] as Bool == true, "Column A has incorrect value")
            
            XCTAssert(statement[1] as String! == "Bob", "Column B has incorrect value")
            
            XCTAssert(statement.columnNameForIndex(0) == "A", "Column A has incorrect name")
            XCTAssert(statement.columnNameForIndex(1) == "B", "Column B has incorrect name")
            XCTAssert(statement.columnNameForIndex(2) == nil, "Column X has incorrect name")
            
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
        while statement.step() == .More
        {
            XCTAssert(statement.columnCount() == 2, "Wrong number of columns")
            XCTAssert(statement[0] as Int32 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as Int64 == 42, "Column A has incorrect value")
            XCTAssert(statement[0] as String! == "42", "Column A has incorrect value")
            XCTAssert(statement[0] as Double == 42.0, "Column A has incorrect value")
            XCTAssert(statement[0] as Bool == true, "Column A has incorrect value")
            
            XCTAssert(statement[1] as String! == "Bob", "Column B has incorrect value")
            
            // Column names should be sanitized since they were passed in as parameters
            XCTAssertEqual(statement.columnNameForIndex(0)!, "A".sqiftSanitize(), "Column A has incorrect name")
            XCTAssertEqual(statement.columnNameForIndex(1)!, "B".sqiftSanitize(), "Column B has incorrect name")
            
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
        while statement.step() == .More
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
        while statement.step() == .More
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
        XCTAssertEqual(statement.bindParameters(42), DatabaseResult.Success, "Bind failed")
        var rowCount = 0
        while statement.step() == .More
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
        XCTAssertEqual(statement.bindParameters(42), DatabaseResult.Success, "Bind failed")
        var rowCount = 0
        while statement.step() == .More
        {
            let value = 42 + rowCount
            XCTAssertEqual(statement.columnCount(), 2, "Wrong number of columns")
            XCTAssertEqual(statement[0], value, "Column A has incorrect value")
            XCTAssertEqual(statement[1]!, "Bob \(value)", "Column B has incorrect value")
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
        
        rowCount = 0;
        XCTAssertEqual(statement.bindParameters(43), DatabaseResult.Success, "Bind failed")
        while statement.step() == .More
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
        database.transaction { (database) -> TransactionResult in
            var transactionResult = TransactionResult.Commit
            var result = DatabaseResult.Success
            
            result = database.executeSQLStatement("DELETE FROM table1;")
            XCTAssertEqual(result, .Success, "Exec failed")
            
            if result == .Success
            {
                result = database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');")
                XCTAssertEqual(result, .Success, "Exec failed")
            }
            
            if result != .Success
            {
                transactionResult = .Rollback(result)
            }
            
            return transactionResult
        }

        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1")
        var rowCount = 0
        while statement.step() == .More
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
        while statement.step() == .More
        {
            rowCount++
        }
        XCTAssert(rowCount == 1, "Incorrect number of rows")
        
        database.transaction { (database) -> TransactionResult in
            var transactionResult = TransactionResult.Commit
            
            let result = database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(43, 'Bob 43');")
            XCTAssertEqual(result, .Success, "Exec failed")
            
            transactionResult = TransactionResult.Rollback(DatabaseResult.Error("Fake Error"))
            
            return transactionResult
        }

        statement.reset()
        rowCount = 0
        while statement.step() == .More
        {
            rowCount++
        }
        XCTAssertEqual(rowCount, 1, "Incorrect number of rows")
    }
    
    func testNumberedInsertParameters()
    {
        database.transaction { (database) -> TransactionResult in
            XCTAssert(database.executeSQLStatement("DELETE FROM table1;") == DatabaseResult.Success, "Exec failed")
            
            let statement = Statement(database: database, sqlStatement: "INSERT INTO table1 VALUES (?1, ?2);")
            
            for index in 0 ..< 50
            {
                XCTAssertEqual(statement.bindParameters(index, "Bob \(index)"), .Success, "Bind failed")
                XCTAssertEqual(statement.step(), .Done, "Step failed")
            }
            return .Commit
        }
        
        // Pull back in descending order, just for fun
        let statement = Statement(database: database, table: "table1", columnNames: ["A", "B"], orderByColumnNames: ["A"], ascending: false)
        var rowCount = 50
        while statement.step() == .More
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
        while statement.step() == .More
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
        XCTAssertEqual(database.insertRowIntoTable("table1", values: [ 43, "Row2"]), .Success, "Insert failed")
        var rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable("table1", rowID: rowID, values: [ 43, "Row2"])

    
        // Insert with columns mixed up
        XCTAssertEqual(database.insertRowIntoTable("table1", columns: ["B", "A"], values: [ "Row3", 44 ]), .Success, "Insert failed")
        rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 3, "unexpected row ID")
        
        validateTable("table1", rowID: rowID, values: [ 44, "Row3" ])
    }
    
    func testDeleteRow()
    {
        oneRowTable()
        
        // Insert, no column names
        XCTAssertEqual(database.insertRowIntoTable("table1", values: [ 43, "Row2"]), .Success, "Insert failed")
        var rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable("table1", rowID: rowID, values: [ 43, "Row2"])
        
        // Delete row
        XCTAssertEqual(database.deleteFromTable("table1", whereExpression: "A == ?", values: [ 42 ]), .Success, "Delete failed")
        
        
        // Look for the row
        let statement = Statement(database: database, sqlStatement: "SELECT * FROM table1 WHERE A == ?", parameters: 42)
        
        var rowCount = 0
        while statement.step() == .More
        {
            rowCount++
        }
        
        XCTAssertEqual(rowCount, 0, "Incorrect number of rows")
    }
    
    func testDeleteAllRows()
    {
        fiftyRowTable()
        
        var count: Int64? = nil
        count = database.numberOfRowsInTable("table1")
        XCTAssert(count != nil && count! == 50, "Incorrect row count")
        
        XCTAssertEqual(database.deleteAllRowsFromTable("table1"), .Success, "Delete all failed")
        
        XCTAssertEqual(database.numberOfRowsInTable("table1")!, 0, "Incorrect row count")
        
        XCTAssertEqual(database.dropTable("table1"), .Success, "Drop failed")
        
        XCTAssertEqual(database.numberOfRowsInTable("table1") == nil, true, "Row count should be nil")
    }
    
    func testUpdateRow1()
    {
        oneRowTable()
        
        XCTAssertEqual(database.updateTable("table1", values: [ "A" : 44 ], whereExpression: "A = ?", parameters: 42), .Success, "Update failed")
        
        validateTable("table1", rowID: 1, values: [ 44, "Bob"])
    }

    func testUpdateRow2()
    {
        oneRowTable()
        
        XCTAssertEqual(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 42), .Success, "Update failed")
        
        validateTable("table1", rowID: 1, values: [ 42, "Barfo"])
    }

    func testUpdateRowNoMatch()
    {
        oneRowTable()
        
        XCTAssertEqual(database.updateTable("table1", values: [ "B" : "Barfo" ], whereExpression: "A = ?", parameters: 99), .Success, "Update failed")
        
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testCreateIndex()
    {
        fiftyRowTable()
        
        XCTAssertEqual(database.createIndex("MyIndex", table: "table1", columns: ["A"]), .Success, "Create index failed")
        
        XCTAssertEqual(database.dropIndex("MyIndex"), .Success, "Drop index failed")
        
        XCTAssertEqual(database.dropIndex("MyIndex"), .Success, "Drop index failed")
        
        XCTAssertEqual(database.dropIndex("Foobar"), .Success, "Drop index failed")
    }
    
    func testQueue()
    {
        XCTAssertEqual(database.dropTable("table1"), .Success, "Drop table failed")

        let queue = DatabaseQueue(path: database.path)
        let expect = expectationWithDescription("async")
        
        queue.open()
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
        XCTAssertEqual(database.dropTable("table1"), .Success, "Drop failed")
        
        database.executeInSavepoint("MySavepoint", transaction: { database in
            self.oneRowTable(database)
            return .Commit
        })
        
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testSavepointRollback()
    {
        XCTAssertEqual(database.dropTable("table1"), .Success, "Drop failed")
        
        database.executeInSavepoint("MySavepoint", transaction: { database in
            self.oneRowTable(database)
            return .Rollback(.Error("gave up"))
        })
        
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
    }
    
    func testNestedSavepoint()
    {
        XCTAssertEqual(database.dropTable("table1"), .Success, "Drop failed")
        XCTAssertFalse(database.tableExists("table1"), "Did not rollback")
        
        database.executeInSavepoint("MySavepoint", transaction: { transactionDatabase in
            self.oneRowTable(transactionDatabase)
            
            transactionDatabase.executeInSavepoint("OtherSavepoint", transaction: { superNestedDatabase in
                XCTAssertEqual(superNestedDatabase.dropTable("table1"), .Success, "Drop failed")
                XCTAssertFalse(superNestedDatabase.tableExists("table1"), "Did not rollback")
                return .Rollback(.Error("whatever"))
                })
            return .Commit
        })
        
        XCTAssertTrue(database.tableExists("table1"), "Did not rollback")
        validateTable("table1", rowID: 1, values: [ 42, "Bob"])
    }
    
    func testInsertTrigger()
    {
        oneRowTable(database)
        
        let expectInsert = expectationWithDescription("trigger")
        
        // Add the trigger
        XCTAssertEqual(database.whenTable("table1", changes: .Insert, perform: ("Trigger", { (change, rowid) -> () in
            XCTAssertEqual(change, .Insert, "change type is incorrect")
            XCTAssertEqual(rowid, 2, "rowid is incorrect")
            
            expectInsert.fulfill()
        })), .Success, "Failed to add trigger")
        
        // Action
        XCTAssertEqual(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(45, 'Bob');"), .Success, "Exec failed")
        
        // Wait...
        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            
        })
        
        // Remove
        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
        
        // Action again
        XCTAssertEqual(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(46, 'Bob');"), .Success, "Exec failed")
    }

    func testDeleteTrigger()
    {
        oneRowTable(database)
        
        let expectInsert = expectationWithDescription("trigger")
        
        // Add the trigger
        XCTAssertEqual(database.whenTable("table1", changes: .Delete, perform: ("Trigger", { (change, rowid) -> () in
            XCTAssertEqual(change, .Delete, "change type is incorrect")
            XCTAssertEqual(rowid, 1, "rowid is incorrect")
            expectInsert.fulfill()
        })), .Success, "Failed to add trigger")
        
        // Action
        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
        
        // Wait...
        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            
        })
        
        // Remove
        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
        
        // Action again
        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
    }
    
    func testUpdateTrigger()
    {
        oneRowTable(database)
        
        let expectInsert = expectationWithDescription("trigger")
        
        // Add the trigger
        XCTAssertEqual(database.whenTable("table1", changes: .Update, perform: ("Trigger", { (change, rowid) -> () in
            XCTAssertEqual(change, .Update, "change type is incorrect")
            XCTAssertEqual(rowid, 1, "rowid is incorrect")
            expectInsert.fulfill()
        })), .Success, "Failed to add trigger")
        
        // Action
        XCTAssertEqual(database.executeSQLStatement("UPDATE table1 SET A = 43 WHERE A == 42;"), .Success, "Exec failed")
        
        // Wait...
        waitForExpectationsWithTimeout(1.0, handler: { (error) -> Void in
            
        })
        
        // Remove
        XCTAssertEqual(database.removeClosureWithName("Trigger"), .Success, "Failed to remove trigger")
        
        // Action again
        XCTAssertEqual(database.executeSQLStatement("DELETE FROM table1 WHERE A == 42;"), .Success, "Exec failed")
    }
    
    
}
