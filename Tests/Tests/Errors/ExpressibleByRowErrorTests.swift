//
//  ExpressibleByRowErrorTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import XCTest

class ExpressibleByRowErrorTestCase: BaseConnectionTestCase {
    func testThatExpressibleByRowErrorCanBeConstructedFromRow() throws {
        // Given
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
    }
}
