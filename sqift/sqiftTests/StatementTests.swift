//
//  StatementTests.swift
//  sqift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import XCTest
@testable import sqift

class StatementTests: XCTestCase {

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

    func testStatement()
    {
        oneRowTable(database)
        
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
        oneRowTable(database)
        
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
        oneRowTable(database)
        
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
        fiftyRowTable(database)
        
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
        fiftyRowTable(database)
        
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
        fiftyRowTable(database)
        
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

    func testNumberedInsertParameters()
    {
        try!(database.transaction { (database) -> TransactionResult in
            try!(database.executeSQLStatement("DELETE FROM table1;"))
            
            let statement = Statement(database: database, sqlStatement: "INSERT INTO table1 VALUES (?1, ?2);")
            
            for index in 0 ..< 50
            {
                try!(statement.bindParameters(index, "Bob \(index)"))
                XCTAssertEqual(try!(statement.step()), DatabaseResult.Done, "Step failed")
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
}
