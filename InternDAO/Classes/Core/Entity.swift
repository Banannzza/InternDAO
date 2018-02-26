//
//  Entity.swift
//  InternDAO
//
//  Created by Алексей Остапенко on 24/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation


/// Parent class for all entities.
open class Entity: Hashable {
    
    /// Hash value for compare entities.
    open var hashValue: Int {
        get {
            return self.entityId.hashValue
        }
    }
    
    
    /// Unique entity identifer.
    open var entityId: String = ""
    
    
    required public init() {
        self.entityId = UUID.init().uuidString
    }
    
    
    /// Creates an instance with identifier.
    ///
    /// - Parameter entityId: unique entity identifier.
    public init(entityId: String) {
        self.entityId = entityId
    }
    
    
    /// Function to redefine it in children for proper equality.
    ///
    /// - Parameter other: entity compare with.
    /// - Returns: result of comparison.
    open func equals<T>(_ other: T) -> Bool where T: Entity {
        return self.entityId == other.entityId
    }
}


/// Custom operator `==` for `Entity` and subclasses.
///
/// - Parameters:
///   - lhs: left entity to compare.
///   - rhs: right entity to compare.
/// - Returns: result of comparison.
public func ==<T>(lhs: T, rhs: T) -> Bool where T: Entity {
    return lhs.equals(rhs)
}
