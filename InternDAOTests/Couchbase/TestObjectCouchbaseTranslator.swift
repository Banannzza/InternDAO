//
//  TestObjectCouchbaseTranslator.swift
//  InternDAOTests
//
//  Created by Алексей Остапенко on 26/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
@testable import InternDAO

class TestObjectCouchbaseTranslator: CouchbaseTranslator<TestObject> {
    
    override func fill(_ entity: TestObject, fromEntry: Document) {
        let dictionary = fromEntry.toDictionary()["Couchbase"] as? [String : Any] ?? fromEntry.toDictionary()
        entity.entityId = fromEntry.id
        entity.date = Date(timeIntervalSince1970: dictionary["date"] as! Double)
        entity.name = dictionary["name"] as! String
        
    }
    override func fill(_ entry: MutableDocument, fromEntity: TestObject) {
        let identifier = String(String(describing: fromEntity.self).split(separator: ".").last!)
        entry.setData(["name" : fromEntity.name,
                       "date" : fromEntity.date.timeIntervalSince1970])
        entry.setString(identifier, forKey: "type")
    }
}
