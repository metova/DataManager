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
    
    convenience init(context: NSManagedObjectContext, name: String, birthDate: Date) {
        
        guard let entity = NSEntityDescription.entity(forEntityName: String(describing: Person.self), in: context) else {
            
            fatalError("Unable to get entity named \(String(describing: Person.self))")
        }
        
        self.init(entity: entity, insertInto: context)
        self.name = name
        self.birthDate = birthDate
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
