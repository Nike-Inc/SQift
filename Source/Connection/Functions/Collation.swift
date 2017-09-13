//
//  Collation.swift
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
import SQLite3

extension Connection {
    /// A closure executed for a custom collation with a specified name.
    public typealias Collation = (_ lhs: String, _ rhs: String) -> ComparisonResult

    // MARK: - Helper Types

    private class CollationBox {
        private let name: String
        private let collate: Collation

        init(name: String, collate: @escaping Collation) {
            self.name = name
            self.collate = collate
        }

        func collate(
            lhsBytes: UnsafeRawPointer?,
            lhsCount: Int32,
            rhsBytes: UnsafeRawPointer?,
            rhsCount: Int32)
            -> Int32
        {
            guard
                let lhsBytes = lhsBytes,
                let rhsBytes = rhsBytes,
                let lhs = String(data: Data(bytes: lhsBytes, count: Int(lhsCount)), encoding: .utf8),
                let rhs = String(data: Data(bytes: rhsBytes, count: Int(rhsCount)), encoding: .utf8)
            else { return Int32(ComparisonResult.orderedAscending.rawValue) }

            return Int32(collate(lhs, rhs).rawValue)
        }
    }

    // MARK: - Collations

    /// Registers the custom collation name and function with SQLite to execute when collating.
    ///
    /// For more details, please refer to the [documentation](https://www.sqlite.org/datatype3.html#collation).
    ///
    /// - Parameters:
    ///   - name:    The name of the custom collation.
    ///   - collate: The closure used to compare the two strings.
    public func createCollation(named name: String, collate: @escaping Collation) {
        let box = CollationBox(name: name, collate: collate)
        let boxPointer = Unmanaged<CollationBox>.passRetained(box).toOpaque()

        let result = sqlite3_create_collation_v2(
            handle,
            name,
            SQLITE_UTF8,
            boxPointer,
            { (boxPointer: UnsafeMutableRawPointer?, lhsCount, lhsBytes, rhsCount, rhsBytes) in
                guard let boxPointer = boxPointer else { return -1 } // ordered ascending, but shouldn't be called
                let box = Unmanaged<CollationBox>.fromOpaque(boxPointer).takeUnretainedValue()
                return box.collate(lhsBytes: lhsBytes, lhsCount: lhsCount, rhsBytes: rhsBytes, rhsCount: rhsCount)
            },
            { (boxPointer: UnsafeMutableRawPointer?) in
                guard let boxPointer = boxPointer else { return }
                Unmanaged<CollationBox>.fromOpaque(boxPointer).release()
            }
        )

        if result != 0 {
            Unmanaged<CollationBox>.fromOpaque(boxPointer).release()
        }
    }
}
