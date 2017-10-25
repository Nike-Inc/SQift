//
//  StringExtensionTests.swift
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

class StringExtensionTestCase: BaseTestCase {
    func testThatStringExtensionAddsSQLEscapesAsExpected() {
        // Given
        let strings = [
            "database_name",
            "'",
            "SELECT * FROM table WHERE column = 'column_name'",
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
