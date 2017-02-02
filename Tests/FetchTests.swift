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
    var connection: Connection!

    let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/fetch_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        do {
            connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)
        } catch {
            // No-op
        }
    }

    override func tearDown() {
        super.tearDown()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Tests

    func testThatConnectionCanFetchFirstRowForSelectStatement() {
        do {
            // Given, When
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            // Then
            if
                let name: String = row?["name"],
                let date: Date = row?["date"],
                let missions: Int = row?["missions"],
                let salary: Float = row?["salary"],
                let jobTitle: Data = row?["job_title"],
                let car: String = row?["car"]
            {
                XCTAssertEqual(name, "Sterling Archer")
                XCTAssertEqual(date, bindingDateFormatter.date(from: "2015-10-02T08:20:00.000"))
                XCTAssertEqual(missions, 485)
                XCTAssertEqual(salary, 2_500_000.56)
                XCTAssertEqual(String(data: jobTitle, encoding: .utf8), "The world's greatest secret agent")
                XCTAssertEqual(car, "Charger")
            } else {
                XCTFail("name, date, missions, salary, job_title, car should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanFetchRowForSelectStatementUsingAllParameterBindingVariants() {
        do {
            // Given, When
            let values1 = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")?.values ?? []
            let values2 = try connection.fetch("SELECT * FROM agents WHERE name=?", "Sterling Archer")?.values ?? []
            let values3 = try connection.fetch("SELECT * FROM agents WHERE name=?", ["Sterling Archer"])?.values ?? []
            let values4 = try connection.fetch("SELECT * FROM agents WHERE name=:name", [":name": "Sterling Archer"])?.values ?? []

            // Then
            XCTAssertEqual(values1.count, 7)
            XCTAssertEqual(values2.count, 7)
            XCTAssertEqual(values3.count, 7)
            XCTAssertEqual(values4.count, 7)

            if values1.count == 7 && values2.count == 7 && values3.count == 7 && values4.count == 7 {
                [values1, values2, values3, values4].forEach { values in
                    XCTAssertEqual(values[0] as? Int64, 1)
                    XCTAssertEqual(values[1] as? String, "Sterling Archer")
                    XCTAssertEqual(values[2] as? String, "2015-10-02T08:20:00.000")
                    XCTAssertEqual(values[3] as? Int64, 485)
                    XCTAssertEqual(values[4] as? Double, 2_500_000.56)
                    XCTAssertEqual(String(data: values[5] as! Data, encoding: .utf8), "The world's greatest secret agent")
                    XCTAssertEqual(values[6] as? String, "Charger")
                }
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionDoesNotFetchRowWhenNoRowIsFound() {
        do {
            // Given, When
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Cyril Figgis'")

            // Then
            XCTAssertNil(row)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanIterateThroughAllRowsForSelectStatement() {
        do {
            // Given
            var rows: [[Any?]] = []

            // When
            for row in try connection.prepare("SELECT * FROM agents") {
                rows.append(row.values)
            }

            // Then
            if rows.count == 2 {
                XCTAssertEqual(rows[0][0] as? Int64, 1)
                XCTAssertEqual(rows[0][1] as? String, "Sterling Archer")
                XCTAssertEqual(rows[0][2] as? String, "2015-10-02T08:20:00.000")
                XCTAssertEqual(rows[0][3] as? Int64, 485)
                XCTAssertEqual(rows[0][4] as? Double, 2_500_000.56)
                XCTAssertEqual(rows[0][5] as? Data, "The world's greatest secret agent".data(using: .utf8))
                XCTAssertEqual(rows[0][6] as? String, "Charger")

                XCTAssertEqual(rows[1][0] as? Int64, 2)
                XCTAssertEqual(rows[1][1] as? String, "Lana Kane")
                XCTAssertEqual(rows[1][2] as? String, "2015-11-06T08:00:00.000")
                XCTAssertEqual(rows[1][3] as? Int64, 2_315)
                XCTAssertEqual(rows[1][4] as? Double, 9_600_200.11)
                XCTAssertEqual(rows[1][5] as? Data, "Top Agent".data(using: .utf8))
                XCTAssertEqual(rows[1][6] as? String, nil)
            } else {
                XCTFail("rows count should be 2")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
