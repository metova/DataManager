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
 
 - useOriginalMethod: The context should execute the original method and not use the swizzled version.
 - throwError:        If the context is the same instance as the associated context, it should execute the swizzled code which throws a fake error. Otherwise, it should execute the original method.
 */
private enum ContextSwizzleBehavior {
    
    case useOriginalMethod
    case throwError(NSManagedObjectContext)
}

/// The behavior to use when executing the `fetch(_:)` method.
private var executeFetchRequestMethodBehavior = ContextSwizzleBehavior.useOriginalMethod

/// The behavior to use when executing the `save` method.
private var saveMethodBehavior = ContextSwizzleBehavior.useOriginalMethod

// MARK: - XCTestCase Extension

extension XCTestCase {
    
    /**
     When this method is called, `contextToSwizzle` will throw an error whenever `fetch(_:)` is invoked inside the `test` closure.
     
     - parameter contextToSwizzle: The context that should exhibit the error throwing behavior.
     - parameter test:             The test code.
     */
    func executeTestWithErrorThrowingExecuteFetchRequestMock(contextToSwizzle: NSManagedObjectContext, test: () -> Void) {
        
        setUpSwizzling()
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
        
        setUpSwizzling()
        saveMethodBehavior = .throwError(contextToSwizzle)
        test()
        saveMethodBehavior = .useOriginalMethod
    }
    
    /// Swizzle `NSManagedObjectContext`'s `fetch(_:)` and `save` methods in preparation for tests that require custom behavior.
    private func setUpSwizzling() {
        
        DispatchQueue.once(withToken: "NSManagedObjectContextSwizzle") {
            swizzle(original: #selector(NSManagedObjectContext.fetch(_:)), with: #selector(NSManagedObjectContext.dataManagerTestExecute(fetchRequest:)), for: NSManagedObjectContext.self)
            swizzle(original: #selector(NSManagedObjectContext.save), with: #selector(NSManagedObjectContext.dataManagerTestSave), for: NSManagedObjectContext.self)
        }
    }
}

// MARK: - DispatchQueue Extension

extension DispatchQueue {
    
    private static var onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token:      A unique token representing the action to execute once.
     - parameter onceAction: Action to execute once.
     */
    class func once(withToken token: String, onceAction: () -> Void) {
        
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        guard !onceTracker.contains(token) else { return }
        
        onceTracker.append(token)
        onceAction()
    }
}

// MARK: - NSManagedObjectContext Extension

extension NSManagedObjectContext {
    
    // MARK: Swizzled Methods
    
    @objc func dataManagerTestExecute(fetchRequest: NSFetchRequest<NSManagedObject>) throws -> [AnyObject] {
        
        switch executeFetchRequestMethodBehavior {
        case .throwError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestExecute(fetchRequest: fetchRequest)
        }
    }
    
    @objc func dataManagerTestSave() throws {
        
        switch saveMethodBehavior {
        case .throwError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestSave()
        }
    }
}
