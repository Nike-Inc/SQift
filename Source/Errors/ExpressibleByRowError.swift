//
//  ExpressibleByRowError.swift
//  SQift
//
//  Created by Christian Noon on 8/12/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

// TODO: test and docstring
public struct ExpressibleByRowError: Error {
    public let type: ExpressibleByRow.Type
    public let columns: [Row.Column]

    public init(type: ExpressibleByRow.Type, row: Row) {
        self.type = type
        self.columns = row.columns
    }
}

// MARK: - CustomStringConvertible

extension ExpressibleByRowError: CustomStringConvertible {
    public var description: String { return "ExpressibleByRowError: \(errorDescription ?? "nil")" }
}

// MARK: - LocalizedError

extension ExpressibleByRowError: LocalizedError {
    public var errorDescription: String? { return "Failed to initialize \(type) from Row with columns: \(columns)" }
    public var failureReason: String? { return "\(type) could not be initialized from Row with columns: \(columns)" }
}
