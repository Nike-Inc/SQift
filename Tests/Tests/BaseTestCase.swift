//
//  BaseTestCase.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import SQLite3
import XCTest

class BaseTestCase: XCTestCase {

    // MARK: - Properties

    let timeout: TimeInterval = 10.0

    let storageLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/sqift_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        let dbPath = storageLocation.path
        let shmPath = dbPath + "-shm"
        let walPath = dbPath + "-wal"

        [dbPath, shmPath, walPath].forEach { FileManager.removeItem(atPath: $0) }
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
