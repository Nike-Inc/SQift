//
//  StringExtension.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

extension String {
    /// Returns a new string extension instance.
    public var sqift: StringExtension { return StringExtension(string: self) }
}

// MARK: -

/// Used to extend the String type inside a `swift` namespace.
public struct StringExtension {
    private let string: String
    private let singleQuote = "'"
    private let escapedQuote = "''"

    init(string: String) {
        self.string = string
    }

    /// Returns a new SQL `String` made by adding single quotes around the `String` and escaping internal single quotes.
    ///
    /// - Returns: The new escaped `String`.
    public func addingSQLEscapes() -> String {
        return singleQuote + string.replacingOccurrences(of: singleQuote, with: escapedQuote) + singleQuote
    }
}
