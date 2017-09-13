//
//  StorageLocation.swift
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

/// Used to specify the path of the database for initialization.
///
/// - onDisk:    Creates an [on-disk database](https://www.sqlite.org/uri.html).
/// - inMemory:  Creates an [in-memory database](https://www.sqlite.org/inmemorydb.html#sharedmemdb).
/// - temporary: Creates a [temporary on-disk database](https://www.sqlite.org/inmemorydb.html#temp_db).
public enum StorageLocation {
    case onDisk(String)
    case inMemory
    case temporary

    /// Returns the path of the database.
    public var path: String {
        switch self {
        case .onDisk(let path):
            return path

        case .inMemory:
            return ":memory:"

        case .temporary:
            return ""
        }
    }
}
