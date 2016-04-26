//
//  DataManagerTests.swift
//  DataManagerTests
//
//  Created by Logan Gauthier on 3/31/16.
//  Copyright © 2016 Metova. All rights reserved.
//

import XCTest
import CoreData
@testable import DataManager

class DataManagerTests: XCTestCase {
    
    // MARK: - Set Up / Tear Down
    
    override func setUp() {
    
        super.setUp()
        
        DataManager.setUpWithDataModelName("TestModel", dataModelBundle: NSBundle(forClass: DataManagerTests.self), persistentStoreName: "Test", persistentStoreType: .InMemory)
    }
    
    
    
    override func tearDown() {
        
        DataManager.deleteAllObjects()
        
        super.tearDown()
    }
    
    
    
    // MARK: Helper
    
    func createTestPerson(name name: String = "Test Person", birthDate: NSDate = NSDate(timeIntervalSince1970: 0)) -> Person {
        
        return Person(context: DataManager.mainContext, name: name, birthDate: birthDate)
    }
    
    
    
    func createTestGroup(title title: String = "Test Group") -> Group {
        
        return Group(context: DataManager.mainContext, title: title)
    }
    
    
    
    // MARK: - Tests
    // MARK: Child Context Creation
    
    func testCreatingChildContext() {
        
        let childContext = DataManager.createChildContextWithParentContext(DataManager.mainContext)
        
        XCTAssertEqual(childContext.concurrencyType, NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        XCTAssertTrue(childContext.parentContext === DataManager.mainContext)
    }
    
    
    
    // MARK: Fetch Single Object
    
    func testFetchingSingleObjectWithSortDescriptor() {
        
        let person1 = createTestPerson(birthDate: NSDate(timeIntervalSince1970: 0))
        let person2 = createTestPerson(birthDate: NSDate(timeIntervalSince1970: 1))
        
        let ascendingSortDescriptor = NSSortDescriptor(key: "birthDate", ascending: true)
        let descendingSortDescriptor = NSSortDescriptor(key: "birthDate", ascending: false)
        
        let olderPerson = DataManager.fetchObject(entity: Person.self, sortDescriptors: [ascendingSortDescriptor], context: DataManager.mainContext)
        
        XCTAssertNotNil(olderPerson, "Failed to fetch a single Person.")
        XCTAssertTrue(person1 === olderPerson, "Fetched incorrect Person.")
        
        let youngerPerson = DataManager.fetchObject(entity: Person.self, sortDescriptors: [descendingSortDescriptor], context: DataManager.mainContext)
        
        XCTAssertNotNil(youngerPerson, "Failed to fetch a single Person.")
        XCTAssertTrue(person2 === youngerPerson, "Fetched incorrect Person.")
    }
    
    
    
    func testFetchingSingleObjectWithPredicate() {
        
        let person = createTestPerson(name: "Logan Gauthier")
        _ = createTestPerson()
        
        let predicate = NSPredicate(format: "name == %@", "Logan Gauthier")
        
        let fetchedPerson = DataManager.fetchObject(entity: Person.self, predicate: predicate, context: DataManager.mainContext)
        
        XCTAssertNotNil(fetchedPerson, "Failed to fetch a single Person.")
        XCTAssertTrue(person === fetchedPerson, "Fetched incorrect Person.")
    }
    
    
    
    func testFetchingSingleObjectsForThrownError() {
        
        executeTestWithErrorThrowingExecuteFetchRequestMock(contextToSwizzle: DataManager.mainContext) {
            
            _ = self.createTestPerson()
            
            let fetchedPerson = DataManager.fetchObject(entity: Person.self, context: DataManager.mainContext)
            
            XCTAssertNil(fetchedPerson, "When an error is thrown, it should be caught and nil should be returned.")
        }
    }
    
    
    
    // MARK: Fetch Multiple Objects
    
    func testFetchingMultipleObjects() {
        
        let person1 = createTestPerson()
        let person2 = createTestPerson()
        
        let fetchedPeople = DataManager.fetchObjects(entity: Person.self, context: DataManager.mainContext)
        
        XCTAssertEqual(fetchedPeople.count, 2)
        XCTAssertTrue(fetchedPeople.contains(person1))
        XCTAssertTrue(fetchedPeople.contains(person2))
    }
    
    
    
    func testFetchingMultipleObjectsWithPredicate() {
        
        let person1 = createTestPerson()
        let person2 = createTestPerson()
        _ = createTestPerson(name: "Some Other Name")
        
        let predicate = NSPredicate(format: "name == %@", "Test Person")
        
        let fetchedPeople = DataManager.fetchObjects(entity: Person.self, predicate: predicate, context: DataManager.mainContext)
        
        XCTAssertEqual(fetchedPeople.count, 2)
        XCTAssertTrue(fetchedPeople.contains(person1))
        XCTAssertTrue(fetchedPeople.contains(person2))
    }
    
    
    
    func testFetchingMultipleObjectsWithSortDescriptor() {
        
        let person1 = createTestPerson(birthDate: NSDate(timeIntervalSince1970: 0))
        let person2 = createTestPerson(birthDate: NSDate(timeIntervalSince1970: 1))
        
        let ascendingSortDescriptor = NSSortDescriptor(key: "birthDate", ascending: true)
        let descendingSortDescriptor = NSSortDescriptor(key: "birthDate", ascending: false)
        
        let fetchedPeopleAscending = DataManager.fetchObjects(entity: Person.self, sortDescriptors: [ascendingSortDescriptor], context: DataManager.mainContext)
        
        XCTAssertEqual(fetchedPeopleAscending.count, 2)
        XCTAssertTrue(fetchedPeopleAscending[0] === person1)
        XCTAssertTrue(fetchedPeopleAscending[1] === person2)
        
        let fetchedPeopleDescending = DataManager.fetchObjects(entity: Person.self, sortDescriptors: [descendingSortDescriptor], context: DataManager.mainContext)
        
        XCTAssertEqual(fetchedPeopleDescending.count, 2)
        XCTAssertTrue(fetchedPeopleDescending[0] === person2)
        XCTAssertTrue(fetchedPeopleDescending[1] === person1)
    }
    
    
    
    func testFetchingMultipleObjectsForThrownError() {
        
        executeTestWithErrorThrowingExecuteFetchRequestMock(contextToSwizzle: DataManager.mainContext) {
            
            _ = self.createTestPerson()
            _ = self.createTestPerson()
            
            let fetchedPeople = DataManager.fetchObjects(entity: Person.self, context: DataManager.mainContext)
            
            XCTAssertEqual(fetchedPeople.count, 0, "When an error is thrown, it should be caught and an empty array should be returned.")
        }
    }
    
    
    
    // MARK: Deleting
    
    func testDeletingObjects() {
        
        let person1 = createTestPerson()
        let person2 = createTestPerson()
        
        DataManager.persist(synchronously: true)
        DataManager.deleteObjects([person1, person2], context: DataManager.mainContext)
        
        XCTAssertTrue(person1.deleted)
        XCTAssertTrue(person2.deleted)
    }
    
    
    
    func testDeletingAllObjects() {
        
        let person1 = createTestPerson()
        let person2 = createTestPerson()
        let group1 = createTestGroup()
        let group2 = createTestGroup()
        
        DataManager.persist(synchronously: true)
        DataManager.deleteAllObjects()
        
        XCTAssertTrue(person1.deleted)
        XCTAssertTrue(person2.deleted)
        XCTAssertTrue(group1.deleted)
        XCTAssertTrue(group2.deleted)
    }
    
    
    
    // MARK: Persistence
    
    func testAsynchronousPersistence() {
        
        let person1 = createTestPerson()
        
        XCTAssertTrue(person1.managedObjectContext?.hasChanges == true)
        
        let expectation = expectationWithDescription("Expect private context to save asynchronously.")
        
        DataManager.persist(synchronously: false) { error in
            
            defer { expectation.fulfill() }
            
            guard let privateContext = person1.managedObjectContext?.parentContext else {
                XCTFail("Failed to obtain parent context from person.")
                return
            }
            
            XCTAssertFalse(privateContext.hasChanges)
            XCTAssertNil(error)
        }
        
        XCTAssertTrue(person1.managedObjectContext?.hasChanges == false)
        
        waitForExpectationsWithTimeout(5) { error in
            
            if let error = error {
                XCTFail("Private context failed to save. Expectation error: \(error.localizedDescription)")
            }
        }
    }
    
    
    
    func testSynchronousPersistence() {
        
        let person1 = createTestPerson()
        
        XCTAssertTrue(person1.managedObjectContext?.hasChanges == true)
        
        DataManager.persist(synchronously: true)
        
        XCTAssertTrue(person1.managedObjectContext?.hasChanges == false)
        XCTAssertTrue(person1.managedObjectContext?.parentContext?.hasChanges == false)
    }
    
    
    
    func testSavingForThrownError() {
        
        func assertErrorIsProvidedInCompletionClosure() {
            
            _ = createTestPerson()
            
            DataManager.persist(synchronously: true) { error in
                
                XCTAssertNotNil(error, "When executeFetchRequest(_:) throws an error, it should be passed in the completion closure.")
            }
        }
        
        executeTestWithErrorThrowingSaveMock(contextToSwizzle: DataManager.mainContext, test: assertErrorIsProvidedInCompletionClosure)
        executeTestWithErrorThrowingSaveMock(contextToSwizzle: DataManager.privateContext, test: assertErrorIsProvidedInCompletionClosure)
    }
}
