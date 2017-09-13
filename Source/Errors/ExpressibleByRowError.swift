//
//  ExpressibleByRowError.swift
//
//  Copyright (c) 2015-present Nike, Inc. (https://www.nike.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
