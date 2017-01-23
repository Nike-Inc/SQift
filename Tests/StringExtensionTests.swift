//
//  StringExtensionTests.swift
//  SQift
//
//  Created by Christian Noon on 1/23/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class StringExtensionTestCase: XCTestCase {
    func testThatStringExtensionAddsSQLEscapesAsExpected() {
        // Given
        let strings = [
            "database_name",
            "'",
            "SELECT * FROM table WHERE column = 'column_name'", // TODO, figure out why we only escape the beginning
            "SELECT * FROM table WHERE column = 'column_'_name'"
        ]

        // When
        let results = strings.map { $0.sqift.addingSQLEscapes() }

        // Then
        XCTAssertEqual(results[0], "'database_name'")
        XCTAssertEqual(results[1], "''''")
        XCTAssertEqual(results[2], "'SELECT * FROM table WHERE column = ''column_name'''")
        XCTAssertEqual(results[3], "'SELECT * FROM table WHERE column = ''column_''_name'''")
    }
}
