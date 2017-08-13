//
//  BaseTestCase.swift
//  SQift
//
//  Created by Christian Noon on 8/13/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class BaseTestCase: XCTestCase {

    // MARK: - Properties

    let timeout: TimeInterval = 4.0

    let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/sqift_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        FileManager.removeItem(atPath: storageLocation.path)
    }
}

// MARK: -

class BaseConnectionTestCase: BaseTestCase {

    // MARK: - Properties

    var connection: Connection!

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
        connection = nil
        super.tearDown()
    }
}
