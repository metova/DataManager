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
        
        guard let entity = NSEntityDescription.entityForName(String(Group), inManagedObjectContext: context) else {
            
            fatalError("Unable to get entity named \(String(Group))")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.title = title
    }
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
}
