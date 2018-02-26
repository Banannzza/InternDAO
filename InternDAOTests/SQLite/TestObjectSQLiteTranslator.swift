//
//  TestObjectSQLiteTranslator.swift
//  InternDAOTests
//
//  Created by Алексей Остапенко on 26/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation
@testable import InternDAO

class TestObjectSQLiteTranslator: SQLiteTranslator<TestObject> {
    override func fill(_ entity: TestObject, fromEntry: SQLiteEntry) {
        entity.entityId = fromEntry.entryId
        entity.date = Date(timeIntervalSince1970: fromEntry.dictionary["date"] as! Double)
        entity.name = fromEntry.dictionary["name"] as! String
        
    }
    override func fill(_ entry: SQLiteEntry, fromEntity: TestObject) {
        entry.entryId = fromEntity.entityId
        entry.dictionary = ["name" : fromEntity.name,
                            "date" : fromEntity.date.timeIntervalSince1970]
    }
}
