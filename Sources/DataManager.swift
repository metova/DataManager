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

/// An enumeration of the three string constants that are used for specifying the persistent store type (NSSQLiteStoreType, NSBinaryStoreType, NSInMemoryStoreType).
public enum PersistentStoreType {
    
    /// Represents the value for NSSQLiteStoreType.
    case SQLite
    
    /// Represents the value for NSBinaryStoreType.
    case Binary
    
    /// Represents the value for NSInMemoryStoreType.
    case InMemory
    
    /// Value of the Core Data string constants corresponding to each case.
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



// MARK: - Logger

public protocol DataManagerErrorLogger {
    
    func logError(error: NSError, file: StaticString, function: StaticString, line: UInt)
}



// MARK: - DefaultLogger

private class DefaultLogger: DataManagerErrorLogger {
    
    func logError(error: NSError, file: StaticString, function: StaticString, line: UInt) {
        
        print("[DataManager - \(function) line \(line)] Error: \(error.localizedDescription)")
    }
}



// MARK: - Constants

private struct Constants {
    
    static private let mustCallSetupMethodErrorMessage = "DataManager must be set up using setUpWithDataModelName(_:persistentStoreType:) before it can be used."
}



// MARK: - DataManager

/**
 Responsible for setting up the Core Data stack. Also provides some convenience methods for fetching, deleting, and saving.
 */
public final class DataManager {
    
    // MARK: Properties
    
    private static var dataModelName: String?
    private static var dataModelBundle: NSBundle?
    private static var persistentStoreName: String?
    private static var persistentStoreType = PersistentStoreType.SQLite
    
    /// The logger to use for logging errors caught internally. A default logger is used if a custom one isn't provided. Assigning nil to this property prevents DataManager from emitting any logs to the console.
    public static var errorLogger: DataManagerErrorLogger? = DefaultLogger()
    
    /// The value to use for `fetchBatchSize` when fetching objects.
    public static var defaultFetchBatchSize = 50
    
    
    
    // MARK: Setup
    
    /**
     This method must be called before DataManager can be used. It provides DataManager with the required information for setting up the Core Data stack. Call this in application(_:didFinishLaunchingWithOptions:).
     
     - parameter dataModelName:       The name of the data model schema file.
     - parameter dataModelBundle:     The bundle in which the data model schema file resides.
     - parameter persistentStoreName: The name of the persistent store.
     - parameter persistentStoreType: The persistent store type. Defaults to SQLite.
     */
    public static func setUpWithDataModelName(dataModelName: String, dataModelBundle: NSBundle, persistentStoreName: String, persistentStoreType: PersistentStoreType = .SQLite) {
        
        DataManager.dataModelName = dataModelName
        DataManager.dataModelBundle = dataModelBundle
        DataManager.persistentStoreName = persistentStoreName
        DataManager.persistentStoreType = persistentStoreType
    }
    
    
    
    // MARK: Core Data Stack
    
    private static var applicationDocumentsDirectory: NSURL = {
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }()
    
    
    
    private static var managedObjectModel: NSManagedObjectModel = {

        guard let dataModelName = DataManager.dataModelName else {
            fatalError("Attempting to use nil data model name. \(Constants.mustCallSetupMethodErrorMessage)")
        }
        
        guard let modelURL = DataManager.dataModelBundle?.URLForResource(DataManager.dataModelName, withExtension: "momd") else {
            fatalError("Failed to locate data model schema file.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Failed to created managed object model")
        }
        
        return managedObjectModel
    }()
    
    
    
    private static var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        guard let persistentStoreName = DataManager.persistentStoreName else {
            fatalError("Attempting to use nil persistent store name. \(Constants.mustCallSetupMethodErrorMessage)")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: DataManager.managedObjectModel)
        let url = DataManager.applicationDocumentsDirectory.URLByAppendingPathComponent("\(persistentStoreName).sqlite")
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        do {
            try coordinator.addPersistentStoreWithType(DataManager.persistentStoreType.stringValue, configuration: nil, URL: url, options: options)
        }
        catch let error as NSError {
            fatalError("Failed to initialize the application's persistent data: \(error.localizedDescription)")
        }
        catch {
            fatalError("Failed to initialize the application's persistent data")
        }
        
        return coordinator
    }()
    
    
    
    static var privateContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = DataManager.persistentStoreCoordinator
        return context
    }()
    
    
    
    /// A MainQueueConcurrencyType context whose parent is a PrivateQueueConcurrencyType context. The PrivateQueueConcurrencyType context is the root context.
    public static var mainContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = DataManager.privateContext
        return context
    }()
    
    
    
    // MARK: Child Contexts
    
    /**
     Creates a private queue concurrency type context that is the child of the specified parent context.
     
     - parameter parentContext: The context to act as the parent of the returned context.
     
     - returns: A private queue concurrency type context that is the child of the specified parent context.
     */
    public static func createChildContextWithParentContext(parentContext: NSManagedObjectContext) -> NSManagedObjectContext {
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = parentContext
        return managedObjectContext
    }
    
    
    
    // MARK: Fetching
    
    /**
     This is a convenience method for performing a fetch request. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     
     - parameter entity:          The NSManagedObject subclass to be fetched.
     - parameter predicate:       A predicate to use for the fetch if needed (defaults to nil).
     - parameter sortDescriptors: Sort descriptors to use for the fetch if needed (defaults to nil).
     - parameter context:         The NSManagedObjectContext to perform the fetch with.
     
     - returns: A typed array containing the results. If executeFetchRequest throws an error, an empty array is returned.
     */
    public static func fetchObjects<T: NSManagedObject>(entity entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> [T] {
        
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
    
    
    
    /**
     This is a convenience method for performing a fetch request that fetches a single object. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     
     - parameter entity:          The NSManagedObject subclass to be fetched.
     - parameter predicate:       A predicate to use for the fetch if needed (defaults to nil).
     - parameter sortDescriptors: Sort descriptors to use for the fetch if needed (defaults to nil).
     - parameter context:         The NSManagedObjectContext to perform the fetch with.
     
     - returns: A typed result if found. If executeFetchRequest throws an error, nil is returned.
     */
    public static func fetchObject<T: NSManagedObject>(entity entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> T? {
        
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
    
    /**
     Iterates over the objects and deletes them using the supplied context.
     
     - parameter objects: The objects to delete.
     - parameter context: The context to perform the deletion with.
     */
    public static func deleteObjects(objects: [NSManagedObject], context: NSManagedObjectContext) {
        
        for object in objects {
            context.deleteObject(object)
        }
    }
    
    
    
    /**
     For each entity in the model, fetches all objects into memory, iterates over each object and deletes them using the main context. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     */
    public static func deleteAllObjects() {
        
        for entityName in managedObjectModel.entitiesByName.keys {
            
            let request = NSFetchRequest(entityName: entityName)
            request.includesPropertyValues = false
            
            do {
                guard let objectsToDelete = try mainContext.executeFetchRequest(request) as? [NSManagedObject] else {
                    fatalError("Attempting to fetch objects of an unknown entity.")
                }
                
                for object in objectsToDelete {
                    mainContext.deleteObject(object)
                }
            }
            catch let error as NSError {
                logError(error)
            }
        }
    }
    
    
    
    // MARK: Saving
    
    /**
     Saves changes to the persistent store.
     
     - parameter synchronously: Whether the main thread should block while writing to the persistent store or not.
     - parameter completion:    Called after the save on the private context completes. If there is an error, it is called immediately and the error parameter is populated.
     */
    public static func persist(synchronously synchronously: Bool, completion: ((NSError?) -> Void)? = nil) {
        
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
    
    private static func logError(error: NSError, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        
        errorLogger?.logError(error, file: file, function: function, line: line)
    }
}
