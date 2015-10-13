//
//  WeakSetTest.swift
//  sqift
//
//  Created by Dave Camp on 3/17/15.
//  Copyright (c) 2015 Nike. All rights reserved.
//

import Foundation
import XCTest
import sqift

class WeakSetTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testWeakSet()
    {
        let ws = WeakSet<Database>()
        var objectA: Database? = Database("")
        let objectB: Database? = Database("")
        
        XCTAssertTrue(ws.isEmpty, "Empty is incorrect")

        ws.addObject(objectA)
        XCTAssertFalse(ws.isEmpty, "Empty is incorrect")
        
        ws.addObject(objectB)

        XCTAssertFalse(ws.isEmpty, "Empty is incorrect")
        XCTAssertTrue(ws.containsObject(objectA), "Object A missing")
        XCTAssertTrue(ws.containsObject(objectB), "Object B missing")
        
        objectA = nil

        XCTAssertFalse(ws.isEmpty, "Empty is incorrect")
        XCTAssertFalse(ws.containsObject(objectA), "Object A did not go away")
        XCTAssertTrue(ws.containsObject(objectB), "Object B missing")

        ws.removeObject(objectB)

        XCTAssertTrue(ws.isEmpty, "Empty is incorrect")
        XCTAssertFalse(ws.containsObject(objectA), "Object A did not go away")
        XCTAssertFalse(ws.containsObject(objectB), "Object B did not go away")
    }
}
