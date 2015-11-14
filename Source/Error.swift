//
//  Error.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

/// Used to encapsulate an error generated by SQLite.
public struct Error: ErrorType {

    // MARK: Properties

    /// The code of the specific error encountered by SQLite: https://www.sqlite.org/c3ref/c_abort.html.
    public let code: Int32

    /// The message of the specific error encountered by SQLite: https://www.sqlite.org/c3ref/errcode.html.
    public var message: String

    /// A textual description of the error code: https://www.sqlite.org/c3ref/errcode.html.
    public var codeDescription: String { return String.fromCString(sqlite3_errstr(code))! }

    private static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    // MARK: Initialization

    init?(code: Int32, database: Database) {
        guard !Error.successCodes.contains(code) else { return nil }

        self.code = code
        self.message = String.fromCString(sqlite3_errmsg(database.handle))!
    }
}

// MARK: - CustomStringConvertible

extension Error: CustomStringConvertible {
    /// A textual representation of the error message, code and code description.
    public var description: String {
        let messageArray = [
            "message=\"\(message ?? "nil")\"",
            "code=\(code)",
            "codeDescription=\"\(codeDescription)\""
        ]

        return "{ " + messageArray.joinWithSeparator(", ") + " }"
    }
}