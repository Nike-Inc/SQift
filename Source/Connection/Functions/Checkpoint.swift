//
//  Checkpoint.swift
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

    // MARK: - Helper Types

    /// Represents all the different modes for executing a checkpoint operation against a WAL database.
    ///
    /// - passive:  Checkpoint as many frames as possible without waiting for any database readers or writers to
    ///             finish, then sync the database file if all frames in the log were checkpointed. The busy-handler
    ///             callback is never invoked in the `.passive` mode. On the other hand, passive mode might leave the
    ///             checkpoint unfinished if there are concurrent readers or writers.
    ///
    /// - full:     This mode blocks (it invokes the busy-handler callback) until there is no database writer and all
    ///             readers are reading from the most recent database snapshot. It then checkpoints all frames in the
    ///             log file and syncs the database file. This mode blocks new database writers while it is pending,
    ///             but new database readers are allowed to continue unimpeded.
    ///
    /// - restart:  This mode works the same way as `.full` with the addition that after checkpointing the log file it
    ///             blocks (calls the busy-handler callback) until all readers are reading from the database file only.
    ///             This ensures that the next writer will restart the log file from the beginning. Like `.full`, this
    ///             mode blocks new database writer attempts while it is pending, but does not impede readers.
    ///
    /// - truncate: This mode works the same way as `.restart` with the addition that it also truncates the log file to
    ///             zero bytes just prior to a successful return.
    public enum CheckpointMode {
        /// Do as much as possible without blocking.
        case passive

        /// Wait for writers, then checkpoint.
        case full

        /// Like `.full`, but wait for readers.
        case restart

        /// Like `.restart`, but also truncate WAL file.
        case truncate

        var rawValue: Int32 {
            switch self {
            case .passive:  return SQLITE_CHECKPOINT_PASSIVE
            case .full:     return SQLITE_CHECKPOINT_FULL
            case .restart:  return SQLITE_CHECKPOINT_RESTART
            case .truncate: return SQLITE_CHECKPOINT_TRUNCATE
            }
        }
    }

    /// Represents the result of a checkpoint operation on a WAL database.
    public struct CheckpointResult {
        /// The number of frames in the WAL log file.
        public let logFrames: Int

        /// The number of frames moved from the WAL log file into the database.
        public let checkpointedFrames: Int
    }

    // MARK: - Checkpoint

    /// Runs a checkpoint operation on the database with the specified mode.
    ///
    /// - Parameters:
    ///   - name: The name of the attached database to checkpoint. `main` by default. Passing `nil` will attempt to
    ///           run the checkpoint operation on all WAL databases attached to the connection.
    ///   - mode: The mode to use when running the checkpoint operation.
    ///
    /// - Returns: The result of the checkpoint operation.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error when running the checkpoint operation. Generally, the
    ///           encountered error will be `SQLITE_BUSY` if a long read operation is being run on a different
    ///           connection. Implementing the busy handler and timeout can help address this issue.
    public func checkpoint(
        attachedDatabaseName name: String? = "main",
        mode: CheckpointMode = .truncate)
        throws -> CheckpointResult
    {
        var logFrames: Int32 = -10
        var checkpointFrames: Int32 = -10

        try check(sqlite3_wal_checkpoint_v2(handle, name, mode.rawValue, &logFrames, &checkpointFrames))

        return CheckpointResult(logFrames: Int(logFrames), checkpointedFrames: Int(checkpointFrames))
    }
}
