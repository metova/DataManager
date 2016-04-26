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
    
    case UseOriginalMethod
    case ThrowError(NSManagedObjectContext)
}



/// The behavior to use when executing the `executeFetchRequest(_:)` method.
private var executeFetchRequestMethodBehavior = ContextSwizzleBehavior.UseOriginalMethod

/// The behavior to use when executing the `save` method.
private var saveMethodBehavior = ContextSwizzleBehavior.UseOriginalMethod



// MARK: - XCTestCase Extension

extension XCTestCase {
    
    /**
     When this method is called, `contextToSwizzle` will throw an error whenever `executeFetchRequest(_:)` is invoked inside the `test` closure.
     
     - parameter contextToSwizzle: The context that should exhibit the error throwing behavior.
     - parameter test:             The test code.
     */
    func executeTestWithErrorThrowingExecuteFetchRequestMock(contextToSwizzle contextToSwizzle: NSManagedObjectContext, test: () -> Void) {
        
        executeFetchRequestMethodBehavior = .ThrowError(contextToSwizzle)
        test()
        executeFetchRequestMethodBehavior = .UseOriginalMethod
    }
    
    /**
     When this method is called, `contextToSwizzle` will throw an error whenever `save` is invoked inside the `test` closure.
     
     - parameter contextToSwizzle: The context that should exhibit the error throwing behavior.
     - parameter test:             The test code.
     */
    func executeTestWithErrorThrowingSaveMock(contextToSwizzle contextToSwizzle: NSManagedObjectContext, test: () -> Void) {
        
        saveMethodBehavior = .ThrowError(contextToSwizzle)
        test()
        saveMethodBehavior = .UseOriginalMethod
    }
}



// MARK: - NSManagedObjectContext Extension

extension NSManagedObjectContext {
    
    // MARK: Overrides
    
    public override class func initialize() {
        
        struct Static {
            
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) { 
            
            swizzle(originalSelector: #selector(executeFetchRequest(_:)), swizzledSelector: #selector(dataManagerTestExecuteFetchRequest(_:)))
            swizzle(originalSelector: #selector(save), swizzledSelector: #selector(dataManagerTestSave))
        }
    }
    
    
    
    // MARK: Helper
    
    private static func swizzle(originalSelector originalSelector: Selector, swizzledSelector: Selector) {
        
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        }
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    
    
    // MARK: Swizzled Methods
    
    func dataManagerTestExecuteFetchRequest(request: NSFetchRequest) throws -> [AnyObject] {
        
        switch executeFetchRequestMethodBehavior {
        case .ThrowError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestExecuteFetchRequest(request)
        }
    }
    
    
    
    func dataManagerTestSave() throws {
        
        switch saveMethodBehavior {
        case .ThrowError(let context) where context === self:
            throw NSError(domain: "DataManagerTests", code: 0, userInfo: nil)
        default:
            return try dataManagerTestSave()
        }
    }
}
