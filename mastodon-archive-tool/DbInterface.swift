//
//  DbInterface.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import Foundation
import SQLite

class DbInterface {
    private static let DB_FILENAME = "app_db.sqlite"
    private static let CURRENT_DB_VERSION = 1
    fileprivate let db: Connection
    
    private init() throws {
        let containingDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        var dbFile: String
        if #available(iOS 16.0, *) {
            dbFile = containingDir.appending(path: DbInterface.DB_FILENAME).absoluteURL.path
        } else {
            dbFile = containingDir.appendingPathComponent(DbInterface.DB_FILENAME).absoluteURL.path
        }
        
        let dbAlreadyExists = FileManager.default.fileExists(atPath: dbFile)
        
        self.db = try Connection(dbFile)
        
        if (dbAlreadyExists) {
            try self.checkVersionAndHandleMigrations()
        } else {
            try self.createNewDb()
        }
    }
    
    private static var singletonInstance: DbInterface? = nil
    
    static func getDbInterface() throws -> DbInterface {
        if self.singletonInstance == nil {
            self.singletonInstance = try DbInterface()
        }
        
        return self.singletonInstance!
    }
    
    private func checkVersionAndHandleMigrations() throws {
        let version = try db.scalar("PRAGMA user_version;") as! Int64
        
        if (version > DbInterface.CURRENT_DB_VERSION) {
            throw DbInterfaceError.unexpected("This version of the app has a db version of \(DbInterface.CURRENT_DB_VERSION), but a database was found with version \(version)")
        }
        
        if (version < DbInterface.CURRENT_DB_VERSION) {
            // TODO if there's ever more than one version of this app, do stuff here!
        }
    }
    
    private func createNewDb() throws {
        try db.run("PRAGMA user_version = \(DbInterface.CURRENT_DB_VERSION);")
        
        try db.run(DbInterface.actors.create { t in
            t.column(DbInterface.actor_id, primaryKey: true)
            t.column(DbInterface.actor_username)
            t.column(DbInterface.actor_name)
            t.column(DbInterface.actor_bio)
            t.column(DbInterface.actor_url)
            t.column(DbInterface.actor_created)
            t.column(DbInterface.actor_table_json)
            t.column(DbInterface.actor_icon)
            t.column(DbInterface.actor_icon_type)
            t.column(DbInterface.actor_headerimage)
            t.column(DbInterface.actor_headerimage_type)
        })
    }
    
    fileprivate static let actors = Table("actors")
    fileprivate static let actor_id = Expression<String>("id")
    fileprivate static let actor_username = Expression<String>("username")
    fileprivate static let actor_name = Expression<String>("name")
    fileprivate static let actor_bio = Expression<String>("bio")
    fileprivate static let actor_url = Expression<String>("url")
    fileprivate static let actor_created = Expression<Date>("created")
    fileprivate static let actor_table_json = Expression<String>("table_json")
    fileprivate static let actor_icon = Expression<SQLite.Blob?>("icon")
    fileprivate static let actor_icon_type = Expression<String?>("icon_type")
    fileprivate static let actor_headerimage = Expression<SQLite.Blob?>("headerimage")
    fileprivate static let actor_headerimage_type = Expression<String?>("headerimage_type")
}

extension APubActor {
    static func fetchActor(byId id: String) throws -> APubActor? {
        let actorRow = try DbInterface.getDbInterface().db.pluck(DbInterface.actors.where(DbInterface.actor_id == id))
        guard let actorRow = actorRow else {
            // nothing found
            return nil
        }
        
        return try actorRowToActor(actorRow)
    }
    
    static func fetchAllActors() throws -> [APubActor] {
        let actorsArr = try Array(try DbInterface.getDbInterface().db.prepareRowIterator(DbInterface.actors))
        return try actorsArr.map(self.actorRowToActor)
    }
    
    func save() throws {
        let tableJson = String(
            data: try JSONSerialization.data(
                withJSONObject: table.map { (a, b) in [a, b] }
            ),
            encoding: .utf8
        )!
        
        try DbInterface.getDbInterface().db.run(DbInterface.actors.insert(
            or: .replace,
            DbInterface.actor_id <- id,
            DbInterface.actor_username <- username,
            DbInterface.actor_name <- name,
            DbInterface.actor_bio <- bio,
            DbInterface.actor_url <- url,
            DbInterface.actor_created <- created,
            DbInterface.actor_table_json <- tableJson,
            DbInterface.actor_icon <- icon?.0.datatypeValue,
            DbInterface.actor_icon_type <- icon?.1,
            DbInterface.actor_headerimage <- headerImage?.0.datatypeValue,
            DbInterface.actor_headerimage_type <- headerImage?.1
        ))
    }
    
    private static func actorRowToActor(_ actorRow: Row) throws -> APubActor {
        var table: [(String, String)] = []
        for row in try JSONSerialization.jsonObject(with: actorRow[DbInterface.actor_table_json].data(using: .utf8)!) as! [[String]] {
            table.append((row[0], row[1]))
        }
        
        let iconData = actorRow[DbInterface.actor_icon]
        let iconType = actorRow[DbInterface.actor_icon_type]
        let icon: (Data, String)?
        if let iconData = iconData, let iconType = iconType {
            icon = (Data.fromDatatypeValue(iconData), iconType)
        } else {
            icon = nil
        }
        
        let headerData = actorRow[DbInterface.actor_headerimage]
        let headerType = actorRow[DbInterface.actor_headerimage_type]
        let header: (Data, String)?
        if let headerData = headerData, let headerType = headerType {
            header = (Data.fromDatatypeValue(headerData), headerType)
        } else {
            header = nil
        }
        
        return APubActor(
            id: actorRow[DbInterface.actor_id],
            username: actorRow[DbInterface.actor_username],
            name: actorRow[DbInterface.actor_name],
            bio: actorRow[DbInterface.actor_bio],
            url: actorRow[DbInterface.actor_url],
            created: actorRow[DbInterface.actor_created],
            table: table,
            icon: icon,
            headerImage: header
        )
    }
}

enum DbInterfaceError: Error {
    case unexpected(String)
}
