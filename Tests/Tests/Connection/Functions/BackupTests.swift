//
//  BackupTests.swift
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

class BackupTestCase: BaseTestCase {

    // MARK: - Properties

    let destinationLocation: StorageLocation = {
        let path = FileManager.cachesDirectory.appending("/backup_tests.db")
        return .onDisk(path)
    }()

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        let dbPath = destinationLocation.path
        let shmPath = dbPath + "-shm"
        let walPath = dbPath + "-wal"

        [dbPath, shmPath, walPath].forEach { FileManager.removeItem(atPath: $0) }
    }

    // MARK: - Tests - Successful Backups

    func testThatConnectionCanBackupToDestination() throws {
        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)
        let destinationConnection = try Connection(storageLocation: destinationLocation)

        let agentCount = 20_000
        try seedDatabase(withAgentCount: agentCount, using: sourceConnection)

        let backupExpectation = expectation(description: "backup should complete successfully")
        let progressExpectation = expectation(description: "progress should be marked as finished")

        var backupResult: Connection.BackupResult?

        // When
        let progress = try sourceConnection.backup(to: destinationConnection, pageSize: 10) { result in
            backupResult = result
            backupExpectation.fulfill()
        }

        var progressValues: [Double] = []

        DispatchQueue.userInitiated.async {
            while !progress.isFinished { progressValues.append(progress.fractionCompleted) ; usleep(10) }
            progressValues.append(progress.fractionCompleted)

            progressExpectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")
        let destinationAgentCount: Int? = try destinationConnection.query("SELECT count(1) FROM agents")

        // Then
        XCTAssertEqual(backupResult?.isSuccess, true)

        XCTAssertTrue(progress.isFinished, "should be finished")
        XCTAssertFalse(progress.isPaused, "should not be paused")
        XCTAssertFalse(progress.isCancelled, "should not be cancelled")

        XCTAssertLessThan(progressValues.first ?? 1.0, 1.0)
        XCTAssertEqual(progressValues.last, 1.0)

        XCTAssertEqual(sourceAgentCount, agentCount)
        XCTAssertEqual(destinationAgentCount, agentCount)
    }

    func testThatConnectionCanBackupToDestinationInOneIteration() throws {
        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)
        let destinationConnection = try Connection(storageLocation: destinationLocation)

        let agentCount = 20_000
        try seedDatabase(withAgentCount: agentCount, using: sourceConnection)

        let backupExpectation = expectation(description: "backup should complete successfully")
        let progressExpectation = expectation(description: "progress should be marked as finished")

        var backupResult: Connection.BackupResult?

        // When
        let progress = try sourceConnection.backup(to: destinationConnection, pageSize: -1) { result in
            backupResult = result
            backupExpectation.fulfill()
        }

        var progressValues: Set<Double> = []

        DispatchQueue.userInitiated.async {
            while !progress.isFinished { progressValues.insert(progress.fractionCompleted) ; usleep(10) }
            progressValues.insert(progress.fractionCompleted)

            progressExpectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")
        let destinationAgentCount: Int? = try destinationConnection.query("SELECT count(1) FROM agents")

        // Then
        XCTAssertEqual(backupResult?.isSuccess, true)

        XCTAssertTrue(progress.isFinished, "should be finished")
        XCTAssertFalse(progress.isPaused, "should not be paused")
        XCTAssertFalse(progress.isCancelled, "should not be cancelled")

        XCTAssertEqual(progressValues.count, 2)
        let sortedProgressValues = progressValues.sorted()
        XCTAssertLessThan(sortedProgressValues.first ?? 1.0, 1.0)
        XCTAssertEqual(sortedProgressValues.last, 1.0)

        XCTAssertEqual(sourceAgentCount, agentCount)
        XCTAssertEqual(destinationAgentCount, agentCount)
    }

    func testThatConnectionCanBackupToDestinationWhileBeingModified() throws {
        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)
        let writerConnection = try Connection(storageLocation: storageLocation)
        let destinationConnection = try Connection(storageLocation: destinationLocation)

        try sourceConnection.execute("PRAGMA journal_mode = WAL")
        try writerConnection.execute("PRAGMA journal_mode = WAL")
        try destinationConnection.execute("PRAGMA journal_mode = WAL")

        let initialAgentCount = 100_000
        try seedDatabase(withAgentCount: initialAgentCount, using: sourceConnection)

        let backupExpectation = expectation(description: "backup should complete successfully")
        let progressExpectation = expectation(description: "progress should be marked as finished")
        let insertionExpectation = expectation(description: "insertion should complete successfully")

        var backupResult: Connection.BackupResult?

        // When
        let progress = try sourceConnection.backup(to: destinationConnection, pageSize: 10) { result in
            backupResult = result
            backupExpectation.fulfill()
        }

        var extraAgentInsertionError: Error?
        let extraAgentCount = 2

        DispatchQueue.utility.async {
            var triggeredInsertion = false

            while !progress.isFinished && !progress.isCancelled {
                let fractionCompleted = progress.fractionCompleted

                if !triggeredInsertion && fractionCompleted > 0.1 {
                    DispatchQueue.userInitiated.async {
                        do {
                            try TestTables.insertDummyAgents(count: extraAgentCount, connection: writerConnection)
                            XCTAssertLessThan(fractionCompleted, 1.0, "Test needs to ensure that the insertion happens while the backup is running")
                            insertionExpectation.fulfill()
                        } catch {
                            extraAgentInsertionError = error
                            insertionExpectation.fulfill()
                        }
                    }

                    triggeredInsertion = true
                }

                usleep(20)
            }

            progressExpectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)

        let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")
        let destinationAgentCount: Int? = try destinationConnection.query("SELECT count(1) FROM agents")

        // Then
        XCTAssertEqual(backupResult?.isSuccess, true)

        XCTAssertTrue(progress.isFinished, "progress was not finished")
        XCTAssertFalse(progress.isPaused, "should not be paused")
        XCTAssertFalse(progress.isCancelled, "should not be cancelled")

        XCTAssertNil(extraAgentInsertionError)

        if !ProcessInfo.isRunningOnCI {
            //======================================================================================================
            //
            // These tests always pass locally and should continue to pass. Unfortunately, we have to disable them
            // on Travis CI because there is no way to get the timing quite right to ensure the backup is actually
            // stopped and restarted. Sometimes, the backup is restarted properly, and sometimes the backup just
            // continues until completion.
            //
            // Christian Noon - 9/21/17
            //
            //======================================================================================================

            XCTAssertEqual(sourceAgentCount, initialAgentCount + extraAgentCount)
            XCTAssertGreaterThanOrEqual(destinationAgentCount ?? 0, initialAgentCount)
        }
    }

    func testThatConnectionCanCancelBackupToDestination() throws {
        // Disable test on CI since timing is too unpredictable
        guard !ProcessInfo.isRunningOnCI else { return }

        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)
        let destinationConnection = try Connection(storageLocation: destinationLocation)

        let agentCount = 20_000
        try seedDatabase(withAgentCount: agentCount, using: sourceConnection)

        let backupExpectation = expectation(description: "backup should complete successfully")
        let progressExpectation = expectation(description: "progress should be marked as finished")

        var backupResult: Connection.BackupResult?

        // When
        let progress = try sourceConnection.backup(to: destinationConnection, pageSize: 10) { result in
            backupResult = result
            backupExpectation.fulfill()
        }
        
        progress.cancel()

        var progressValues: [Double] = []

        DispatchQueue.userInitiated.async {
            while !progress.isCancelled { progressValues.append(progress.fractionCompleted) ; usleep(10) }
            progressValues.append(progress.fractionCompleted)

            progressExpectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")

        // Then
        XCTAssertEqual(backupResult?.isCancelled, true)

        XCTAssertTrue(progress.isCancelled, "should be cancelled")
        XCTAssertFalse(progress.isFinished, "progress should not be finished")
        XCTAssertFalse(progress.isPaused, "should not be paused")

        XCTAssertLessThan(progressValues.last ?? 100, 10.0)

        XCTAssertEqual(sourceAgentCount, agentCount)
    }

    func testThatConnectionCanPauseBackupToDestination() throws {
        // Disable test on CI since timing is too unpredictable
        guard !ProcessInfo.isRunningOnCI else { return }

        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)
        let destinationConnection = try Connection(storageLocation: destinationLocation)

        let agentCount = 20_000
        try seedDatabase(withAgentCount: agentCount, using: sourceConnection)

        let backupExpectation = expectation(description: "backup should complete successfully")
        let progressExpectation = expectation(description: "progress should be marked as finished")

        var backupResult: Connection.BackupResult?

        // When
        let progress = try sourceConnection.backup(to: destinationConnection, pageSize: 10) { result in
            backupResult = result
            backupExpectation.fulfill()
        }

        DispatchQueue.utility.asyncAfter(seconds: 0.0001) { progress.pause() }
        DispatchQueue.utility.asyncAfter(seconds: 0.1) { progress.resume() }

        var progressValues: [Double] = []

        DispatchQueue.userInitiated.async {
            while !progress.isFinished { progressValues.append(progress.fractionCompleted) ; usleep(10) }
            progressValues.append(progress.fractionCompleted)

            progressExpectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")
        let destinationAgentCount: Int? = try destinationConnection.query("SELECT count(1) FROM agents")

        // Then
        XCTAssertEqual(backupResult?.isSuccess, true, "backup was not successful")

        XCTAssertTrue(progress.isFinished, "progress was not finished")
        XCTAssertFalse(progress.isPaused, "should not be paused")
        XCTAssertFalse(progress.isCancelled, "should not be cancelled")

        XCTAssertLessThan(progressValues.first ?? 1.0, 1.0)
        XCTAssertEqual(progressValues.last, 1.0)

        XCTAssertEqual(sourceAgentCount, agentCount)
        XCTAssertEqual(destinationAgentCount, agentCount)
    }

    // MARK: - Tests - Backup Failures

    func testThatConnectionThrowsErrorWhenTryingToBackupToSelf() throws {
        // Given
        let sourceConnection = try Connection(storageLocation: storageLocation)

        let agentCount = 20_000
        try seedDatabase(withAgentCount: agentCount, using: sourceConnection)

        var backupError: Error?

        // When
        do {
            try sourceConnection.backup(to: sourceConnection) { _ in }
        } catch {
            backupError = error
        }

        // Then
        XCTAssertTrue(backupError is SQLiteError)

        if let error = backupError as? SQLiteError {
            XCTAssertEqual(error.code, SQLITE_ERROR)
            XCTAssertEqual(error.message, "source and destination must be distinct")
        }
    }

    // MARK: - Private - Test Helpers

    private func seedDatabase(withAgentCount count: Int, using connection: Connection) throws {
        try TestTables.createAndPopulateAgentsTable(using: connection)
        try connection.execute("DELETE FROM agents")
        try TestTables.insertDummyAgents(count: count, connection: connection)
    }
}
