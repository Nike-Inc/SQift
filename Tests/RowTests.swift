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
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            let beneficiary_NSNull: NSNull = row[7]

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
            XCTAssertEqual(beneficiary_NSNull, NSNull())

            XCTAssertEqual(id_Bool, true)

            XCTAssertEqual(id_Int8, 1)
            XCTAssertEqual(id_Int16, 1)
            XCTAssertEqual(id_Int32, 1)
            XCTAssertEqual(id_Int64, 1)
            XCTAssertEqual(id_Int, 1)

            XCTAssertEqual(id_UInt8, 1)
            XCTAssertEqual(id_UInt16, 1)
            XCTAssertEqual(id_UInt32, 1)
            XCTAssertEqual(id_UInt64, 1)
            XCTAssertEqual(id_UInt, 1)

            XCTAssertEqual(salary_Float, 2_500_000.56)
            XCTAssertEqual(salary_Double, 2_500_000.56)

            XCTAssertEqual(name_String, "Sterling Archer")
            XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-10-02T08:20:00.000")!)

            XCTAssertEqual(jobTitle_NSData, "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding))
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
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            let beneficiary_NSNull: NSNull? = row[7]

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
            XCTAssertEqual(beneficiary_NSNull, NSNull())

            XCTAssertEqual(id_Bool, true)

            XCTAssertEqual(id_Int8, 1)
            XCTAssertEqual(id_Int16, 1)
            XCTAssertEqual(id_Int32, 1)
            XCTAssertEqual(id_Int64, 1)
            XCTAssertEqual(id_Int, 1)

            XCTAssertEqual(id_UInt8, 1)
            XCTAssertEqual(id_UInt16, 1)
            XCTAssertEqual(id_UInt32, 1)
            XCTAssertEqual(id_UInt64, 1)
            XCTAssertEqual(id_UInt, 1)

            XCTAssertEqual(salary_Float, 2_500_000.56)
            XCTAssertEqual(salary_Double, 2_500_000.56)

            XCTAssertEqual(name_String, "Sterling Archer")
            XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-10-02T08:20:00.000")!)

            XCTAssertEqual(jobTitle_NSData, "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding))
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
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            let beneficiary_NSNull: NSNull = row["beneficiary"]

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
            XCTAssertEqual(beneficiary_NSNull, NSNull())

            XCTAssertEqual(id_Bool, true)

            XCTAssertEqual(id_Int8, 1)
            XCTAssertEqual(id_Int16, 1)
            XCTAssertEqual(id_Int32, 1)
            XCTAssertEqual(id_Int64, 1)
            XCTAssertEqual(id_Int, 1)

            XCTAssertEqual(id_UInt8, 1)
            XCTAssertEqual(id_UInt16, 1)
            XCTAssertEqual(id_UInt32, 1)
            XCTAssertEqual(id_UInt64, 1)
            XCTAssertEqual(id_UInt, 1)

            XCTAssertEqual(salary_Float, 2_500_000.56)
            XCTAssertEqual(salary_Double, 2_500_000.56)

            XCTAssertEqual(name_String, "Sterling Archer")
            XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-10-02T08:20:00.000")!)

            XCTAssertEqual(jobTitle_NSData, "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding))
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
            let row = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")

            let beneficiary_NSNull: NSNull? = row["beneficiary"]

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
            XCTAssertEqual(beneficiary_NSNull, NSNull())

            XCTAssertEqual(id_Bool, true)

            XCTAssertEqual(id_Int8, 1)
            XCTAssertEqual(id_Int16, 1)
            XCTAssertEqual(id_Int32, 1)
            XCTAssertEqual(id_Int64, 1)
            XCTAssertEqual(id_Int, 1)

            XCTAssertEqual(id_UInt8, 1)
            XCTAssertEqual(id_UInt16, 1)
            XCTAssertEqual(id_UInt32, 1)
            XCTAssertEqual(id_UInt64, 1)
            XCTAssertEqual(id_UInt, 1)

            XCTAssertEqual(salary_Float, 2_500_000.56)
            XCTAssertEqual(salary_Double, 2_500_000.56)

            XCTAssertEqual(name_String, "Sterling Archer")
            XCTAssertEqual(date_NSDate, BindingDateFormatter.dateFromString("2015-10-02T08:20:00.000")!)

            XCTAssertEqual(jobTitle_NSData, "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding))
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
            let values = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'").values

            // Then
            if values.count == 8 {
                XCTAssertTrue(values[0] is Int64, "id column should be extracted as `Int64`")
                XCTAssertTrue(values[1] is String, "name column should be extracted as `Int64`")
                XCTAssertTrue(values[2] is String, "date column should be extracted as `Int64`")
                XCTAssertTrue(values[3] is Int64, "missions column should be extracted as `Int64`")
                XCTAssertTrue(values[4] is Double, "salary column should be extracted as `Int64`")
                XCTAssertTrue(values[5] is NSData, "job_title column should be extracted as `Int64`")
                XCTAssertTrue(values[6] is String, "car column should be extracted as `Int64`")
                XCTAssertTrue(values[7] is NSNull, "beneficiary column should be extracted as `Int64`")
            } else {
                XCTFail("values count should be 8")
            }
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
