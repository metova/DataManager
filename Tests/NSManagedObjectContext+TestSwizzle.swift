//
//  NSManagedObjectContext+TestSwizzle.swift
//  DataManager
//
//  Created by Logan Gauthier on 4/26/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation
import CoreData
import XCTest

/**
 Represents the behavior an NSManagedObjectContext should use when executing a swizzled method.
 
 - UseOriginalMethod: The context should execute the original method and not use the swizzled version.
 - ThrowError:        If the context is the same instance as the associated context, it should execute the swizzled code which throws a fake error. Otherwise, it should execute the original method.
 */
private enum ContextSwizzleBehavior {
    
    case useOriginalMethod
    case throwError(NSManagedObjectContext)
}



/// The behavior to use when executing the `executeFetchRequest(_:)` method.
private var executeFetchRequestMethodBehavior = ContextSwizzleBehavior.useOriginalMethod

/// The behavior to use when executing the `save` method.
private var saveMethodBehavior = ContextSwizzleBehavior.useOriginalMethod



// MARK: - XCTestCase Extension

extension XCTestCase {
    
    /**
     When this method is called, `contextToSwizzle` will throw an error whenever `executeFetchRequest(_:)` is invoked inside the `test` closure.
     
     - parameter contextToSwizzle: The context that should exhibit the error throwing behavior.
     - parameter test:             The test code.
     */
    func executeTestWithErrorThrowingExecuteFetchRequestMock(contextToSwizzle: NSManagedObjectContext, test: () -> Void) {
        
        executeFetchRequestMethodBehavior = .throwError(contextToSwizzle)
        test()
        executeFetchRequestMethodBehavior = .useOriginalMethod
    }
    
    /**
     When this method is called, `contextToSwizzle` will throw an error whenever `save` is invoked inside the `test` closure.
     
     - parameter contextToSwizzle: The context that should exhibit the error throwing behavior.
     - parameter test:             The test code.
     */
    func executeTestWithErrorThrowingSaveMock(contextToSwizzle: NSManagedObjectContext, test: () -> Void) {
        
        saveMethodBehavior = .throwError(contextToSwizzle)
        test()
        saveMethodBehavior = .useOriginalMethod
    }
}

// DispatchQueue Extension

extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:(Void)->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}


// MARK: - NSManagedObjectContext Extension

extension NSManagedObjectContext {
    
    // MARK: Overrides
    
    open override class func initialize() {
        
       DispatchQueue.once(token: "NSManagedObjectContextSwizzle") {
            swizzle(originalSelector: #selector(fetch(_:)), swizzledSelector: #selector(dataManagerTestExecuteFetchRequest(_:)), forClass: self)
            swizzle(originalSelector: #selector(save), swizzledSelector: #selector(dataManagerTestSave), forClass: self)
        }
    }

    
    
    // MARK: Swizzled Methods
    
    func dataManagerTestExecuteFetchRequest(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [AnyObject] {
        
        switch executeFetchRequestMethodBehavior {
        case .throwError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestExecuteFetchRequest(request)
        }
    }
    
    
    
    func dataManagerTestSave() throws {
        
        switch saveMethodBehavior {
        case .throwError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestSave()
        }
    }
}
