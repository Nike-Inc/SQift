//
//  BackupTests.swift
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

    func testThatConnectionCanBackupToDestination() {
        do {
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

            XCTAssertEqual(progress.isFinished, true)
            XCTAssertEqual(progress.isPaused, false)
            XCTAssertEqual(progress.isCancelled, false)

            XCTAssertEqual(progressValues.first, 0.0)
            XCTAssertEqual(progressValues.last, 1.0)

            XCTAssertEqual(sourceAgentCount, agentCount)
            XCTAssertEqual(destinationAgentCount, agentCount)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanBackupToDestinationInOneIteration() {
        do {
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

            XCTAssertEqual(progress.isFinished, true)
            XCTAssertEqual(progress.isPaused, false)
            XCTAssertEqual(progress.isCancelled, false)

            XCTAssertEqual(progressValues.count, 2)
            let sortedProgressValues = progressValues.sorted()
            XCTAssertEqual(sortedProgressValues.first, 0.0)
            XCTAssertEqual(sortedProgressValues.last, 1.0)

            XCTAssertEqual(sourceAgentCount, agentCount)
            XCTAssertEqual(destinationAgentCount, agentCount)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanBackupToDestinationWhileBeingModified() {
        do {
            // Given
            let sourceConnection = try Connection(storageLocation: storageLocation)
            let destinationConnection = try Connection(storageLocation: destinationLocation)

            try sourceConnection.execute("PRAGMA journal_mode = WAL")
            try destinationConnection.execute("PRAGMA journal_mode = WAL")

            let initialAgentCount = 1_000
            try seedDatabase(withAgentCount: initialAgentCount, using: sourceConnection)

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

            let extraAgentCount = 2
            try TestTables.insertDummyAgents(count: extraAgentCount, connection: sourceConnection)

            waitForExpectations(timeout: timeout, handler: nil)

            let sourceAgentCount: Int? = try sourceConnection.query("SELECT count(1) FROM agents")
            let destinationAgentCount: Int? = try destinationConnection.query("SELECT count(1) FROM agents")

            // Then
            XCTAssertEqual(backupResult?.isSuccess, true)

            XCTAssertEqual(progress.isFinished, true)
            XCTAssertEqual(progress.isPaused, false)
            XCTAssertEqual(progress.isCancelled, false)

            XCTAssertEqual(progressValues.first, 0.0)
            XCTAssertEqual(progressValues.last, 1.0)

            XCTAssertEqual(sourceAgentCount, initialAgentCount + extraAgentCount)
            XCTAssertEqual(destinationAgentCount, initialAgentCount + extraAgentCount)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCancelBackupToDestination() {
        do {
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

            XCTAssertEqual(progress.isFinished, false)
            XCTAssertEqual(progress.isPaused, false)
            XCTAssertEqual(progress.isCancelled, true)

            XCTAssertEqual(progressValues.first, 0.0)
            XCTAssertLessThan(progressValues.last ?? 100, 1.0)

            XCTAssertEqual(sourceAgentCount, agentCount)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanPauseBackupToDestination() {
        do {
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
            XCTAssertEqual(backupResult?.isSuccess, true)

            XCTAssertEqual(progress.isFinished, true)
            XCTAssertEqual(progress.isPaused, false)
            XCTAssertEqual(progress.isCancelled, false)

            XCTAssertLessThan(progressValues.first ?? 1.0, 1.0)
            XCTAssertEqual(progressValues.last, 1.0)

            XCTAssertEqual(sourceAgentCount, agentCount)
            XCTAssertEqual(destinationAgentCount, agentCount)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    // MARK: - Tests - Backup Failures

    func testThatConnectionThrowsErrorWhenTryingToBackupToSelf() {
        do {
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
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    // MARK: - Private - Test Helpers

    private func seedDatabase(withAgentCount count: Int, using connection: Connection) throws {
        try TestTables.createAndPopulateAgentsTable(using: connection)
        try connection.execute("DELETE FROM agents")
        try TestTables.insertDummyAgents(count: count, connection: connection)
    }
}
