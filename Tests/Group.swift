//
//  Group.swift
//  DataManager
//
//  Created by Logan Gauthier on 4/26/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import Foundation
import CoreData

class Group: NSManagedObject {

    // MARK: Initialization
    
    convenience init(context: NSManagedObjectContext, title: String) {
        
        guard let entity = NSEntityDescription.entity(forEntityName: String(describing: Group.self), in: context) else {
            
            fatalError("Unable to get entity named \(String(describing: Group.self))")
        }
        
        self.init(entity: entity, insertInto: context)
        self.title = title
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
