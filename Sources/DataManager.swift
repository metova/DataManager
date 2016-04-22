//
//  DataManager.swift
//  DataManager
//
//  Copyright (c) 2016 Metova Inc.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import CoreData

// MARK: - PersistentStoreType

public enum PersistentStoreType {
    
    case SQLite
    case Binary
    case InMemory
    
    var stringValue: String {
        switch self {
        case .SQLite:
            return NSSQLiteStoreType
        case .Binary:
            return NSBinaryStoreType
        case .InMemory:
            return NSInMemoryStoreType
        }
    }
}



// MARK: - Constants

private struct Constants {
    
    static private let mustCallSetupMethodErrorMessage = "DataManager must be set up using setUpWithDataModelName(_:persistentStoreName:persistenceType:) before it can be used."
}



// MARK: - DataManager

public final class DataManager {
    
    // MARK: Properties
    
    var dataModelName: String?
    var dataModelBundle: NSBundle?
    var persistentStoreName: String?
    var persistentStoreType = PersistentStoreType.SQLite
    var defaultFetchBatchSize = 50
    var shouldSuppressLogs = false
    
    
    
    // MARK: Singleton
    
    public static let sharedInstance = DataManager()
    
    private init() {}
    
    
    
    // MARK: Setup
    
    /**
     This method must be called before DataManager can be used. It provides DataManager with the required information for setting up the Core Data stack. Call this in application(_:didFinishLaunchingWithOptions:).
     
     - parameter dataModelName:       The name of the data model schema file.
     - parameter persistentStoreName: The name of the persistent store.
     - parameter persistentStoreType: The persistent store type. Defaults to SQLite.
     */
    public func setUpWithDataModelName(dataModelName: String, dataModelBundle: NSBundle? = nil, persistentStoreName: String, persistentStoreType: PersistentStoreType = .SQLite) {
        
        self.dataModelName = dataModelName
        self.dataModelBundle = dataModelBundle ?? NSBundle.mainBundle()
        self.persistentStoreName = persistentStoreName
        self.persistentStoreType = persistentStoreType
    }
    
    
    
    // MARK: Core Data Stack
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }()
    
    
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        
        guard let dataModelName = self.dataModelName else {
            fatalError("Attempting to use nil data model name. \(Constants.mustCallSetupMethodErrorMessage)")
        }
        
        guard let modelURL = self.dataModelBundle?.URLForResource(self.dataModelName, withExtension: "momd") else {
            fatalError("Failed to locate data model schema file.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Failed to created managed object model")
        }
        
        return managedObjectModel
    }()
    
    
    
    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        guard let persistentStoreName = self.persistentStoreName else {
            fatalError("Attempting to use nil persistent store name. \(Constants.mustCallSetupMethodErrorMessage)")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.persistentStoreName).sqlite")
        
        let options: Dictionary? = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        do {
            try coordinator.addPersistentStoreWithType(self.persistentStoreType.stringValue, configuration: nil, URL: url, options: options)
        }
        catch let error as NSError {
            fatalError("Failed to initialize the application's persistent data: \(error.localizedDescription)")
        }
        catch {
            fatalError("Failed to initialize the application's persistent data")
        }
        
        return coordinator
    }()
    
    
    
    private lazy var privateContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        return context
    }()
    
    
    
    public lazy var mainContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = self.privateContext
        return context
    }()
    
    
    
    // MARK: Child Contexts
    
    /**
     Creates a private queue concurrency type context that is the child of the specified parent context.
     
     - parameter parentContext: The context to act as the parent of the returned context.
     
     - returns: A private queue concurrency type context that is the child of the specified parent context.
     */
    public func createChildContextWithParentContext(parentContext: NSManagedObjectContext) -> NSManagedObjectContext {
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = parentContext
        return managedObjectContext
    }
    
    
    
    // MARK: Fetching
    
    public func fetchObjects<T: NSManagedObject>(entity entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> [T] {
        
        let request = NSFetchRequest(entityName: String(entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = defaultFetchBatchSize
        
        do {
            guard let results = try context.executeFetchRequest(request) as? [T] else {
                fatalError("Attempting to fetch objects of an unknown entity (\(entity)).")
            }
            return results
        }
        catch let error as NSError {
            logError(error)
            return [T]()
        }
    }
    
    
    
    public func fetchObject<T: NSManagedObject>(entity entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> T? {
        
        let request = NSFetchRequest(entityName: String(entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = 1
        
        do {
            guard let results = try context.executeFetchRequest(request) as? [T] else {
                fatalError("Attempting to fetch objects of an unknown entity (\(entity)).")
            }
            return results.first
        }
        catch let error as NSError {
            logError(error)
            return nil
        }
    }
    
    
    
    // MARK: Deleting
    
    public func deleteObjects(objects: [NSManagedObject], context: NSManagedObjectContext) {
        
        for object in objects {
            context.deleteObject(object)
        }
    }
    
    
    
    public func deleteAllObjects() throws {
        
        for entityName in managedObjectModel.entitiesByName.keys {
            
            let request = NSFetchRequest()
            request.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: mainContext)
            request.includesPropertyValues = false
            
            guard let objectsToDelete = try mainContext.executeFetchRequest(request) as? [NSManagedObject] else {
                fatalError("Attempting to fetch objects of an unknown entity.")
            }
            
            for object in objectsToDelete {
                mainContext.deleteObject(object)
            }
        }
    }
    
    
    
    // MARK: Saving
    
    /**
     Saves changes to the persistent store.
     
     - parameter synchronously: Whether the main thread should block while writing to the persistent store or not.
     - parameter completion:    Called after the save on the private context completes. If there is an error, it is called immediately and the error parameter is populated.
     */
    public func persist(synchronously synchronously: Bool, completion: ((NSError?) -> Void)? = nil) {
        
        var mainContextSaveError: NSError?
        
        if mainContext.hasChanges {
            mainContext.performBlockAndWait() {
                do {
                    try self.mainContext.save()
                }
                catch var error as NSError {
                    mainContextSaveError = error
                }
            }
        }
        
        guard mainContextSaveError == nil else {
            completion?(mainContextSaveError)
            return
        }
        
        func savePrivateContext() {
            do {
                try privateContext.save()
                completion?(nil)
            }
            catch let error as NSError {
                completion?(error)
            }
        }
        
        if privateContext.hasChanges {
            if synchronously {
                privateContext.performBlockAndWait(savePrivateContext)
            }
            else {
                privateContext.performBlock(savePrivateContext)
            }
        }
    }
    
    
    
    // MARK: Logging
    
    private func logError(error: NSError, function: StaticString = #function, line: UInt = #line) {
        
        if !shouldSuppressLogs {
            print("[DataManager - \(function) line \(line)] Error: \(error.localizedDescription)")
        }
    }
}