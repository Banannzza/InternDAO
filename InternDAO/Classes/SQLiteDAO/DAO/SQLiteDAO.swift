//
//  SQLiteDAO.swift
//  InternDAO
//
//  Created by Алексей Остапенко on 25/02/2018.
//  Copyright © 2018 Алексей Остапенко. All rights reserved.
//

import UIKit
import SQLite3

open class SQLiteDAO<Model: Entity>: DAO<Model> {

    // MARK: - Property

    private let identifier = String(describing: Model.self)
    private let translator: SQLiteTranslator<Model>
    private let databasePath: URL!
    
    // Error
    enum SQLiteDatabaseError: Error {
        case openError
        case tableCreateError(String)
        case tableReadError(String)
        case tableInsertError
    }
    
    // MARK: - Constructor
    
    public init(translator: SQLiteTranslator<Model>, databasePath: String) throws {
        let fileURL = URL(fileURLWithPath: databasePath)
        self.translator = translator
        self.databasePath = fileURL
        super.init()
    }
    
    public init(translator: SQLiteTranslator<Model>, directory: FileManager.SearchPathDirectory = .documentDirectory) throws {
        let fileURL = try! FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("database.sqlite")
        self.translator = translator
        self.databasePath = fileURL
        super.init()
        do {
            try self.createTable()
        } catch {
            throw error
        }
    }
    
    // MARK: - DAO
    
    open override func persist(_ entity: Model) throws {
        try persist([entity])
    }
    
    open override func persist(_ entities: [Model]) throws {
        do {
            var entries = try self.readFromSQL()
            self.translator.fill(&entries, fromEntities: entities)
            try self.saveToSQLFast(entries: entries)
            //try self.saveToSQL(entries: entries)
        } catch {
            throw error
        }
    }
    
    open override func read() -> [Model] {
        do {
            let entries = try self.readFromSQL()
            var entity = [Model]()
            self.translator.fill(&entity, fromEntries: entries)
            return entity
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    open override func read(_ entityId: String) -> Model? {
        if let entry = try! self.readFromSQL(entityId) {
            let entity = Model()
            self.translator.fill(entity, fromEntry: entry)
            return entity
        } else {
            return nil
        }
    }

    open override func erase(_ entityId: String) throws {
        do {
            try self.removeRecord(withUuid: entityId)
        } catch {
            throw error
        }
    }

    open override func erase() throws {
        do {
            try self.removeAllRecords()
        } catch {
            throw error
        }
    }
    
    
    // MARK: - SQL Accessors
    
    private func createTable() throws {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        if sqlite3_exec(databasePointer, "CREATE TABLE IF NOT EXISTS \(identifier) (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT NOT NULL, uuid TEXT NOT NULL)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableCreateError(errmsg)
        }
    }
    
    private func removeRecord(withUuid uuid: String) throws {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        let queryString = "DELETE FROM \(identifier) WHERE uuid = \"\(uuid)\""
        
        if sqlite3_exec(databasePointer, queryString, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        sqlite3_close(databasePointer)
    }
    
    private func removeAllRecords() throws {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        let queryString = "DELETE FROM \(identifier)"

        if sqlite3_exec(databasePointer, queryString, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
    }
    
    private func readFromSQL(_ entryId: String) throws -> SQLiteEntry? {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        let queryString = "SELECT * FROM \(identifier) WHERE uuid = \"\(entryId)\""
        var readStatement: OpaquePointer?
        
        if sqlite3_prepare(databasePointer, queryString, -1, &readStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        
        while(sqlite3_step(readStatement) == SQLITE_ROW){
            let uuid = String(cString: sqlite3_column_text(readStatement, 2))
            let jsonString = String(cString: sqlite3_column_text(readStatement, 1))
            if let data = jsonString.data(using: .utf8) {
                do {
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        throw SQLiteDatabaseError.tableReadError("Bad Data")
                    }
                    return SQLiteEntry(id: uuid, info: dictionary)
                } catch {
                    throw error
                }
            }
        }
        sqlite3_finalize(readStatement)
        return nil
    }
    
    private func readFromSQL() throws -> [SQLiteEntry] {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        var result = [SQLiteEntry]()
        let queryString = "SELECT * FROM \(identifier)"
        var readStatement: OpaquePointer?
        
        if sqlite3_prepare(databasePointer, queryString, -1, &readStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        
        while(sqlite3_step(readStatement) == SQLITE_ROW){
            let uuid = String(cString: sqlite3_column_text(readStatement, 2))
            let jsonString = String(cString: sqlite3_column_text(readStatement, 1))
            if let data = jsonString.data(using: .utf8) {
                do {
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String : Any] else {
                        throw SQLiteDatabaseError.tableReadError("Bad Data")
                    }
                    result.append(SQLiteEntry(id: uuid, info: dictionary))
                } catch {
                    throw error
                }
            }
        }
        sqlite3_finalize(readStatement)
        return result
    }
    
    func saveToSQLSlow(entries: [SQLiteEntry]) throws {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        var insertStatement: OpaquePointer? = nil

        if sqlite3_exec(databasePointer, "CREATE UNIQUE INDEX IF NOT EXISTS idx_uuid ON \(identifier) (uuid)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
    
        let insertStatementString = "INSERT OR REPLACE INTO \(identifier) (data, uuid) VALUES (?, ?);"
        if sqlite3_prepare_v2(databasePointer, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            for (_, entry) in entries.enumerated(){
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: entry.dictionary, options: [])
                    let dataString = String(data: jsonData, encoding: .utf8)! as NSString
                    let uuid = (entry.entryId as NSString)
                    sqlite3_bind_text(insertStatement, 1, dataString.utf8String, -1, nil)
                    sqlite3_bind_text(insertStatement, 2, uuid.utf8String, -1, nil)
                    
                    if sqlite3_step(insertStatement) != SQLITE_DONE {
                        throw SQLiteDatabaseError.tableInsertError
                    }
                    sqlite3_reset(insertStatement)
                } catch {
                    throw error
                }
            }
            sqlite3_finalize(insertStatement)
        } else {
            throw SQLiteDatabaseError.tableInsertError
        }
    }
    
    func saveToSQLFast(entries: [SQLiteEntry]) throws {
        var databasePointer: OpaquePointer?
        if sqlite3_open(databasePath.path, &databasePointer) != SQLITE_OK {
            throw SQLiteDatabaseError.openError
        }
        defer { sqlite3_close(databasePointer) }
        
        if sqlite3_exec(databasePointer, "CREATE UNIQUE INDEX IF NOT EXISTS idx_uuid ON \(identifier) (uuid)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        
        if sqlite3_exec(databasePointer, "BEGIN TRANSACTION;", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        
        var insertSQL = ""
        for (_, entry) in entries.enumerated(){
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: entry.dictionary, options: [])
                let dataString = String(data: jsonData, encoding: .utf8)! as NSString
                let uuid = (entry.entryId as NSString)
                insertSQL += "INSERT OR REPLACE INTO \(identifier) (data, uuid) VALUES ('\(dataString)', '\(uuid)');\n"
            } catch {
                throw error
            }
        }
        
        if sqlite3_exec(databasePointer, insertSQL, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
        
        if sqlite3_exec(databasePointer, "COMMIT;", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(databasePointer)!)
            throw SQLiteDatabaseError.tableReadError(errmsg)
        }
    }
}

