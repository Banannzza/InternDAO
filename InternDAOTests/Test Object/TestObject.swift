//
//  TestObject.swift
//  InternDAOTests
//
//  Created by Алексей Остапенко on 26/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation
@testable import InternDAO

class TestObject: Entity {
    var name: String
    var date: Date
    
    init(name: String) {
        self.name = name
        self.date = Date()
        super.init()
    }
    
    required init() {
        self.name = "RedMadRobot"
        self.date = Date()
        super.init()
    }
    
    static func ==(lhs: TestObject, rhs: TestObject) -> Bool {
        return lhs.name == rhs.name && lhs.date.timeIntervalSince1970 == rhs.date.timeIntervalSince1970
    }
    
    override func equals<T>(_ other: T) -> Bool where T : Entity {
        guard let rhs = other as? TestObject else { return false }
        return self == rhs
    }
    
}

