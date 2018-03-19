//
//  BindingTests.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation
import SQift
import XCTest

class BindingTestCase: BaseTestCase {

    // MARK: - Helper Types

    private struct Person: CodableBinding, Equatable {
        typealias BindingType = Data

        let firstName: String
        let lastName: String
        let countries: [String]
        let friends: UInt
        let homes: Int64

        static func ==(lhs: Person, rhs: Person) -> Bool {
            return lhs.firstName == rhs.firstName &&
                lhs.lastName == rhs.lastName &&
                lhs.countries == rhs.countries &&
                lhs.friends == rhs.friends &&
                lhs.homes == rhs.homes
        }
    }

    // MARK: - Properties

    private var is64Bit: Bool { return MemoryLayout<Int>.size == MemoryLayout<Int64>.size }

    // MARK: - Tests - Null Bindable

    func testNSNullBinding() {
        // Given, When
        let bindingValue = NSNull().bindingValue

        // Then
        XCTAssertTrue(bindingValue == .null)
    }

    // MARK: - Tests - Integer Binding

    func testBoolBinding() {
        // Given, When
        let trueBindingValue = true.bindingValue
        let falseBindingValue = true.bindingValue

        let fromBindingValueZero = Bool.fromBindingValue(Int64(0))
        let fromBindingValueOne = Bool.fromBindingValue(Int64(1))
        let fromBindingValueNegativeOne = Bool.fromBindingValue(Int64(-1))
        let fromInvalidBindingValue = Bool.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(trueBindingValue == .integer(1))
        XCTAssertTrue(falseBindingValue == .integer(1))

        XCTAssertEqual(fromBindingValueZero, false)
        XCTAssertEqual(fromBindingValueOne, true)
        XCTAssertEqual(fromBindingValueNegativeOne, true)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testInt8Binding() {
        // Given, When
        let bindingValue = Int8(120).bindingValue

        let fromBindingValueMin = Int8.fromBindingValue(Int64(Int8.min))
        let fromBindingValueMax = Int8.fromBindingValue(Int64(Int8.max))
        let fromBindingValueWithinBounds = Int8.fromBindingValue(Int64(120))

        let fromBindingValueOutOfMinBounds = Int8.fromBindingValue(Int64(-140))
        let fromBindingValueOutOfMaxBounds = Int8.fromBindingValue(Int64(140))
        let fromInvalidBindingValue = Int8.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(120))

        XCTAssertEqual(fromBindingValueMin, Int8.min)
        XCTAssertEqual(fromBindingValueMax, Int8.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 120)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testInt16Binding() {
        // Given, When
        let bindingValue = Int16(2_543).bindingValue

        let fromBindingValueMin = Int16.fromBindingValue(Int64(Int16.min))
        let fromBindingValueMax = Int16.fromBindingValue(Int64(Int16.max))
        let fromBindingValueWithinBounds = Int16.fromBindingValue(Int64(2_543))

        let fromBindingValueOutOfMinBounds = Int16.fromBindingValue(Int64(-35_000))
        let fromBindingValueOutOfMaxBounds = Int16.fromBindingValue(Int64(35_000))
        let fromInvalidBindingValue = Int16.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(2_543))

        XCTAssertEqual(fromBindingValueMin, Int16.min)
        XCTAssertEqual(fromBindingValueMax, Int16.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 2_543)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testInt32Binding() {
        // Given, When
        let bindingValue = Int32(234_567).bindingValue

        let fromBindingValueMin = Int32.fromBindingValue(Int64(Int32.min))
        let fromBindingValueMax = Int32.fromBindingValue(Int64(Int32.max))
        let fromBindingValueWithinBounds = Int32.fromBindingValue(Int64(234_567))

        let fromBindingValueOutOfMinBounds = Int32.fromBindingValue(Int64.min)
        let fromBindingValueOutOfMaxBounds = Int32.fromBindingValue(Int64.max)
        let fromInvalidBindingValue = Int32.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(234_567))

        XCTAssertEqual(fromBindingValueMin, Int32.min)
        XCTAssertEqual(fromBindingValueMax, Int32.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 234_567)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testInt64Binding() {
        // Given, When
        let bindingValue = Int64(Int64.max - 10_000).bindingValue

        let fromBindingValueMin = Int64.fromBindingValue(Int64.min)
        let fromBindingValueMax = Int64.fromBindingValue(Int64.max)
        let fromBindingValueWithinBounds = Int64.fromBindingValue(Int64.max - 10_000)

        let fromInvalidBindingValue = Int64.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(Int64.max - 10_000))

        XCTAssertEqual(fromBindingValueMin, Int64.min)
        XCTAssertEqual(fromBindingValueMax, Int64.max)
        XCTAssertEqual(fromBindingValueWithinBounds, Int64.max - 10_000)

        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testIntBinding() {
        // Given, When
        let bindingValue = Int(123_456).bindingValue

        let fromBindingValueMin = Int.fromBindingValue(Int64(Int.min))
        let fromBindingValueMax = Int.fromBindingValue(Int64(Int.max))
        let fromBindingValueWithinBounds = Int.fromBindingValue(Int64(123_456))

        let fromBindingValuePossiblyOutOfMinBounds = Int.fromBindingValue(Int64.min)
        let fromBindingValuePossiblyOutOfMaxBounds = Int.fromBindingValue(Int64.max)
        let fromInvalidBindingValue = Int.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(123_456))

        XCTAssertEqual(fromBindingValueMin, Int.min)
        XCTAssertEqual(fromBindingValueMax, Int.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 123_456)

        if is64Bit {
            XCTAssertEqual(fromBindingValuePossiblyOutOfMinBounds, Int.min)
            XCTAssertEqual(fromBindingValuePossiblyOutOfMaxBounds, Int.max)
        } else {
            XCTAssertEqual(fromBindingValuePossiblyOutOfMinBounds, nil)
            XCTAssertEqual(fromBindingValuePossiblyOutOfMaxBounds, nil)
        }

        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testUInt8Binding() {
        // Given, When
        let bindingValue = UInt8(120).bindingValue

        let fromBindingValueMin = UInt8.fromBindingValue(Int64(UInt8.min))
        let fromBindingValueMax = UInt8.fromBindingValue(Int64(UInt8.max))
        let fromBindingValueWithinBounds = UInt8.fromBindingValue(Int64(120))

        let fromBindingValueOutOfMinBounds = UInt8.fromBindingValue(Int64(-10))
        let fromBindingValueOutOfMaxBounds = UInt8.fromBindingValue(Int64(260))
        let fromInvalidBindingValue = UInt8.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(120))

        XCTAssertEqual(fromBindingValueMin, UInt8.min)
        XCTAssertEqual(fromBindingValueMax, UInt8.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 120)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testUInt16Binding() {
        // Given, When
        let bindingValue = UInt16(64_123).bindingValue

        let fromBindingValueMin = UInt16.fromBindingValue(Int64(UInt16.min))
        let fromBindingValueMax = UInt16.fromBindingValue(Int64(UInt16.max))
        let fromBindingValueWithinBounds = UInt16.fromBindingValue(Int64(64_123))

        let fromBindingValueOutOfMinBounds = UInt16.fromBindingValue(Int64(-10))
        let fromBindingValueOutOfMaxBounds = UInt16.fromBindingValue(Int64(68_000))
        let fromInvalidBindingValue = UInt16.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(64_123))

        XCTAssertEqual(fromBindingValueMin, UInt16.min)
        XCTAssertEqual(fromBindingValueMax, UInt16.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 64_123)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testUInt32Binding() {
        // Given, When
        let bindingValue = UInt32(1_234_567_890).bindingValue

        let fromBindingValueMin = UInt32.fromBindingValue(Int64(UInt32.min))
        let fromBindingValueMax = UInt32.fromBindingValue(Int64(UInt32.max))
        let fromBindingValueWithinBounds = UInt32.fromBindingValue(Int64(1_234_567_890))

        let fromBindingValueOutOfMinBounds = UInt32.fromBindingValue(Int64(-10))
        let fromInvalidBindingValue = UInt32.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(1_234_567_890))

        XCTAssertEqual(fromBindingValueMin, UInt32.min)
        XCTAssertEqual(fromBindingValueMax, UInt32.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 1_234_567_890)

        XCTAssertEqual(fromBindingValueOutOfMinBounds, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testUInt64Binding() {
        // Given, When
        let bindingValue = (UInt64.max - 40).bindingValue

        let fromBindingValueMin = UInt64.fromBindingValue(Int64(bitPattern: UInt64.min))
        let fromBindingValueMax = UInt64.fromBindingValue(Int64(bitPattern: UInt64.max))
        let fromBindingValueWithinBounds = UInt64.fromBindingValue(Int64(-41))

        let fromInvalidBindingValue = UInt64.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(-41))

        XCTAssertEqual(fromBindingValueMin, UInt64.min)
        XCTAssertEqual(fromBindingValueMax, UInt64.max)
        XCTAssertEqual(fromBindingValueWithinBounds, UInt64.max - UInt64(40))

        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testUIntBinding() {
        // Given, When
        let bindingValue = UInt(UInt32.max).bindingValue

        let fromBindingValueMin = UInt.fromBindingValue(Int64(bitPattern: UInt64(UInt.min)))
        let fromBindingValueMax = UInt.fromBindingValue(Int64(bitPattern: UInt64(UInt.max)))
        let fromBindingValueWithinBounds = UInt.fromBindingValue(Int64(4_000))

        let fromInvalidBindingValue = UInt.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .integer(Int64(UInt32.max)))

        XCTAssertEqual(fromBindingValueMin, UInt.min)
        XCTAssertEqual(fromBindingValueMax, UInt.max)
        XCTAssertEqual(fromBindingValueWithinBounds, 4_000)

        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    // MARK: - Tests - Real Binding

    func testFloatBinding() {
        // Given, When
        let bindingValue = Float(0.123).bindingValue

        let fromBindingValueWithinBounds = Float.fromBindingValue(Double(0.123))
        let fromBindingValueRoundedOff = Float.fromBindingValue(Double(0.123_456_789)) ?? 0.0
        let fromInvalidBindingValue = Float.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .real(Double(Float(0.123))))

        XCTAssertEqual(fromBindingValueWithinBounds, Float(0.123))
        XCTAssertEqual(fromBindingValueRoundedOff, Float(0.123_457), accuracy: Float(0.000_000_3))
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testDoubleBinding() {
        // Given, When
        let bindingValue = Double(0.123_456_789_012).bindingValue

        let fromBindingValueWithinBounds = Double.fromBindingValue(0.123_456_789_012)
        let fromBindingValueRoundedOff = Double.fromBindingValue(0.123_456_789_012_345_678)
        let fromInvalidBindingValue = Double.fromBindingValue("invalid")

        // Then
        XCTAssertTrue(bindingValue == .real(0.123_456_789_012))

        XCTAssertEqual(fromBindingValueWithinBounds, 0.123_456_789_012)
        XCTAssertEqual(fromBindingValueRoundedOff, 0.123_456_789_012_345_678)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    // MARK: - Tests - Text Binding

    func testStringBinding() {
        // Given, When
        let bindingValue = "Téštįńg 👍🏼🎉🔥ไม้หันอากาศ".bindingValue
        let fromBindingValue = String.fromBindingValue("Téštįńg 👍🏼🎉🔥ไม้หันอากาศ")
        let fromInvalidBindingValue = String.fromBindingValue(1234)

        // Then
        XCTAssertTrue(bindingValue == .text("Téštįńg 👍🏼🎉🔥ไม้หันอากาศ"))
        XCTAssertEqual(fromBindingValue, "Téštįńg 👍🏼🎉🔥ไม้หันอากาศ")
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testURLBinding() {
        // Given, When
        let remoteURLBindingValue = URL(string: "https://httpbin.org/get")!.bindingValue
        let remoteURLFromBindingValue = URL.fromBindingValue("https://httpbin.org/get")

        let fileURLBindingValue = URL(fileURLWithPath: "/Users/cnoon/DropShip/file.json").bindingValue
        let fileURLFromBindingValue = URL.fromBindingValue("file:///Users/cnoon/DropShip/file.json")
        let fromInvalidBindingValue = URL.fromBindingValue(1234)

        // Then
        XCTAssertTrue(remoteURLBindingValue == .text("https://httpbin.org/get"))
        XCTAssertEqual(remoteURLFromBindingValue, URL(string: "https://httpbin.org/get")!)

        XCTAssertTrue(fileURLBindingValue == .text("file:///Users/cnoon/DropShip/file.json"))
        XCTAssertEqual(fileURLFromBindingValue, URL(fileURLWithPath: "/Users/cnoon/DropShip/file.json"))
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    func testDateBinding() {
        // Given
        let timestamp = Date(timeIntervalSince1970: 123_456_789.0)

        // When
        let bindingValue = timestamp.bindingValue
        let fromStringBindingValue = Date.fromBindingValue(bindingDateFormatter.string(from: timestamp)) ?? Date()
        let fromInvalidStringValue = Date.fromBindingValue("12:34:56") // MUST use date binding formatter format
        let fromInvalidBindingValue = Date.fromBindingValue(1234)

        // Then
        XCTAssertTrue(bindingValue == .text(bindingDateFormatter.string(from: timestamp)))
        XCTAssertEqual(fromStringBindingValue.timeIntervalSince(timestamp), 0.0)
        XCTAssertEqual(fromInvalidStringValue, nil)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    // MARK: - Tests - Blob Binding

    func testDataBinding() {
        // Given, When
        let data = "VMOpxaF0xK/FhGcg8J+RjfCfj7zwn46J8J+UpQ==".data(using: .utf8)!
        let bindingValue = data.bindingValue
        let fromBindingValue = Data.fromBindingValue(data)
        let fromInvalidBindingValue = Date.fromBindingValue(1234)

        // Then
        XCTAssertTrue(bindingValue == .blob(data))
        XCTAssertEqual(fromBindingValue, data)
        XCTAssertEqual(fromInvalidBindingValue, nil)
    }

    // MARK: - Tests - Codable Binding

    func testCodableBinding() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE person(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")

        let archer = Person(firstName: "Sterling", lastName: "Archer", countries: ["USA", "France", "Belgium"], friends: 0, homes: 2)
        let lana = Person(firstName: "Lana", lastName: "Kane", countries: ["USA", "China", "Russia"], friends: 1, homes: 20)

        // When
        try connection.run("INSERT INTO person(data) VALUES(?)", archer)
        try connection.run("INSERT INTO person(data) VALUES(?)", lana)

        let archerQueried: Person? = try connection.query("SELECT data FROM person WHERE id = ?", 1)
        let lanaQueried: Person? = try connection.query("SELECT data FROM person WHERE id = ?", 2)

        // Then
        XCTAssertEqual(archerQueried, archer)
        XCTAssertEqual(lanaQueried, lana)
    }

    // MARK: - Tests - Collection Bindings

    func testArrayBinding() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE stream(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")

        let points: ArrayBinding = [
            CGPoint(x: 1.0, y: 2.0),
            CGPoint(x: 3.0, y: 4.0),
            CGPoint(x: 5.0, y: 6.0),
            CGPoint(x: 7.0, y: 8.0),
            CGPoint(x: 9.0, y: 10.0)
        ]

        // When
        try connection.run("INSERT INTO stream(data) VALUES(?)", points)
        let pointsQueried: ArrayBinding<CGPoint>? = try connection.query("SELECT data FROM stream WHERE id = ?", 1)

        // Then
        XCTAssertEqual(pointsQueried?.elements ?? [], points.elements)
    }

    func testArrayBindingOfCodableBindings() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE stream(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")

        let people: ArrayBinding = [
            Person(firstName: "Sterling", lastName: "Archer", countries: ["USA", "France", "Belgium"], friends: 0, homes: 2),
            Person(firstName: "Lana", lastName: "Kane", countries: ["USA", "China", "Russia"], friends: 1, homes: 20)
        ]

        // When
        try connection.run("INSERT INTO stream(data) VALUES(?)", people)
        let peopleQueried: ArrayBinding<Person>? = try connection.query("SELECT data FROM stream WHERE id = ?", 1)

        // Then
        XCTAssertEqual(peopleQueried?.elements ?? [], people.elements)
    }

    func testSetBinding() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE stream(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")

        let identifiers: SetBinding = [
            UUID(),
            UUID(),
            UUID(),
            UUID()
        ]

        // When
        try connection.run("INSERT INTO stream(data) VALUES(?)", identifiers)
        let identifiersQueried: SetBinding<UUID>? = try connection.query("SELECT data FROM stream WHERE id = ?", 1)

        // Then
        XCTAssertEqual(identifiersQueried?.elements ?? [], identifiers.elements)
    }

    func testDictionaryBinding() throws {
        // Given
        let connection = try Connection(storageLocation: storageLocation)
        try connection.execute("CREATE TABLE stream(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")

        let capitals: DictionaryBinding = [
            "Iowa": "Des Moines",
            "Oregon": "Salem",
            "California": "Sacremento",
            "Washington": "Olympia"
        ]

        // When
        try connection.run("INSERT INTO stream(data) VALUES(?)", capitals)
        let capitalsQueried: DictionaryBinding<String, String>? = try connection.query("SELECT data FROM stream WHERE id = ?", 1)

        // Then
        XCTAssertEqual(capitalsQueried?.elements ?? [:], capitals.elements)
    }
}
