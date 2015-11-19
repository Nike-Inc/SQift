//
//  TestTables.swift
//  SQift
//
//  Created by Christian Noon on 11/12/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift

struct TestTables {
    static func createAndPopulateAgentsTable(connection: Connection) throws {
        try connection.transaction {
            try connection.run(
                "CREATE TABLE agents(" +
                    "  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
                    "  name TEXT NOT NULL," +
                    "  date TEXT NOT NULL," +
                    "  missions INTEGER NOT NULL," +
                    "  salary REAL NOT NULL," +
                    "  job_title BLOB NOT NULL," +
                    "  car TEXT," +
                    "  beneficiary NULL" +
                ")"
            )

            let insert = try connection.prepare("INSERT INTO agents(name, date, missions, salary, job_title, car) VALUES(?, ?, ?, ?, ?, ?)")

            let archersJobTitleData = "The world's greatest secret agent".dataUsingEncoding(NSUTF8StringEncoding)
            try insert.bind("Sterling Archer", "2015-10-02T08:20:00.000", 485, 2_500_000.56, archersJobTitleData, "Charger").run()

            let lanasJobTitleData = "Top Agent".dataUsingEncoding(NSUTF8StringEncoding)
            try insert.bind("Lana Kane", "2015-11-06T08:00:00.000", 2_315, 9_600_200.11, lanasJobTitleData, nil).run()
        }
    }
}
