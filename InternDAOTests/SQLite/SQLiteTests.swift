//
//  SQLiteTests.swift
//  InternDAOTests
//
//  Created by Алексей Остапенко on 26/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import XCTest
@testable import InternDAO

// Запускать тесты по 1
class SQLiteTests: XCTestCase {
    
    let dao = try! SQLiteDAO<TestObject>(translator: TestObjectSQLiteTranslator())
    
    override func setUp() {
        try? dao.erase()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPersist() {
        let object = TestObject()
        XCTAssertNoThrow(try self.dao.persist(object))
        let savedObject = dao.read(object.entityId)
        XCTAssertNotNil(savedObject)
        XCTAssertEqual(object, savedObject)
    }
    
    func testArrayPersist() {
        let names = ["Agent Smith", "Morpheus", "Trinity", "Neo"]
        var objects = [TestObject]()
        for name in names {
            objects.append(TestObject(name: name))
        }
        XCTAssertNoThrow(try dao.persist(objects))
        let savedObjects = dao.read()
        XCTAssert(objects.count == savedObjects.count, "Не все данные получены")
    }
    
    func testPersistClear() {
        var objects = [TestObject]()
        
        for i in 0..<10 {
            objects.append(TestObject(name: "\(i)"))
        }
        
        for _ in 0..<10 {
            try! dao.persist(objects)
        }
        let savedObjects = dao.read()
        XCTAssert(savedObjects.count == objects.count, "Сохраняются дубликаты")
    }
    
    func testPerformance() {
        var objects = [TestObject]()
       
        for i in 0..<10000 {
            objects.append(TestObject(name: "\(i)"))
        }
        self.measure {
            try? dao.erase()
            try? dao.persist(objects)
        }
    }
    
}
