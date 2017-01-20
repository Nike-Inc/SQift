//
//  QueryTests.swift
//  SQift
//
//  Created by Christian Noon on 11/12/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class QueryTestCase: XCTestCase {
    var connection: Connection!

    let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/query_tests.db")
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

    func testThatConnectionCanQueryRowsMatchingExactText() {
        do {
            // Given, When
            let exactCount: Int = try connection.query("SELECT count(*) FROM agents WHERE name='Sterling Archer'")
            let exactBool: Bool = try connection.query("SELECT count(*) FROM agents WHERE name='Sterling Archer'")

            let partialCount: Int64 = try connection.query("SELECT count(*) FROM agents WHERE name='Sterling'")
            let partialBool: Bool = try connection.query("SELECT count(*) FROM agents WHERE name='Sterling'")

            // Then
            XCTAssertEqual(exactCount, 1, "exact count should be 1")
            XCTAssertTrue(exactBool, "exact bool should be true")

            XCTAssertEqual(partialCount, 0, "partial count should be 0")
            XCTAssertFalse(partialBool, "partial bool should be false")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryRowsContainingText() {
        do {
            // Given, When
            let likeCount: Int8 = try connection.query("SELECT count(*) FROM agents WHERE name LIKE '%Kane%'")
            let likeBool: Bool = try connection.query("SELECT count(*) FROM agents WHERE name LIKE '%Kane%'")

            let instrCount: Int16 = try connection.query("SELECT count(*) FROM agents WHERE instr(name, 'Kane') > 0")
            let instrBool: Bool = try connection.query("SELECT count(*) FROM agents WHERE instr(name, 'Kane') > 0")

            // Then
            XCTAssertEqual(likeCount, 1, "like count should be 1")
            XCTAssertTrue(likeBool, "like bool should be true")

            XCTAssertEqual(instrCount, 1, "instr count should be 1")
            XCTAssertTrue(instrBool, "instr bool should be true")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryRowsWithinIntegerRange() {
        do {
            // Given, When
            let belowSalaryCount: UInt8 = try connection.query("SELECT count(*) FROM agents WHERE salary < 3000000.12")
            let aboveSalaryCount: UInt16 = try connection.query("SELECT count(*) FROM agents WHERE salary >= 1000000")

            // Then
            XCTAssertEqual(belowSalaryCount, 1, "below salary count should be 1")
            XCTAssertEqual(aboveSalaryCount, 2, "above salary count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryRowsWithinRealRange() {
        do {
            // Given, When
            let belowMissionsCount: UInt = try connection.query("SELECT count(*) FROM agents WHERE missions <= 485")
            let aboveMissionsCount: UInt64 = try connection.query("SELECT count(*) FROM agents WHERE salary >= 486")

            // Then
            XCTAssertEqual(belowMissionsCount, 1, "below missions count should be 1")
            XCTAssertEqual(aboveMissionsCount, 2, "above missions count should be 1")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryRowsWithinDateRange() {
        do {
            // Given
            let calendar = Calendar.current

            let firstOfOctober: String = {
                var comps = DateComponents()
                comps.year = 2015
                comps.month = 10
                comps.day = 1

                return BindingDateFormatter.string(from: calendar.date(from: comps)!)
            }()

            let endOfOctober: String = {
                var comps = DateComponents()
                comps.year = 2015
                comps.month = 10
                comps.day = 31

                return BindingDateFormatter.string(from: calendar.date(from: comps)!)
            }()

            let endOfNovember: String = {
                var comps = DateComponents()
                comps.year = 2015
                comps.month = 11
                comps.day = 30

                return BindingDateFormatter.string(from: calendar.date(from: comps)!)
            }()

            // When
            let hiredInOctoberCount: UInt = try connection.query(
                "SELECT count(*) FROM agents WHERE date >= date(?) AND date <= date(?)",
                firstOfOctober,
                endOfOctober
            )

            let hiredInOctoberOrNovemberCount: UInt64 = try connection.query(
                "SELECT count(*) FROM agents WHERE date >= date(?) AND date <= date(?)",
                [firstOfOctober, endOfNovember]
            )

            // Then
            XCTAssertEqual(hiredInOctoberCount, 1, "hired in october count should be 1")
            XCTAssertEqual(hiredInOctoberOrNovemberCount, 2, "hired in october or november count should be 2")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryRowsMatchingBlobData() {
        do {
            // Given, When
            let archersJobTitleData: Data = try connection.query("SELECT job_title FROM agents WHERE name='Sterling Archer'")
            let lanasJobTitleData: Data = try connection.query("SELECT job_title FROM agents WHERE name='Lana Kane'")

            let archersJobTitle = String(data: archersJobTitleData, encoding: .utf8)
            let lanasJobTitle = String(data: lanasJobTitleData, encoding: .utf8)

            // Then
            XCTAssertEqual(archersJobTitle, "The world's greatest secret agent", "archers job title should match")
            XCTAssertEqual(lanasJobTitle, "Top Agent", "lanas job title should match")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanSafelyQueryRowsWithNullValues() {
        do {
            // Given, When
            let archersCar: String? = try connection.fetch("SELECT * FROM agents WHERE name='Sterling Archer'")?["car"]
            let lanasCar: String? = try connection.fetch("SELECT * FROM agents WHERE name='Lana Kane'")?["car"]

            // Then
            XCTAssertEqual(archersCar, "Charger", "archers car should be 'Charger'")
            XCTAssertEqual(lanasCar, nil, "lanas car should be nil")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryPRAGMAValues() {
        do {
            // Given, When
            let synchronous: Int = try connection.query("PRAGMA synchronous")
            let journalMode: String = try connection.query("PRAGMA journal_mode")

            // Then
            XCTAssertEqual(synchronous, 2, "synchronous PRAGMA should be 2")
            XCTAssertEqual(journalMode, "delete", "journal_mode PRAGMA should be 'delete'")
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }

    func testThatConnectionCanQueryValuesUsingAllParameterBindingVariants() {
        do {
            // Given, When
            let count1: Int = try connection.query("SELECT count(1) FROM agents WHERE name='Sterling Archer'")
            let count2: Int = try connection.query("SELECT count(1) FROM agents WHERE name=?", "Sterling Archer")
            let count3: Int = try connection.query("SELECT count(1) FROM agents WHERE name=?", ["Sterling Archer"])
            let count4: Int = try connection.query("SELECT count(1) FROM agents WHERE name=:name", [":name": "Sterling Archer"])

            // Then
            XCTAssertEqual(count1, 1)
            XCTAssertEqual(count2, 1)
            XCTAssertEqual(count3, 1)
            XCTAssertEqual(count4, 1)
        } catch {
            XCTFail("Test Encountered Unexpected Error: \(error)")
        }
    }
}
