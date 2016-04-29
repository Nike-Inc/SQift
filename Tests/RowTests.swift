//
//  RowTests.swift
//  SQift
//
//  Created by Christian Noon on 11/18/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class RowTestCase: XCTestCase {
    let storageLocation: StorageLocation = {
        let path = NSFileManager.cachesDirectory.stringByAppendingString("/connection_tests.db")
        return .OnDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        NSFileManager.removeItemAtPath(storageLocation.path)
    }

    // MARK: - Tests

    func testThatAllNonOptionalBindingTypesCanBeAccessedByColumnIndexSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(connection)

            // When
            if let row = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'") {
                let id_Bool: Bool = row[0]

                let id_Int8: Int8 = row[0]
                let id_Int16: Int16 = row[0]
                let id_Int32: Int32 = row[0]
                let id_Int64: Int64 = row[0]
                let id_Int: Int = row[0]

                let id_UInt8: UInt8 = row[0]
                let id_UInt16: UInt16 = row[0]
                let id_UInt32: UInt32 = row[0]
                let id_UInt64: UInt64 = row[0]
                let id_UInt: UInt = row[0]

                let salary_Float: Float = row[4]
                let salary_Double: Double = row[4]

                let name_String: String = row[1]
                let date_NSDate: NSDate = row[2]

                let jobTitle_NSData: NSData = row[5]

                // Then
                XCTAssertEqual(id_Bool, true)

                XCTAssertEqual(id_Int8, 2)
                XCTAssertEqual(id_Int16, 2)
                XCTAssertEqual(id_Int32, 2)
                XCTAssertEqual(id_Int64, 2)
                XCTAssertEqual(id_Int, 2)

                XCTAssertEqual(id_UInt8, 2)
                XCTAssertEqual(id_UInt16, 2)
                XCTAssertEqual(id_UInt32, 2)
                XCTAssertEqual(id_UInt64, 2)
                XCTAssertEqual(id_UInt, 2)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_NSData, "Top Agent".dataUsingEncoding(NSUTF8StringEncoding))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatAllOptionalBindingTypesCanBeAccessedByColumnIndexSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(connection)

            // When
            if let row = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'") {
                let id_Bool: Bool? = row[0]

                let id_Int8: Int8? = row[0]
                let id_Int16: Int16? = row[0]
                let id_Int32: Int32? = row[0]
                let id_Int64: Int64? = row[0]
                let id_Int: Int? = row[0]

                let id_UInt8: UInt8? = row[0]
                let id_UInt16: UInt16? = row[0]
                let id_UInt32: UInt32? = row[0]
                let id_UInt64: UInt64? = row[0]
                let id_UInt: UInt? = row[0]

                let salary_Float: Float? = row[4]
                let salary_Double: Double? = row[4]

                let name_String: String? = row[1]
                let date_NSDate: NSDate? = row[2]

                let jobTitle_NSData: NSData? = row[5]

                // Then
                XCTAssertEqual(id_Bool, true)

                XCTAssertEqual(id_Int8, 2)
                XCTAssertEqual(id_Int16, 2)
                XCTAssertEqual(id_Int32, 2)
                XCTAssertEqual(id_Int64, 2)
                XCTAssertEqual(id_Int, 2)

                XCTAssertEqual(id_UInt8, 2)
                XCTAssertEqual(id_UInt16, 2)
                XCTAssertEqual(id_UInt32, 2)
                XCTAssertEqual(id_UInt64, 2)
                XCTAssertEqual(id_UInt, 2)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_NSData, "Top Agent".dataUsingEncoding(NSUTF8StringEncoding))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatAllNonOptionalBindingTypesCanBeAccessedByColumnNameSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(connection)

            // When
            if let row = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'") {
                let id_Bool: Bool = row["id"]

                let id_Int8: Int8 = row["id"]
                let id_Int16: Int16 = row["id"]
                let id_Int32: Int32 = row["id"]
                let id_Int64: Int64 = row["id"]
                let id_Int: Int = row["id"]

                let id_UInt8: UInt8 = row["id"]
                let id_UInt16: UInt16 = row["id"]
                let id_UInt32: UInt32 = row["id"]
                let id_UInt64: UInt64 = row["id"]
                let id_UInt: UInt = row["id"]

                let salary_Float: Float = row["salary"]
                let salary_Double: Double = row["salary"]

                let name_String: String = row["name"]
                let date_NSDate: NSDate = row["date"]

                let jobTitle_NSData: NSData = row["job_title"]

                // Then
                XCTAssertEqual(id_Bool, true)

                XCTAssertEqual(id_Int8, 2)
                XCTAssertEqual(id_Int16, 2)
                XCTAssertEqual(id_Int32, 2)
                XCTAssertEqual(id_Int64, 2)
                XCTAssertEqual(id_Int, 2)

                XCTAssertEqual(id_UInt8, 2)
                XCTAssertEqual(id_UInt16, 2)
                XCTAssertEqual(id_UInt32, 2)
                XCTAssertEqual(id_UInt64, 2)
                XCTAssertEqual(id_UInt, 2)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_NSData, "Top Agent".dataUsingEncoding(NSUTF8StringEncoding))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatAllOptionalBindingTypesCanBeAccessedByColumnNameSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(connection)

            // When
            if let row = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'") {
                let id_Bool: Bool? = row["id"]

                let id_Int8: Int8? = row["id"]
                let id_Int16: Int16? = row["id"]
                let id_Int32: Int32? = row["id"]
                let id_Int64: Int64? = row["id"]
                let id_Int: Int? = row["id"]

                let id_UInt8: UInt8? = row["id"]
                let id_UInt16: UInt16? = row["id"]
                let id_UInt32: UInt32? = row["id"]
                let id_UInt64: UInt64? = row["id"]
                let id_UInt: UInt? = row["id"]

                let salary_Float: Float? = row["salary"]
                let salary_Double: Double? = row["salary"]

                let name_String: String? = row["name"]
                let date_NSDate: NSDate? = row["date"]

                let jobTitle_NSData: NSData? = row["job_title"]

                // Then
                XCTAssertEqual(id_Bool, true)

                XCTAssertEqual(id_Int8, 2)
                XCTAssertEqual(id_Int16, 2)
                XCTAssertEqual(id_Int32, 2)
                XCTAssertEqual(id_Int64, 2)
                XCTAssertEqual(id_Int, 2)

                XCTAssertEqual(id_UInt8, 2)
                XCTAssertEqual(id_UInt16, 2)
                XCTAssertEqual(id_UInt32, 2)
                XCTAssertEqual(id_UInt64, 2)
                XCTAssertEqual(id_UInt, 2)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_NSData, "Top Agent".dataUsingEncoding(NSUTF8StringEncoding))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatAllDatabaseTypesCanBeAccessedThroughValuesProperty() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(connection)

            // When
            if let values = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'")?.values where values.count == 7 {
                // Then
                XCTAssertTrue(values[0] is Int64, "id column should be extracted as `Int64`")
                XCTAssertTrue(values[1] is String, "name column should be extracted as `Int64`")
                XCTAssertTrue(values[2] is String, "date column should be extracted as `Int64`")
                XCTAssertTrue(values[3] is Int64, "missions column should be extracted as `Int64`")
                XCTAssertTrue(values[4] is Double, "salary column should be extracted as `Int64`")
                XCTAssertTrue(values[5] is NSData, "job_title column should be extracted as `Int64`")
                XCTAssertNil(values[6], "car column should be extracted as `nil`")
            } else {
                XCTFail("values should not be nil and should have a count of 7")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
