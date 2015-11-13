//
//  Migrator.swift
//  SQift
//
//  Created by Christian Noon on 11/11/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

let MigrationTableName = "schema_migrations"

public class Migrator {

    // MARK: - Properties

    public let desiredSchemaVersion: UInt64

    public var currentSchemaVersion: UInt64 {
        var version: UInt64 = 0

        do {
            if let tableVersion: UInt64 = try database.query("SELECT MAX(version) FROM \(MigrationTableName)") {
                version = tableVersion
            }
        } catch {
            // No-op
        }

        return version
    }

    public var migrationRequired: Bool { return currentSchemaVersion < desiredSchemaVersion }

    var migrationsTableExists: Bool {
        var exists = false

        do {
            exists = try database.query(
                "SELECT count(*) FROM sqlite_master WHERE type=? AND name=?",
                "table",
                MigrationTableName
            )
        } catch {
            // No-op
        }

        return exists
    }

    let database: Database

    // MARK: - Initialization

    public init(database: Database, desiredSchemaVersion: UInt64) {
        self.database = database
        self.desiredSchemaVersion = desiredSchemaVersion
    }

    // MARK: - Run Migrations

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
                    "INSERT INTO \(MigrationTableName) VALUES(?, ?)",
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
            "CREATE TABLE IF NOT EXISTS \(MigrationTableName)",
            "(version INTEGER UNIQUE NOT NULL, migration_timestamp TEXT NOT NULL)"
        ]

        try database.execute(SQL.joinWithSeparator(""))
    }
}
