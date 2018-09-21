//
//  MethodSwizzling.swift
//  DataManager
//
//  Created by Logan Gauthier on 5/2/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation

func swizzle(original selector: Selector, with newSelector: Selector, for classType: AnyClass) {
    
    guard
        let originalMethod = class_getInstanceMethod(classType, selector),
        let swizzledMethod = class_getInstanceMethod(classType, newSelector)
    else {
        assertionFailure("Swizzle failure - Failed to get one or both instance methods for \(selector) and \(newSelector) for class type \(String(describing: classType)).")
        return
    }
    
    let didAddMethod = class_addMethod(classType, selector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    
    if didAddMethod {
        class_replaceMethod(classType, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
