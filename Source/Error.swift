//
//  Error.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public struct Error: ErrorType {
    public let code: Int32
    public var message: String
    public let statement: Statement?

    public var codeDescription: String { return String.fromCString(sqlite3_errstr(code))! }

    private static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    init?(code: Int32, database: Database, statement: Statement? = nil) {
        guard !Error.successCodes.contains(code) else { return nil }

        self.code = code
        self.message = String.fromCString(sqlite3_errmsg(database.handle))!
        self.statement = statement
    }
}

// MARK: - CustomStringConvertible

extension Error: CustomStringConvertible {
    public var description: String {
        let messageArray = [
            "message=\"\(message ?? "nil")\"",
            "code=\(code)",
            "codeDescription=\"\(codeDescription)\""
        ]

        return "{ " + messageArray.joinWithSeparator(", ") + " }"
    }
}
