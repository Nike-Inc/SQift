//
//  ExpressibleByRowErrorTests.swift
//
//  Copyright (c) 2015-present Nike, Inc. (https://www.nike.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import SQift
import XCTest

class ExpressibleByRowErrorTestCase: BaseConnectionTestCase {
    func testThatExpressibleByRowErrorCanBeConstructedFromRow() {
        do {
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
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
