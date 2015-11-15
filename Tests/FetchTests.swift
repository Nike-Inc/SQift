//
//  SQiftTests.swift
//  SQift
//
//  Created by Christian Noon on 11/12/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class FetchTestCase: XCTestCase {
    var database: Database!

    let databaseType: Database.DatabaseType = {
        let path = NSFileManager.documentsDirectory.stringByAppendingString("/fetch_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        do {
            database = try Database(databaseType: databaseType)
            try TestTables.createAndPopulateAgentsTableInDatabase(database)
        } catch {
            // No-op
        }
    }

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(databaseType.path)
    }

    // MARK: - Tests

    func testThatDatabaseCanFetchFirstRowForSelectStatement() {
        do {
            // Given, When
            let row = try database.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            // Then
            if let
                name: String = row["name"],
                date: NSDate = row["date"],
                missions: Int = row["missions"],
                salary: Float = row["salary"],
                jobTitle: NSData = row["job_title"],
                car: String = row["car"]
            {
                XCTAssertEqual(name, "Sterling Archer")
                XCTAssertEqual(date, BindingDateFormatter.dateFromString("2015-10-02T08:20:00.000"))
                XCTAssertEqual(missions, 485)
                XCTAssertEqual(salary, 2_500_000.56)
                XCTAssertEqual(String(data: jobTitle, encoding: NSUTF8StringEncoding), "The world's greatest secret agent")
                XCTAssertEqual(car, "Charger")
            } else {
                XCTFail("name, date, missions, salary, job_title, car should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanFetchFirstRowForSelectStatementEvenWhenSelectFailsToFindAnyRows() {
        do {
            // Given, When
            let rowValues = try database.fetch("SELECT * FROM agents WHERE name='Does Not Exist'").values

            // Then
            XCTAssertEqual(rowValues.count, 7, "row values count should be 7")

            for (index, rowValue) in rowValues.enumerate() {
                XCTAssertNil(rowValue, "row value at index \(index) should be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatFetchFirstRowOnDatabaseReturnsAllNilValuesWhenNoRowsAreFoundInSelectStatement() {
        do {
            // Given, When
            let rowValues = try database.fetch("SELECT * FROM agents WHERE name='Does Not Exist'").values

            // Then
            XCTAssertEqual(rowValues.count, 7, "row values count should be 7")

            for (index, rowValue) in rowValues.enumerate() {
                XCTAssertNil(rowValue, "row value at index \(index) should be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatDatabaseCanIterateThroughAllRowsForSelectStatement() {
        do {
            // Given
            var rows: [[Any?]] = []

            // When
            for row in try database.prepare("SELECT * FROM agents") {
                rows.append(row.values)
            }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1)
                XCTAssertEqual(rows[0][1] as? String, "Sterling Archer")
                XCTAssertEqual(rows[0][2] as? String, "2015-10-02T08:20:00.000")
                XCTAssertEqual(rows[0][3] as? Int64, 485)
                XCTAssertEqual(rows[0][4] as? Double, 2_500_000.56)
                XCTAssertEqual(rows[0][5] as? NSData, "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding))
                XCTAssertEqual(rows[0][6] as? String, "Charger")

                XCTAssertEqual(rows[1][0] as? Int64, 2)
                XCTAssertEqual(rows[1][1] as? String, "Lana Kane")
                XCTAssertEqual(rows[1][2] as? String, "2015-11-06T08:00:00.000")
                XCTAssertEqual(rows[1][3] as? Int64, 2_315)
                XCTAssertEqual(rows[1][4] as? Double, 9_600_200.11)
                XCTAssertEqual(rows[1][5] as? NSData, "Top Agent".dataUsingEncoding(NSUTF8StringEncoding))
                XCTAssertEqual(rows[1][6] as? String, nil)
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
