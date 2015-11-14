//
//  Statement.swift
//  SQift
//
//  Created by Dave Camp on 3/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

public class Statement {
    var handle: COpaquePointer = nil
    private let database: Database

    // MARK: - Initialization

    init(database: Database, SQL: String) throws {
        self.database = database
        try database.check(sqlite3_prepare_v2(database.handle, SQL, -1, &handle, nil))
    }

    deinit {
        sqlite3_finalize(handle)
    }

    // MARK: - Binding

    public func bind(bindables: Bindable?...) throws -> Statement {
        try bind(bindables)
        return self
    }

    public func bind(bindables: [Bindable?]) throws -> Statement {
        try reset()

        let parameterCount = Int(sqlite3_bind_parameter_count(handle))

        guard bindables.count == parameterCount else {
            var error = Error(code: SQLITE_MISUSE, database: database)!
            error.message = "Bind expected \(parameterCount) parameters, instead received \(bindables.count)"
            throw error
        }

        for (index, bindable) in bindables.enumerate() {
            try bind(bindable, atIndex: Int32(index + 1))
        }

        return self
    }

    public func bind(bindables: [String: Bindable?]) throws -> Statement {
        try reset()

        for (key, bindable) in bindables {
            let index = Int32(sqlite3_bind_parameter_index(handle, key))

            guard index > 0 else {
                var error = Error(code: SQLITE_MISUSE, database: database)!
                error.message = "Bind could not find index for key: '\(key)'"
                throw error
            }

            try bind(bindable, atIndex: index)
        }

        return self
    }

    private func bind(bindable: Bindable?, atIndex index: Int32) throws {
        guard let bindable = bindable else {
            try database.check(sqlite3_bind_null(handle, index))
            return
        }

        switch bindable.bindingValue {
        case .Null:
            try database.check(sqlite3_bind_null(handle, index))
        case .Integer(let value):
            try database.check(sqlite3_bind_int64(handle, index, value))
        case .Real(let value):
            try database.check(sqlite3_bind_double(handle, index, value))
        case .Text(let value):
            try database.check(sqlite3_bind_text(handle, index, value, -1, SQLITE_TRANSIENT))
        case .Blob(let value):
            try database.check(sqlite3_bind_blob(handle, index, value.bytes, Int32(value.length), SQLITE_TRANSIENT))
        }
    }

    // MARK: - Execution

    public func run() throws -> Statement {
        repeat {} while try step()
        return self
    }

    public func fetch() throws -> Row {
        try step()
        return Row(statement: self)
    }

    public func query<T: Binding>() throws -> T {
        try step()
        let value = Row(statement: self).valueAtColumnIndex(0)

        return T.fromBindingValue(value!) as! T
    }

    public func query<T: Binding>() throws -> T? {
        try step()

        let value = Row(statement: self).valueAtColumnIndex(0)
        guard let bindingValue = value as? T.BindingType else { return nil }

        return T.fromBindingValue(bindingValue) as? T
    }

    // MARK: - Columns

    lazy var columnCount: Int = Int(sqlite3_column_count(self.handle))

    lazy var columnNames: [String] = {
        var names: [String] = []

        for index in 0..<self.columnCount {
            names.append(self.columnNameAtIndex(index))
        }

        return names
    }()

    func columnTypeAtIndex(index: Int) -> Int32 {
        return sqlite3_column_type(handle, Int32(index))
    }

    func columnNameAtIndex(index: Int) -> String {
        return String.fromCString(sqlite3_column_name(handle, Int32(index)))!
    }

    func columnIndexForName(name: String) -> Int? {
        for (index, columnName) in columnNames.enumerate() {
            if columnName == name { return index }
        }

        return nil
    }

    // MARK: - Private - Execution and Binding

    private func reset() throws {
        try database.check(sqlite3_reset(handle))
        try database.check(sqlite3_clear_bindings(handle))
    }

    private func step() throws -> Bool {
        return try database.check(sqlite3_step(handle)) == SQLITE_ROW
    }
}

// MARK: - SequenceType

extension Statement: SequenceType {
    public func generate() -> AnyGenerator<Row> {
        return anyGenerator { try! self.step() ? Row(statement: self) : nil }
    }
}

private let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
