//
//  Person+CoreDataProperties.swift
//  DataManager
//
//  Created by Logan Gauthier on 4/21/16.
//  Copyright © 2016 Metova. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Person {

    @NSManaged var name: String?
    @NSManaged var birthDate: Date?

}
