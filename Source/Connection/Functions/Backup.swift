//
//  Backup.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQLite3

extension Connection {
    /// Represents the result of a backup operation.
    ///
    /// - success:   The backup operation succeeded.
    /// - failure:   The backup operation failed with the provided error.
    /// - cancelled: The backup operation was cancelled.
    public enum BackupResult {
        case success
        case failure(Error)
        case cancelled

        /// Returns `true` if the backup result is a success, `false` otherwise.
        public var isSuccess: Bool {
            guard case .success = self else { return false }
            return true
        }

        /// Returns `true` if the backup result is a failure, `false` otherwise.
        public var isFailure: Bool {
            guard case .failure = self else { return false }
            return true
        }

        /// Returns `true` if the backup result was cancelled, `false` otherwise.
        public var isCancelled: Bool {
            guard case .cancelled = self else { return false }
            return true
        }
    }

    /// Copies the content of a database attached to the connection into the destination database on the backup queue.
    ///
    /// SQLite holds a write transaction open on the destination database file for the duration of the backup
    /// operation. The source database is read-locked only while it is being read. It is not locked continuously for
    /// the entire backup operation. Thus, the backup may be performed on a live source database without preventing
    /// other database connections from reading or writing to the source database while the backup is underway.
    ///
    /// For more information about database backups, please refer to the
    /// [documentation](https://sqlite.org/c3ref/backup_finish.html).
    ///
    /// - Parameters:
    ///   - sourceName:      The name of the source database. "main" by default.
    ///   - destination:     A connection to the destination database to copy to.
    ///   - destinationName: The name of the destination database. "main" by default.
    ///   - pageSize:        The number of pages to copy between the source and destination databases on each iteration.
    ///   - backupQueue:     The dispatch queue to execute the backup operation on.
    ///   - completionQueue: The dispatch queue to call the completion closure on.
    ///   - completion:      The closure called once the backup operation is complete.
    ///
    /// - Returns: A progress instance that can be used to monitor, pause, and cancel the backup operation.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when initializing the backup operation.
    @discardableResult
    public func backup(
        databaseNamed sourceName: String = "main",
        to destination: Connection,
        as destinationName: String = "main",
        pageSize: Int32 = 100,
        backupQueue: DispatchQueue = .global(qos: .default),
        completionQueue: DispatchQueue = .main,
        completion: @escaping (BackupResult) -> Void)
        throws -> Progress
    {
        guard let backup = sqlite3_backup_init(destination.handle, destinationName, handle, sourceName) else {
            throw SQLiteError(connection: destination)
        }

        let progress = Progress()

        progress.isCancellable = true
        progress.isPausable = true

        backupQueue.async {
            do {
                var result: Int32 = 0

                repeat {
                    guard !progress.isCancelled else {
                        completionQueue.async { completion(.cancelled) }
                        sqlite3_backup_finish(backup) // cleanup and ignore result
                        return
                    }

                    if progress.isPaused {
                        while progress.isPaused { usleep(1000) /** sleep 1 ms */ }
                    }

                    result = try self.check(sqlite3_backup_step(backup, pageSize))

                    let totalPageCount = Int64(sqlite3_backup_pagecount(backup))
                    let completedPageCount = totalPageCount - Int64(sqlite3_backup_remaining(backup))

                    progress.totalUnitCount = totalPageCount
                    progress.completedUnitCount = completedPageCount
                } while result != SQLITE_DONE

                try self.check(sqlite3_backup_finish(backup)) // cleanup but track result

                completionQueue.async { completion(.success) }
            } catch {
                sqlite3_backup_finish(backup) // cleanup and ignore result
                progress.cancel()
                completionQueue.async { completion(.failure(error)) }
            }
        }

        return progress
    }
}
