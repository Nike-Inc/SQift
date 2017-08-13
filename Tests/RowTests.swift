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
    private let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/connection_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func tearDown() {
        super.tearDown()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Tests

    func testThatAllNonOptionalBindingTypesCanBeAccessedByColumnIndexSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            if let row = try connection.query("SELECT * FROM agents WHERE name='Lana Kane'") {
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
                let date_Date: Date = row[2]

                let jobTitle_Data: Data = row[5]

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
                XCTAssertEqual(date_Date, bindingDateFormatter.date(from: "2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_Data, "Top Agent".data(using: .utf8))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatAllOptionalBindingTypesCanBeAccessedByColumnIndexSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            if let row = try connection.query("SELECT * FROM agents WHERE name='Lana Kane'") {
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

                let missions_Int8: Int8? = row[3]
                let missions_Int16: Int16? = row[3]
                let missions_Int32: Int32? = row[3]
                let missions_Int64: Int64? = row[3]
                let missions_Int: Int? = row[3]

                let missions_UInt8: UInt8? = row[3]
                let missions_UInt16: UInt16? = row[3]
                let missions_UInt32: UInt32? = row[3]
                let missions_UInt64: UInt64? = row[3]
                let missions_UInt: UInt? = row[3]

                let salary_Float: Float? = row[4]
                let salary_Double: Double? = row[4]

                let name_String: String? = row[1]
                let date_Date: Date? = row[2]

                let jobTitle_Data: Data? = row[5]

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

                XCTAssertEqual(missions_Int8, nil)
                XCTAssertEqual(missions_Int16, 2_315)
                XCTAssertEqual(missions_Int32, 2_315)
                XCTAssertEqual(missions_Int64, 2_315)
                XCTAssertEqual(missions_Int, 2_315)

                XCTAssertEqual(missions_UInt8, nil)
                XCTAssertEqual(missions_UInt16, 2_315)
                XCTAssertEqual(missions_UInt32, 2_315)
                XCTAssertEqual(missions_UInt64, 2_315)
                XCTAssertEqual(missions_UInt, 2_315)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_Date, bindingDateFormatter.date(from: "2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_Data, "Top Agent".data(using: .utf8))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatAllNonOptionalBindingTypesCanBeAccessedByColumnNameSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            if let row = try connection.query("SELECT * FROM agents WHERE name='Lana Kane'") {
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
                let date_Date: Date = row["date"]

                let jobTitle_Data: Data = row["job_title"]

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
                XCTAssertEqual(date_Date, bindingDateFormatter.date(from: "2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_Data, "Top Agent".data(using: .utf8))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatAllOptionalBindingTypesCanBeAccessedByColumnNameSubscript() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            if let row = try connection.query("SELECT * FROM agents WHERE name='Lana Kane'") {
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

                let missions_Int8: Int8? = row["missions"]
                let missions_Int16: Int16? = row["missions"]
                let missions_Int32: Int32? = row["missions"]
                let missions_Int64: Int64? = row["missions"]
                let missions_Int: Int? = row["missions"]

                let missions_UInt8: UInt8? = row["missions"]
                let missions_UInt16: UInt16? = row["missions"]
                let missions_UInt32: UInt32? = row["missions"]
                let missions_UInt64: UInt64? = row["missions"]
                let missions_UInt: UInt? = row["missions"]

                let salary_Float: Float? = row["salary"]
                let salary_Double: Double? = row["salary"]

                let name_String: String? = row["name"]
                let date_Date: Date? = row["date"]

                let jobTitle_Data: Data? = row["job_title"]

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

                XCTAssertEqual(missions_Int8, nil)
                XCTAssertEqual(missions_Int16, 2_315)
                XCTAssertEqual(missions_Int32, 2_315)
                XCTAssertEqual(missions_Int64, 2_315)
                XCTAssertEqual(missions_Int, 2_315)

                XCTAssertEqual(missions_UInt8, nil)
                XCTAssertEqual(missions_UInt16, 2_315)
                XCTAssertEqual(missions_UInt32, 2_315)
                XCTAssertEqual(missions_UInt64, 2_315)
                XCTAssertEqual(missions_UInt, 2_315)

                XCTAssertEqual(salary_Float, 9_600_200.11)
                XCTAssertEqual(salary_Double, 9_600_200.11)

                XCTAssertEqual(name_String, "Lana Kane")
                XCTAssertEqual(date_Date, bindingDateFormatter.date(from: "2015-11-06T08:00:00.000")!)

                XCTAssertEqual(jobTitle_Data, "Top Agent".data(using: .utf8))
            } else {
                XCTFail("row should not be nil")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatAllDatabaseTypesCanBeAccessedThroughValuesProperty() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            // When
            if
                let values = try connection.query("SELECT * FROM agents WHERE name='Lana Kane'")?.values,
                values.count == 7
            {
                // Then
                XCTAssertTrue(values[0] is Int64, "id column should be extracted as `Int64`")
                XCTAssertTrue(values[1] is String, "name column should be extracted as `Int64`")
                XCTAssertTrue(values[2] is String, "date column should be extracted as `Int64`")
                XCTAssertTrue(values[3] is Int64, "missions column should be extracted as `Int64`")
                XCTAssertTrue(values[4] is Double, "salary column should be extracted as `Int64`")
                XCTAssertTrue(values[5] is Data, "job_title column should be extracted as `Int64`")
                XCTAssertNil(values[6], "car column should be extracted as `nil`")
            } else {
                XCTFail("values should not be nil and should have a count of 7")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
