//
//  PersistentStoreTypeTests.swift
//  DataManager
//
//  Created by Logan Gauthier on 4/26/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import XCTest
import CoreData

@testable import DataManager

class PersistentStoreTypeTests: XCTestCase {
    
    // MARK: Tests
    
    func testPersistentStoreTypeStringValues() {
        
        XCTAssertEqual(PersistentStoreType.sqLite.stringValue, NSSQLiteStoreType)
        XCTAssertEqual(PersistentStoreType.binary.stringValue, NSBinaryStoreType)
        XCTAssertEqual(PersistentStoreType.inMemory.stringValue, NSInMemoryStoreType)
    }
}
