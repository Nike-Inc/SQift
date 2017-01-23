//
//  Migrator.swift
//  SQift
//
//  Created by Christian Noon on 11/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `Migrator` class handles data migrations between schema versions for an attached database connection.
/// The migrations MUST be numerically ordered by integers starting by 1, and incrementing by one each 
/// migration. i.e. [1, 2, 3, 4, etc.].
public class Migrator {

    // MARK: - Properties

    /// The desired schema version of the attached database connection the migrator will attempt to update to when run.
    public let desiredSchemaVersion: UInt64

    /// The current schema version of the attached database connection.
    public var currentSchemaVersion: UInt64 {
        var version: UInt64 = 0

        do {
            if let tableVersion: UInt64 = try connection.query("SELECT MAX(version) FROM \(Migrator.MigrationTableName)") {
                version = tableVersion
            }
        } catch {
            // No-op
        }

        return version
    }

    /// Whether a migration is required to update the attached database connection to the desired schema version.
    public var migrationRequired: Bool { return currentSchemaVersion < desiredSchemaVersion }

    var migrationsTableExists: Bool {
        var exists = false

        do {
            exists = try connection.query(
                "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                "table",
                Migrator.MigrationTableName
            )
        } catch {
            // No-op
        }

        return exists
    }

    let connection: Connection

    private static let MigrationTableName = "schema_migrations"

    // MARK: - Initialization

    /// Creates a `Migrator` instance with the specified database connection and desired schema version.
    ///
    /// - Parameters:
    ///   - connection:           The database connection to attach to the migrator.
    ///   - desiredSchemaVersion: The desired schema version the migrator will use when run.
    public init(connection: Connection, desiredSchemaVersion: UInt64) {
        self.connection = connection
        self.desiredSchemaVersion = desiredSchemaVersion
    }

    // MARK: - Run Migrations

    /// Runs all migrations sequentially until the desired schema version is reached.
    ///
    /// The SQL necessary to run the migration is lazily requested by the `migrationSQLForSchemaVersion` closure. It is
    /// important to note that each version MUST start at one and increment by one each version. i.e. [1, 2, 3, etc.].
    ///
    /// - Parameters:
    ///   - migrationSQL: A closure requesting the migration SQL for a required schema version.
    ///   - willMigrate:  A closure executed before running the migration for the specified schema version.
    ///   - didMigrate:   A closure executed after running the migration for the specified schema version.
    ///
    /// - Returns: The total number of migrations completed.
    ///
    /// - Throws: A `SQLiteError` if any migration encounters an error.
    @discardableResult
    public func runMigrationsIfNecessary(
        migrationSQLForSchemaVersion migrationSQL: (UInt64) -> String,
        willMigrateToSchemaVersion willMigrate: ((UInt64) -> Void)? = nil,
        didMigrateToSchemaVersion didMigrate: ((UInt64) -> Void)? = nil)
        throws -> UInt64
    {
        guard migrationRequired else { return 0 }

        if !migrationsTableExists { try createMigrationsTable() }

        var totalMigrationsCompleted: UInt64 = 0

        for schemaVersion in (currentSchemaVersion + 1)...desiredSchemaVersion {
            let SQL = migrationSQL(schemaVersion)

            willMigrate?(schemaVersion)

            try connection.transaction {
                try self.connection.execute(SQL)
                try self.connection.run(
                    "INSERT INTO \(Migrator.MigrationTableName) VALUES(?, ?)",
                    schemaVersion,
                    BindingDateFormatter.string(from: Date())
                )
            }

            didMigrate?(schemaVersion)

            totalMigrationsCompleted += 1
        }

        return totalMigrationsCompleted
    }

    /// Runs all migrations sequentially until the desired schema version is reached.
    ///
    /// This method gives full control over the migration process. The `migrate` closure passes in the schema
    /// version to update to along with the database connection. It is then the closures job to handle all the
    /// migration logic to update the schema to the provided version. Having complete control over this process
    /// can be very useful when migrating a non-SQift database over to using SQift.
    ///
    /// It is important to note that each version MUST start at one and increment by one each version. Alternative
    /// naming conventions and versioning schemes are NOT supported. For example, your first version number MUST be
    /// 1. The second MUST be 2, etc.
    ///
    /// - Parameters:
    ///   - migrate:     A closure required to migrate to the provided version using the provided connection.
    ///   - willMigrate: A closure executed before running the migration for the specified schema version.
    ///   - didMigrate:  A closure executed after running the migration for the specified schema version.
    ///
    /// - Returns: The total number of migrations completed.
    ///
    /// - Throws: An `Error` if any migration encounters an error.
    @discardableResult
    public func runMigrationsIfNecessary(
        migrateDatabaseToSchemaVersion migrate: ((UInt64), Connection) throws -> Void,
        willMigrateToSchemaVersion willMigrate: ((UInt64) -> Void)? = nil,
        didMigrateToSchemaVersion didMigrate: ((UInt64) -> Void)? = nil)
        throws -> UInt64
    {
        guard migrationRequired else { return 0 }

        if !migrationsTableExists { try createMigrationsTable() }

        var totalMigrationsCompleted: UInt64 = 0

        for schemaVersion in (currentSchemaVersion + 1)...desiredSchemaVersion {
            willMigrate?(schemaVersion)

            try migrate(schemaVersion, connection)
            try connection.run("INSERT INTO \(Migrator.MigrationTableName) VALUES(?, ?)", schemaVersion, Date())

            didMigrate?(schemaVersion)

            totalMigrationsCompleted += 1
        }

        return totalMigrationsCompleted
    }

    // MARK: - Internal - Migrations Table Helpers

    func createMigrationsTable() throws {
        let SQL = [
            "CREATE TABLE IF NOT EXISTS \(Migrator.MigrationTableName)",
            "(version INTEGER UNIQUE NOT NULL, migration_timestamp TEXT NOT NULL)"
        ]

        try connection.execute(SQL.joined(separator: ""))
    }
}
