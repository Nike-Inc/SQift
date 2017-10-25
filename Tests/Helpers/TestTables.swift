//
//  TestTables.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift

enum TestTables {
    static func createAndPopulateAgentsTable(using connection: Connection) throws {
        try connection.transaction {
            try connection.execute("""
                CREATE TABLE agents(
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    date TEXT NOT NULL,
                    missions INTEGER NOT NULL,
                    salary REAL NOT NULL,
                    job_title BLOB NOT NULL,
                    car TEXT
                )
                """
            )

            let insertSQL = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
            let insert = try connection.prepare(insertSQL)

            let archersJobTitleData = "The world's greatest secret agent".data(using: .utf8)
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485, 2_500_000.56, archersJobTitleData, "Charger").run()

            let lanasJobTitleData = "Top Agent".data(using: .utf8)
            try insert.bind("Lana Kane", "2015-11-06T08:00:00.000", 2_315, 9_600_200.11, lanasJobTitleData, nil).run()
        }
    }

    static func insertDummyAgents(count: Int, connection: Connection) throws {
        let dateString = bindingDateFormatter.string(from: Date())

        try connection.transaction {
            let sql = "INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)"
            let statement = try connection.prepare(sql)

            for index in 0..<count {
                try statement.bind("name", dateString, index, 2.01, "job".data(using: .utf8), nil).run()
            }
        }
    }
}

// MARK: -

struct Agent: ExpressibleByRow, Equatable {
    let id: Int64
    let name: String
    let date: Date
    let missions: Int64
    let salary: Double
    let jobTitle: Data
    let car: String?

    init(row: Row) throws {
        guard
            let id: Int64 = row["id"],
            let name: String = row["name"],
            let date: Date = row["date"],
            let missions: Int64 = row["missions"],
            let salary: Double = row["salary"],
            let jobTitle: Data = row["job_title"]
        else { throw ExpressibleByRowError(type: Agent.self, row: row) }

        self = Agent(
            id: id,
            name: name,
            date: date,
            missions: missions,
            salary: salary,
            jobTitle: jobTitle,
            car: row["car"]
        )
    }

    init(
        id: Int64,
        name: String,
        date: Date,
        missions: Int64,
        salary: Double,
        jobTitle: Data,
        car: String?)
    {
        self.id = id
        self.name = name
        self.date = date
        self.missions = missions
        self.salary = salary
        self.jobTitle = jobTitle
        self.car = car
    }

    static func == (lhs: Agent, rhs: Agent) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.date == rhs.date &&
            lhs.missions == rhs.missions &&
            lhs.salary == rhs.salary &&
            lhs.jobTitle == rhs.jobTitle &&
            lhs.car == rhs.car
    }
}
