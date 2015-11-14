//
//  Migrator.swift
//  SQift
//
//  Created by Christian Noon on 11/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// The `Migrator` class handles data migrations between schema versions for an attached database. The migrations MUST
/// be numerically ordered by integers starting by 1, and incrementing by one each migration. i.e. [1, 2, 3, 4, etc.].
public class Migrator {

    // MARK: - Properties

    /// The desired schema version of the attached database the migrator will attempt to update to when run.
    public let desiredSchemaVersion: UInt64

    /// The current schema version of the attached database.
    public var currentSchemaVersion: UInt64 {
        var version: UInt64 = 0

        do {
            if let tableVersion: UInt64 = try database.query("SELECT MAX(version) FROM \(Migrator.MigrationTableName)") {
                version = tableVersion
            }
        } catch {
            // No-op
        }

        return version
    }

    /// Whether a migration is required to update the attached database to the desired schema version.
    public var migrationRequired: Bool { return currentSchemaVersion < desiredSchemaVersion }

    var migrationsTableExists: Bool {
        var exists = false

        do {
            exists = try database.query(
                "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                "table",
                Migrator.MigrationTableName
            )
        } catch {
            // No-op
        }

        return exists
    }

    let database: Database

    private static let MigrationTableName = "schema_migrations"

    // MARK: - Initialization

    /**
        Initializes the `Migrator` instance with the given database and desired schema version.

        - parameter database:             The database to attach to the migrator.
        - parameter desiredSchemaVersion: The desired schema version the migrator will use when run.

        - returns: The new `Migrator` instance.
    */
    public init(database: Database, desiredSchemaVersion: UInt64) {
        self.database = database
        self.desiredSchemaVersion = desiredSchemaVersion
    }

    // MARK: - Run Migrations

    /**
        Runs all migrations sequentially until the desired schema version is reached.

        The SQL necessary to run the migration is lazily requested by the `migrationSQLForSchemaVersion` closure. It is
        important to note that each version MUST start at one and increment by one each version. i.e. [1, 2, 3, etc.].

        - parameter migrationSQL: A closure requesting the migration SQL for a required schema version.
        - parameter willMigrate:  A closure executed before running the migration for the specified schema version.
        - parameter didMigrate:   A closure executed after running the migration for the specified schema version.

        - throws: An `Error` if any migration encounters an error.

        - returns: The total number of migrations completed.
    */
    public func runMigrationsIfNecessary(
        migrationSQLForSchemaVersion migrationSQL: UInt64 -> String,
        willMigrateToSchemaVersion willMigrate: (UInt64 -> Void)? = nil,
        didMigrateToSchemaVersion didMigrate: (UInt64 -> Void)? = nil)
        throws -> UInt64
    {
        guard migrationRequired else { return 0 }

        if !migrationsTableExists { try createMigrationsTable() }

        var totalMigrationsCompleted: UInt64 = 0

        for schemaVersion in (currentSchemaVersion + 1)...desiredSchemaVersion {
            let SQL = migrationSQL(schemaVersion)

            willMigrate?(schemaVersion)

            try database.transaction {
                try self.database.execute(SQL)
                try self.database.run(
                    "INSERT INTO \(Migrator.MigrationTableName) VALUES(?, ?)",
                    schemaVersion,
                    BindingDateFormatter.stringFromDate(NSDate())
                )
            }

            didMigrate?(schemaVersion)

            ++totalMigrationsCompleted
        }

        return totalMigrationsCompleted
    }

    // MARK: - Internal - Migrations Table Helpers

    func createMigrationsTable() throws {
        let SQL = [
            "CREATE TABLE IF NOT EXISTS \(Migrator.MigrationTableName)",
            "(version INTEGER UNIQUE NOT NULL, migration_timestamp TEXT NOT NULL)"
        ]

        try database.execute(SQL.joinWithSeparator(""))
    }
}
