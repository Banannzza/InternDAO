//
//  CouchbaseDAO.swift
//  InternDAO
//
//  Created by Алексей Остапенко on 24/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

open class CouchbaseDAO<Model: Entity>: DAO<Model> {
    
    // MARK: - Private
    
    private let database: Database
    private let translator: CouchbaseTranslator<Model>
    
    public init(translator: CouchbaseTranslator<Model>, databaseName: String = "Couchbase") throws {
        do {
            self.database = try Database(name: databaseName)
            self.translator = translator
        } catch {
            throw error
        }
    }
    
    public init(translator: CouchbaseTranslator<Model>, encryptionKey: String, databaseName: String = "Couchbase") throws {
        let config = DatabaseConfiguration()
        config.encryptionKey = EncryptionKey.password(encryptionKey)
        do {
            self.database = try Database(name: databaseName, config: config)
            self.translator = translator
        } catch {
            throw error
        }
    }
    
    // MARK: - DAO
    
    open override func persist(_ entity: Model) throws {
        if let document = database.document(withID: entity.entityId)?.toMutable() {
            self.translator.fill(document, fromEntity: entity)
            try self.database.saveDocument(document)
        } else {
            let newDocument = MutableDocument(id: entity.entityId)
            self.translator.fill(newDocument, fromEntity: entity)
            try self.database.saveDocument(newDocument)
        }
    }
    
    open override func persist(_ entities: [Model]) throws {
        var entries = [Document]()
        do {
            try self.database.inBatch {
                for entity in entities {
                    if let document = self.database.document(withID: entity.entityId) {
                        entries.append(document)
                    }
                }
                self.translator.fill(&entries, fromEntities: entities)
                for entry in entries {
                    try self.database.saveDocument(entry.toMutable())
                }
            }
        } catch {
            throw error
        }
    }
    
    open override func read() -> [Model] {
        let identifier = String(describing: Model.self)
        var entities = [Model]()
        var entries = [MutableDocument]()
        do {
            let result = try QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string(identifier)))
                .execute()
            for row in result {
                entries.append(MutableDocument().setData(row.toDictionary()))
            }
            self.translator.fill(&entities, fromEntries: entries)
            return entities
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
    
    open override func read(_ entityId: String) -> Model? {
        guard let document = self.database.document(withID: entityId) else { return nil }
        
        let entity = Model()
        self.translator.fill(entity, fromEntry: document)
        
        return entity
    }
    
    open override func erase(_ entityId: String) throws {
        guard let document = self.database.document(withID: entityId) else { return }
        do {
            try self.database.deleteDocument(document)
        } catch {
            throw error
        }
    }
    
    open override func erase() throws {
        let identifier = String(describing: Model.self)
        do {
            try self.database.inBatch {
                let result = try QueryBuilder
                    .select(SelectResult.expression(Meta.id))
                    .from(DataSource.database(database))
                    .where(Expression.property("type").equalTo(Expression.string(identifier)))
                    .execute()
                for row in result {
                    if let id = row.string(forKey: "id"), let document = self.database.document(withID: id) {
                        try self.database.deleteDocument(document)
                    }
                }
            }
        } catch {
            throw error
        }
    }
    
}
