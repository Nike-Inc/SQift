//
//  ExpressibleByRowError.swift
//  SQift
//
//  Created by Christian Noon on 8/12/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

/// Represents an error that occurred when trying to create a model object of a specific type from a row.
public struct ExpressibleByRowError: Error {
    /// The type of object that failed to be created.
    public let type: ExpressibleByRow.Type

    /// The columns of the row that produced the error.
    public let columns: [Row.Column]

    /// Creates an instance from the specified type and row.
    ///
    /// - Parameters:
    ///   - type: The type of object that failed.
    ///   - row:  The row used to try to create the object.
    public init(type: ExpressibleByRow.Type, row: Row) {
        self.type = type
        self.columns = row.columns
    }
}

// MARK: - CustomStringConvertible

extension ExpressibleByRowError: CustomStringConvertible {
    /// The textual representation of the error.
    public var description: String { return "ExpressibleByRowError: \(errorDescription ?? "nil")" }
}

// MARK: - LocalizedError

extension ExpressibleByRowError: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String? { return "Failed to initialize \(type) from Row with columns: \(columns)" }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { return "\(type) could not be initialized from Row with columns: \(columns)" }
}
