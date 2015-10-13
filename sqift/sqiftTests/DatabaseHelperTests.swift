//
//  DatabaseHelperTests.swift
//  sqift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import XCTest
import Foundation
@testable import sqift

class DatabaseHelperTests: XCTestCase {

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
        oneRowTable(database)
        XCTAssert(database.tableExists("table1") == true, "Did not find table")
        XCTAssert(database.tableExists("NotHere") == false, "Found non-existant table")
    }
    
    func testInsertRow()
    {
        oneRowTable(database)
        
        // Insert, no column names
        try!(database.insertRowIntoTable("table1", values: [ 43, "Row2"]))
        var rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable(database, table: "table1", rowID: rowID, values: [ 43, "Row2"])
        
        
        // Insert with columns mixed up
        try!(database.insertRowIntoTable("table1", columns: ["B", "A"], values: [ "Row3", 44 ]))
        rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 3, "unexpected row ID")
        
        validateTable(database, table: "table1", rowID: rowID, values: [ 44, "Row3" ])
    }
    
    func testDeleteRow()
    {
        oneRowTable(database)
        
        // Insert, no column names
        try!(database.insertRowIntoTable("table1", values: [ 43, "Row2"]))
        let rowID = database.lastRowInserted()
        XCTAssertEqual(rowID, 2, "unexpected row ID")
        validateTable(database, table: "table1", rowID: rowID, values: [ 43, "Row2"])
        
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
        fiftyRowTable(database)
        
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
    
    func testCreateIndex()
    {
        fiftyRowTable(database)
        
        try!(database.createIndex("MyIndex", table: "table1", columns: ["A"]))
        try!(database.dropIndex("MyIndex"))
        try!(database.dropIndex("MyIndex"))
        try!(database.dropIndex("Foobar"))
    }
    
}
