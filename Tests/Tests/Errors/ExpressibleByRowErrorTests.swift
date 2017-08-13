//
//  ExpressibleByRowErrorTests.swift
//  SQift
//
//  Created by Christian Noon on 8/12/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class ExpressibleByRowErrorTestCase: XCTestCase {

    // MARK: - Properties

    private let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/expressible_by_row_error_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        FileManager.removeItem(atPath: storageLocation.path)
    }

    // MARK: - Tests

    func testThatExpressibleByRowErrorCanBeConstructedFromRow() {
        do {
            // Given
            let connection = try Connection(storageLocation: storageLocation)
            try TestTables.createAndPopulateAgentsTable(using: connection)

            var error: ExpressibleByRowError?

            // When
            if let row = try connection.query("SELECT name, missions FROM agents WHERE name='Lana Kane'") {
                error = ExpressibleByRowError(type: Agent.self, row: row)
            }

            // Then
            XCTAssertTrue(error?.type is Agent.Type)
            XCTAssertEqual(error?.columns.count, 2)

            let expectedDescription = "ExpressibleByRowError: Failed to initialize Agent from Row with columns: " +
                "[{ index: 0 name: \"name\", type: \"text\", value: Lana Kane }, " +
            "{ index: 1 name: \"missions\", type: \"integer\", value: 2315 }]"

            let expectedErrorDescription = "Failed to initialize Agent from Row with columns: " +
                "[{ index: 0 name: \"name\", type: \"text\", value: Lana Kane }, " +
            "{ index: 1 name: \"missions\", type: \"integer\", value: 2315 }]"

            let expectedFailureReason = "Agent could not be initialized from Row with columns: " +
                "[{ index: 0 name: \"name\", type: \"text\", value: Lana Kane }, " +
            "{ index: 1 name: \"missions\", type: \"integer\", value: 2315 }]"

            XCTAssertEqual(error?.description, expectedDescription)
            XCTAssertEqual(error?.errorDescription, expectedErrorDescription)
            XCTAssertEqual(error?.failureReason, expectedFailureReason)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
