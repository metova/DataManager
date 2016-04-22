//
//  Person.swift
//  DataManager
//
//  Created by Logan Gauthier on 4/21/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation
import CoreData


class Person: NSManagedObject {

    // MARK: Initialization
    
    convenience init(context: NSManagedObjectContext, name: String, birthDate: NSDate) {
        
        guard let entity = NSEntityDescription.entityForName(String(Person), inManagedObjectContext: context) else {
            
            fatalError("Unable to get entity named \(String(Person))")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.name = name
        self.birthDate = birthDate
    }
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
}
