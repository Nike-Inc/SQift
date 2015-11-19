//
//  BindingTests.swift
//  SQift
//
//  Created by Christian Noon on 11/12/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation
import SQift
import XCTest

class BindingTestCase: XCTestCase {

    // MARK: - Null Bindable Tests

    func testNSNullBinding() {
        // Given, When
        let bindingValue = NSNull().bindingValue

        // Then
        XCTAssertTrue(bindingValue == .Null)
    }

    // MARK: - Integer Binding Tests

    func testBoolBinding() {
        // Given, When
        let trueBindingValue = true.bindingValue
        let falseBindingValue = true.bindingValue

        let fromBindingValueZero = Bool.fromBindingValue(Int64(0))
        let fromBindingValueOne = Bool.fromBindingValue(Int64(1))
        let fromBindingValueNegativeOne = Bool.fromBindingValue(Int64(-1))

        // Then
        XCTAssertTrue(trueBindingValue == .Integer(1))
        XCTAssertTrue(falseBindingValue == .Integer(1))

        XCTAssertFalse(fromBindingValueZero)
        XCTAssertTrue(fromBindingValueOne)
        XCTAssertTrue(fromBindingValueNegativeOne)
    }

    func testInt8Binding() {
        // Given, When
        let bindingValue = Int8(120).bindingValue

        let fromBindingValueWithinBounds = Int8.fromBindingValue(Int64(120))
        let fromBindingValueOutOfMinBounds = Int8.fromBindingValue(Int64(-140))
        let fromBindingValueOutOfMaxBounds = Int8.fromBindingValue(Int64(140))

        // Then
        XCTAssertTrue(bindingValue == .Integer(120))

        XCTAssertEqual(fromBindingValueWithinBounds, 120)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, Int8.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, Int8.max)
    }

    func testInt16Binding() {
        // Given, When
        let bindingValue = Int16(2_543).bindingValue

        let fromBindingValueWithinBounds = Int16.fromBindingValue(Int64(2_543))
        let fromBindingValueOutOfMinBounds = Int16.fromBindingValue(Int64(-35_000))
        let fromBindingValueOutOfMaxBounds = Int16.fromBindingValue(Int64(35_000))

        // Then
        XCTAssertTrue(bindingValue == .Integer(2_543))

        XCTAssertEqual(fromBindingValueWithinBounds, 2_543)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, Int16.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, Int16.max)
    }

    func testInt32Binding() {
        // Given, When
        let bindingValue = Int32(234_567).bindingValue

        let fromBindingValueWithinBounds = Int32.fromBindingValue(Int64(234_567))
        let fromBindingValueOutOfMinBounds = Int32.fromBindingValue(Int64.min)
        let fromBindingValueOutOfMaxBounds = Int32.fromBindingValue(Int64.max)

        // Then
        XCTAssertTrue(bindingValue == .Integer(234_567))

        XCTAssertEqual(fromBindingValueWithinBounds, 234_567)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, Int32.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, Int32.max)
    }

    func testInt64Binding() {
        // Given, When
        let bindingValue = Int64(Int64.max - 10_000).bindingValue

        let fromBindingValueWithinBounds = Int64.fromBindingValue(Int64.max - 10_000)
        let fromBindingValueMin = Int64.fromBindingValue(Int64.min)
        let fromBindingValueMax = Int64.fromBindingValue(Int64.max)

        // Then
        XCTAssertTrue(bindingValue == .Integer(Int64.max - 10_000))

        XCTAssertEqual(fromBindingValueWithinBounds, Int64.max - 10_000)
        XCTAssertEqual(fromBindingValueMin, Int64.min)
        XCTAssertEqual(fromBindingValueMax, Int64.max)
    }

    func testIntBinding() {
        // Given, When
        let bindingValue = Int(123_456).bindingValue

        let fromBindingValueWithinBounds = Int.fromBindingValue(Int64(123_456))
        let fromBindingValueOutOfMinBounds = Int.fromBindingValue(Int64.min)
        let fromBindingValueOutOfMaxBounds = Int.fromBindingValue(Int64.max)

        // Then
        XCTAssertTrue(bindingValue == .Integer(123_456))

        XCTAssertEqual(fromBindingValueWithinBounds, 123_456)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, Int.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, Int.max)
    }

    func testUInt8Binding() {
        // Given, When
        let bindingValue = UInt8(120).bindingValue

        let fromBindingValueWithinBounds = UInt8.fromBindingValue(Int64(120))
        let fromBindingValueOutOfMinBounds = UInt8.fromBindingValue(Int64(-10))
        let fromBindingValueOutOfMaxBounds = UInt8.fromBindingValue(Int64(260))

        // Then
        XCTAssertTrue(bindingValue == .Integer(120))

        XCTAssertEqual(fromBindingValueWithinBounds, 120)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, UInt8.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, UInt8.max)
    }

    func testUInt16Binding() {
        // Given, When
        let bindingValue = UInt16(64_123).bindingValue

        let fromBindingValueWithinBounds = UInt16.fromBindingValue(Int64(64_123))
        let fromBindingValueOutOfMinBounds = UInt16.fromBindingValue(Int64(-10))
        let fromBindingValueOutOfMaxBounds = UInt16.fromBindingValue(Int64(68_000))

        // Then
        XCTAssertTrue(bindingValue == .Integer(64_123))

        XCTAssertEqual(fromBindingValueWithinBounds, 64_123)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, UInt16.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, UInt16.max)
    }

    func testUInt32Binding() {
        // Given, When
        let bindingValue = UInt32(1_234_567_890).bindingValue

        let fromBindingValueWithinBounds = UInt32.fromBindingValue(Int64(1_234_567_890))
        let fromBindingValueOutOfMinBounds = UInt32.fromBindingValue(Int64(-10))
        let fromBindingValueOutOfMaxBounds = UInt32.fromBindingValue(Int64(UInt32.max))

        // Then
        XCTAssertTrue(bindingValue == .Integer(1_234_567_890))

        XCTAssertEqual(fromBindingValueWithinBounds, 1_234_567_890)
        XCTAssertEqual(fromBindingValueOutOfMinBounds, UInt32.min)
        XCTAssertEqual(fromBindingValueOutOfMaxBounds, UInt32.max)
    }

    func testUInt64Binding() {
        // Given, When
        let bindingValue = (UInt64.max - 40).bindingValue

        let fromBindingValueWithinBounds = UInt64.fromBindingValue(Int64(-41))
        let fromBindingValueMin = UInt64.fromBindingValue(Int64(bitPattern: UInt64.min))
        let fromBindingValueMax = UInt64.fromBindingValue(Int64(bitPattern: UInt64.max))

        // Then
        XCTAssertTrue(bindingValue == .Integer(-41))

        XCTAssertEqual(fromBindingValueWithinBounds, UInt64.max - 40)
        XCTAssertEqual(fromBindingValueMin, UInt64.min)
        XCTAssertEqual(fromBindingValueMax, UInt64.max)
    }

    func testUIntBinding() {
        // Given, When
        let bindingValue = UInt(UInt32.max).bindingValue

        let fromBindingValueWithinBounds = UInt.fromBindingValue(Int64(4_000))
        let fromBindingValueMin = UInt.fromBindingValue(Int64(bitPattern: UInt64(UInt.min)))
        let fromBindingValueMax = UInt.fromBindingValue(Int64(bitPattern: UInt64(UInt.max)))

        // Then
        XCTAssertTrue(bindingValue == .Integer(Int64(UInt32.max)))

        XCTAssertEqual(fromBindingValueWithinBounds, 4_000)
        XCTAssertEqual(fromBindingValueMin, UInt.min)
        XCTAssertEqual(fromBindingValueMax, UInt.max)
    }

    // MARK: - Real Binding Tests

    func testFloatBinding() {
        // Given, When
        let bindingValue = Float(0.123).bindingValue

        let fromBindingValueWithinBounds = Float.fromBindingValue(Double(0.123))
        let fromBindingValueRoundedOff = Float.fromBindingValue(Double(0.123_456_789))

        // Then
        XCTAssertTrue(bindingValue == .Real(Double(Float(0.123))))

        XCTAssertEqual(fromBindingValueWithinBounds, Float(0.123))
        XCTAssertEqualWithAccuracy(fromBindingValueRoundedOff, Float(0.123_457), accuracy: Float(0.000_000_3))
    }

    func testDoubleBinding() {
        // Given, When
        let bindingValue = Double(0.123_456_789_012).bindingValue

        let fromBindingValueWithinBounds = Double.fromBindingValue(0.123_456_789_012)
        let fromBindingValueRoundedOff = Double.fromBindingValue(0.123_456_789_012_345_678)

        // Then
        XCTAssertTrue(bindingValue == .Real(0.123_456_789_012))

        XCTAssertEqual(fromBindingValueWithinBounds, 0.123_456_789_012)
        XCTAssertEqual(fromBindingValueRoundedOff, 0.123_456_789_012_345_678)
    }

    // MARK: - Text Binding Tests

    func testStringBinding() {
        // Given, When
        let bindingValue = "Téštįńg 👍🏼🎉🔥ไม้หันอากาศ".bindingValue
        let fromBindingValue = String.fromBindingValue("Téštįńg 👍🏼🎉🔥ไม้หันอากาศ")

        // Then
        XCTAssertTrue(bindingValue == .Text("Téštįńg 👍🏼🎉🔥ไม้หันอากาศ"))
        XCTAssertEqual(fromBindingValue, "Téštįńg 👍🏼🎉🔥ไม้หันอากาศ")
    }

    func testDateBinding() {
        // Given
        let now = NSDate()

        // When
        let bindingValue = now.bindingValue
        let fromStringBindingValue = NSDate.fromBindingValue(BindingDateFormatter.stringFromDate(now))
        let fromInt64BindingValue = NSDate.fromBindingValue(Int64(now.timeIntervalSince1970))
        let fromDoubleBindingValue = NSDate.fromBindingValue(now.timeIntervalSince1970)

        // Then
        XCTAssertTrue(bindingValue == .Text(BindingDateFormatter.stringFromDate(now)))
        XCTAssertEqualWithAccuracy(fromStringBindingValue.timeIntervalSinceDate(now), 0.0, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(fromInt64BindingValue.timeIntervalSinceDate(now), 0.0, accuracy: 1.0)
        XCTAssertEqualWithAccuracy(fromDoubleBindingValue.timeIntervalSinceDate(now), 0.0, accuracy: 0.000001)
    }

    // MARK: - Blob Binding Tests

    func testNSDataBinding() {
        // Given, When
        let data = "VMOpxaF0xK/FhGcg8J+RjfCfj7zwn46J8J+UpQ==".dataUsingEncoding(NSUTF8StringEncoding)!
        let bindingValue = data.bindingValue
        let fromBindingValue = NSData.fromBindingValue(data)

        // Then
        XCTAssertTrue(bindingValue == .Blob(data))
        XCTAssertEqual(fromBindingValue, data)
    }
}
