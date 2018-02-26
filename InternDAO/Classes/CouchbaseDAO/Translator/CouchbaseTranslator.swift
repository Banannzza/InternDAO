//
//  CouchbaseTranslator.swift
//  InternDAO
//
//  Created by Алексей Остапенко on 24/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

open class CouchbaseTranslator<Model: Entity> {
    
    public required init() {}
    
    
    open func fill(_ entry: MutableDocument, fromEntity: Model) {
        fatalError("Abstract method")
    }
    
    
    open func fill(_ entity: Model, fromEntry: Document) {
        fatalError("Abstract method")
    }
    
    
    /// All properties of entities will be overridden by entries properties.
    /// If entry doesn't exist, it'll be created.
    ///
    /// - Parameters:
    ///   - entries: array of instances of `CouchbaseModel` type.
    ///   - fromEntities: array of instances of `Model` type.
    open func fill(_ entries: inout [Document], fromEntities: [Model]) {
        var newEntries = [Document]()
        
        fromEntities
            .map { entity -> (Document, Model) in
                
                let entry = entries
                    .filter { $0.id == entity.entityId }
                    .first
                
                if let entry = entry {
                    return (entry, entity)
                } else {
                    let entry = MutableDocument(id: entity.entityId)
                    newEntries.append(entry)
                    return (entry, entity)
                }
            }
            .forEach {
                self.fill($0.0.toMutable(), fromEntity: $0.1)
        }
        
        if fromEntities.count < entries.count {
            let entityIds = fromEntities.map { $0.entityId }
            let deletedEntriesIndexes = entries
                .filter { !entityIds.contains($0.id) }
            deletedEntriesIndexes.forEach {
                if let index = entries.index(of: $0) {
                    entries.remove(at: index)
                }
            }
        } else {
            entries.append(contentsOf: newEntries)
        }
    }
    
    
    /// All properties of entries will be overridden by entities properties.
    ///
    /// - Parameters:
    ///   - entities: array of instances of `Model` type.
    ///   - fromEntries: list of instances of `RealmModel` type.
    open func fill( _ entities: inout [Model], fromEntries: [Document]) {
        entities.removeAll()
        
        fromEntries.forEach {
            let model = Model()
            entities.append(model)
            self.fill(model, fromEntry: $0)
        }
    }
    
}

