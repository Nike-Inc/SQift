//
//  TestHelpers.swift
//  sqift
//
//  Created by Dave Camp on 8/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import XCTest
import Foundation
@testable import sqift

var fiftyRowTableStatement: Statement!

func oneRowTable(database: Database)
{
    try!(database.dropTable("table1"))
    try!(database.createTable("table1", columns: [
        Column(name: "A", type: .Integer),
        Column(name: "B", type: .String)
        ]))
    XCTAssert(try!(database.executeSQLStatement("DELETE FROM table1;")) == DatabaseResult.Done, "Exec failed")
    XCTAssert(try!(database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');")) == DatabaseResult.Done, "Exec failed")
}

func fiftyRowTable(database: Database)
{
    try!(database.transaction { (db) -> TransactionResult in
        try!(database.dropTable("table1"))
        try!(database.createTable("table1", columns: [
            Column(name: "A", type: .Integer),
            Column(name: "B", type: .String)
            ]))
        
        if fiftyRowTableStatement == nil
        {
            fiftyRowTableStatement = Statement(database: database, sqlStatement: "INSERT INTO table1(A, B) VALUES (?, ?);")
        }
        
        for index in 0 ..< 50
        {
            try!(fiftyRowTableStatement.bindParameters(index, "Bob \(index)"))
            XCTAssertEqual(try!(fiftyRowTableStatement.step()), DatabaseResult.Done, "Step failed")
        }
        return .Commit
        })
}

func validateTable(database: Database, table: String, rowID: Int64, values: [Any])
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

