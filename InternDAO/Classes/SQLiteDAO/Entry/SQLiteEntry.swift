//
//  SQLiteEntry.swift
//  InternDAO
//
//  Created by Алексей Остапенко on 25/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation

open class SQLiteEntry: Hashable {
    
    // MARK: - Property
    
    /// Hash value for compare entities.
    open var hashValue: Int {
        get {
            return self.entryId.hashValue
        }
    }
    
    open var dictionary: [String : Any]
    open var entryId: String
    
    // MARK: - Constructor
    
    init(id: String) {
        self.entryId = id
        self.dictionary = [:]
    }
    
    init(id: String, info: [String : Any]) {
        self.entryId = id
        self.dictionary = info
    }
    
    /// Function to redefine it in children for proper equality.
    ///
    /// - Parameter other: entity compare with.
    /// - Returns: result of comparison.
    open func equals<T>(_ other: T) -> Bool where T: SQLiteEntry {
        return self.entryId == other.entryId
    }
}


/// Custom operator `==` for `Entity` and subclasses.
///
/// - Parameters:
///   - lhs: left entity to compare.
///   - rhs: right entity to compare.
/// - Returns: result of comparison.
public func ==<T>(lhs: T, rhs: T) -> Bool where T: SQLiteEntry {
    return lhs.equals(rhs)
}

