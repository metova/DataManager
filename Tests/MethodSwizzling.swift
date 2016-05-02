//
//  MethodSwizzling.swift
//  DataManager
//
//  Created by Logan Gauthier on 5/2/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation

func swizzle(originalSelector originalSelector: Selector, swizzledSelector: Selector, forClass classType: AnyClass) {
    
    let originalMethod = class_getInstanceMethod(classType, originalSelector)
    let swizzledMethod = class_getInstanceMethod(classType, swizzledSelector)
    
    let didAddMethod = class_addMethod(classType, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    
    if didAddMethod {
        class_replaceMethod(classType, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
