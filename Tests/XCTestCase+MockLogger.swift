//
//  DataManager+LogSwizzle.swift
//  DataManager
//
//  Created by Logan Gauthier on 5/2/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation
import XCTest
@testable import DataManager


// MARK: XCTestCase Extension

extension XCTestCase {
    
    func isLogMethodExecutedInClosure(closure: () -> Void) -> Bool {
        
        let originalLogger = DataManager.errorLogger
        let mockLogger = MockLogger()
        DataManager.errorLogger = mockLogger
        closure()
        DataManager.errorLogger = originalLogger
        return mockLogger.didExecuteLogMethod
    }
}



// MARK: MockLogger

class MockLogger: DataManagerErrorLogger {
    
    var didExecuteLogMethod = false
    
    func logError(error: NSError, file: StaticString, function: StaticString, line: UInt) {
        
        didExecuteLogMethod = true
    }
}