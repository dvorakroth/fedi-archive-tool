//
//  DbInterface.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import Foundation
import SQLite

fileprivate class DbInterface {
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
    
    fileprivate static func getDb() throws -> Connection {
        if self.singletonInstance == nil {
            self.singletonInstance = try DbInterface()
        }
        
        return self.singletonInstance!.db
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
        
        try db.run(DbInterface.notes.create { t in
            t.column(DbInterface.note_id, primaryKey: true)
            t.column(DbInterface.note_published)
            t.column(DbInterface.note_url)
            t.column(DbInterface.note_replying_to_note_id)
            t.column(DbInterface.note_cw)
            t.column(DbInterface.note_content)
            t.column(DbInterface.note_sensitive)
        })
        
        try db.run(DbInterface.actions.create { t in
            t.column(DbInterface.action_id, primaryKey: true)
            t.column(DbInterface.action_actor_id)
            t.column(DbInterface.action_published)
            t.column(DbInterface.action_action_type)
            t.column(DbInterface.action_same_user_note_id)
            t.column(DbInterface.action_other_user_note_id)
            
            t.foreignKey(DbInterface.action_actor_id, references: DbInterface.actors, DbInterface.actor_id)
            t.foreignKey(DbInterface.action_same_user_note_id, references: DbInterface.notes, DbInterface.note_id)
        })
        
        try db.run(DbInterface.attachments.create { t in
            t.column(DbInterface.attachments_note_id)
            t.column(DbInterface.attachments_order_num)
            t.column(DbInterface.attachments_media_type)
            t.column(DbInterface.attachments_data)
            t.column(DbInterface.attachments_alt_text)
            t.column(DbInterface.attachments_blurhash)
            t.column(DbInterface.attachments_focal_point_x)
            t.column(DbInterface.attachments_focal_point_y)
            t.column(DbInterface.attachments_width)
            t.column(DbInterface.attachments_height)
            
            t.primaryKey(DbInterface.attachments_note_id, DbInterface.attachments_order_num)
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
    
    fileprivate static let actions = Table("actions")
    fileprivate static let action_id = Expression<String>("id")
    fileprivate static let action_actor_id = Expression<String>("actor_id")
    fileprivate static let action_published = Expression<Date>("published")
    fileprivate static let action_action_type = Expression<Int>("action_type")
    fileprivate static let action_same_user_note_id = Expression<String?>("same_user_note_id")
    fileprivate static let action_other_user_note_id = Expression<String?>("other_user_note_id")
    
    fileprivate static let notes = Table("notes")
    fileprivate static let note_id = Expression<String>("id")
    fileprivate static let note_published = Expression<Date>("published")
    fileprivate static let note_url = Expression<String>("url")
    fileprivate static let note_replying_to_note_id = Expression<String?>("replying_to_note_id")
    fileprivate static let note_cw = Expression<String?>("cw")
    fileprivate static let note_content = Expression<String>("content")
    fileprivate static let note_sensitive = Expression<Bool>("sensitive")
    
    fileprivate static let attachments = Table("attachments")
    fileprivate static let attachments_note_id = Expression<String>("note_id")
    fileprivate static let attachments_order_num = Expression<Int>("order_num")
    fileprivate static let attachments_media_type = Expression<String>("media_type")
    fileprivate static let attachments_data = Expression<SQLite.Blob?>("data")
    fileprivate static let attachments_alt_text = Expression<String?>("alt_text")
    fileprivate static let attachments_blurhash = Expression<String?>("blurhash")
    fileprivate static let attachments_focal_point_x = Expression<Double?>("focal_point_x")
    fileprivate static let attachments_focal_point_y = Expression<Double?>("focal_point_y")
    fileprivate static let attachments_width = Expression<Int?>("width")
    fileprivate static let attachments_height = Expression<Int?>("height")
    
    // TODO poll options
}

extension APubActor {
    static func fetchActor(byId id: String) throws -> APubActor? {
        let actorRow = try DbInterface.getDb().pluck(DbInterface.actors.where(DbInterface.actor_id == id))
        guard let actorRow = actorRow else {
            // nothing found
            return nil
        }
        
        return try actorRowToActor(actorRow)
    }
    
    static func fetchAllActors() throws -> [APubActor] {
        let actorsArr = try Array(try DbInterface.getDb().prepareRowIterator(DbInterface.actors))
        return try actorsArr.map(self.actorRowToActor)
    }
    
    func save() throws {
        let tableJson = String(
            data: try JSONSerialization.data(
                withJSONObject: table.map { (a, b) in [a, b] }
            ),
            encoding: .utf8
        )!
        
        try DbInterface.getDb().run(DbInterface.actors.insert(
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

extension APubActionEntry {
    static func fetchActionEntries(
        fromActorId actorId: String,
        matchingSearchString: String? = nil,
        toDateTimeExclusive: Date? = nil,
        maxNumberOfPosts: Int?
    ) throws -> [APubActionEntry] {
        let stringMatchCondition: Expression<Bool>
        if let matchingSearchString = matchingSearchString {
            stringMatchCondition = DbInterface.notes[DbInterface.note_content].like(
                "%"
                + escapeExpressionForSqlLike(
                    matchingSearchString,
                    usingEscapeChar: "\\"
                )
                + "%"
            )
        } else {
            stringMatchCondition = Expression(value: true)
        }
        
        let maxDateCondition: Expression<Bool>
        if let toDateTimeExclusive = toDateTimeExclusive {
            maxDateCondition = DbInterface.actions[DbInterface.action_published] < toDateTimeExclusive
        } else {
            maxDateCondition = Expression(value: true)
        }
        
        let entryRowsArr = try Array(try DbInterface.getDb().prepareRowIterator(
            DbInterface.actions
                .join(.leftOuter, DbInterface.notes, on: DbInterface.notes[DbInterface.note_id] == DbInterface.actions[DbInterface.action_same_user_note_id])
                .select(DbInterface.actions[*])
                .where(
                    stringMatchCondition && maxDateCondition && DbInterface.actions[DbInterface.action_actor_id] == actorId
                )
                .order(DbInterface.actions[DbInterface.action_published].desc)
                .limit(maxNumberOfPosts)
        ))
        
        return try entryRowsArr.map(self.actionEntryRowToActionEntry)
    }
    
    func save() throws {
        let actionType: Int;
        let ownNoteId: String?;
        let foreignNoteId: String?;
        
        switch self.action {
        case .create(let note):
            try note.save()
            actionType = 0
            ownNoteId = note.id
            foreignNoteId = nil
            
        case .announce(let noteId):
            actionType = 1
            
            if let _ = try APubNote.fetchNote(byId: noteId) {
                ownNoteId = noteId
                foreignNoteId = nil
            } else {
                ownNoteId = nil
                foreignNoteId = noteId
            }
        
        case .announceOwn(let note):
            try note.save()
            actionType = 1
            ownNoteId = note.id
            foreignNoteId = nil
        }
        
        try DbInterface.getDb().run(DbInterface.actions.insert(
            or: .replace,
            DbInterface.action_id <- self.id,
            DbInterface.action_actor_id <- self.actorId,
            DbInterface.action_published <- self.published,
            DbInterface.action_action_type <- actionType,
            DbInterface.action_same_user_note_id <- ownNoteId,
            DbInterface.action_other_user_note_id <- foreignNoteId
        ))
    }
    
    private static func actionEntryRowToActionEntry(_ actionEntryRow: Row) throws -> APubActionEntry {
        let id = actionEntryRow[DbInterface.action_id]
        let actorId = actionEntryRow[DbInterface.action_actor_id]
        let published = actionEntryRow[DbInterface.action_published]
        let actionType = actionEntryRow[DbInterface.action_action_type]
        let ownNoteId = actionEntryRow[DbInterface.action_same_user_note_id]
        let foreignNoteId = actionEntryRow[DbInterface.action_other_user_note_id]
        
        let action: APubAction
        switch actionType {
        case 0:
            action = .create(try APubNote.fetchNote(byId: ownNoteId!)!)
        case 1:
            if let ownNoteId = ownNoteId, let ownNote = try APubNote.fetchNote(byId: ownNoteId) {
                action = .announceOwn(ownNote)
            } else {
                action = .announce(ownNoteId ?? foreignNoteId!)
            }
        default:
            throw DbInterfaceError.unexpected("APubActionEntry \(id) has unrecognized action type: \(actionType)")
        }
        
        return APubActionEntry(id: id, actorId: actorId, published: published, action: action)
    }
}

extension APubNote {
    static func fetchNote(byId id: String) throws -> APubNote? {
        let noteRow = try DbInterface.getDb().pluck(DbInterface.notes.where(DbInterface.note_id == id))
        guard let noteRow = noteRow else {
            return nil
        }
        
        return try noteRowToNote(
            noteRow,
            withMediaAttachments: try APubDocument.fetchDocuments(forNote: id)
        )
    }
    
    func save() throws {
        // TODO delete and recreate poll options
        
        try DbInterface.getDb().run(DbInterface.notes.insert(
            or: .replace,
            DbInterface.note_id <- self.id,
            DbInterface.note_published <- self.published,
            DbInterface.note_url <- self.url,
            DbInterface.note_replying_to_note_id <- self.replyingToNoteId,
            DbInterface.note_cw <- self.cw,
            DbInterface.note_content <- self.content,
            DbInterface.note_sensitive <- self.sensitive
        ))
        
        try APubDocument.deleteDocuments(forNote: self.id)
        if let mediaAttachments = self.mediaAttachments {
            for (idx, attachment) in mediaAttachments.enumerated() {
                try attachment.save(withNoteId: id, orderNum: idx)
            }
        }
    }
    
    private static func noteRowToNote(
        _ noteRow: Row,
        withMediaAttachments mediaAttachments: [APubDocument]
    ) throws -> APubNote {
        // TODO poll options
        
        return APubNote(
            id: noteRow[DbInterface.note_id],
            published: noteRow[DbInterface.note_published],
            url: noteRow[DbInterface.note_url],
            replyingToNoteId: noteRow[DbInterface.note_replying_to_note_id],
            cw: noteRow[DbInterface.note_cw],
            content: noteRow[DbInterface.note_content],
            sensitive: noteRow[DbInterface.note_sensitive],
            mediaAttachments: mediaAttachments,
            pollOptions: nil
        )
    }
}

extension APubDocument {
    static func fetchDocuments(forNote noteId: String) throws -> [APubDocument] {
        let attachmentRows = try Array(try DbInterface.getDb().prepareRowIterator(
            DbInterface.attachments
                .where(DbInterface.attachments_note_id == noteId)
                .order(DbInterface.attachments_order_num)
        ))
        
        return try attachmentRows.map(self.attachmentRowToDocument)
    }
    
    static func deleteDocuments(forNote noteId: String) throws -> Void {
        let attachmentsForNote = DbInterface.attachments.filter(
            DbInterface.attachments_note_id == noteId
        )
        try DbInterface.getDb().run(attachmentsForNote.delete())
    }
    
    func save(withNoteId noteId: String, orderNum: Int) throws {
        try DbInterface.getDb().run(DbInterface.attachments.insert(
            or: .replace,
            DbInterface.attachments_note_id <- noteId,
            DbInterface.attachments_order_num <- orderNum,
            DbInterface.attachments_media_type <- self.mediaType,
            DbInterface.attachments_data <- self.data?.datatypeValue,
            DbInterface.attachments_alt_text <- self.altText,
            DbInterface.attachments_blurhash <- self.blurhash,
            DbInterface.attachments_focal_point_x <- self.focalPoint?.0,
            DbInterface.attachments_focal_point_y <- self.focalPoint?.1,
            DbInterface.attachments_width <- self.size?.0,
            DbInterface.attachments_height <- self.size?.1
        ))
    }
    
    private static func attachmentRowToDocument(_ attachmentRow: Row) throws -> APubDocument {
        let blob = attachmentRow[DbInterface.attachments_data]
        let data: Data?
        if let blob = blob {
            data = Data.fromDatatypeValue(blob)
        } else {
            data = nil
        }
        
        
        let focalPointX = attachmentRow[DbInterface.attachments_focal_point_x]
        let focalPointY = attachmentRow[DbInterface.attachments_focal_point_y]
        let focalPoint: (Double, Double)?
        if let focalPointX = focalPointX, let focalPointY = focalPointY {
            focalPoint = (focalPointX, focalPointY)
        } else {
            focalPoint = nil
        }
        
        let width = attachmentRow[DbInterface.attachments_width]
        let height = attachmentRow[DbInterface.attachments_height]
        let size: (Int, Int)?
        if let width = width, let height = height {
            size = (width, height)
        } else {
            size = nil
        }
        
        return APubDocument(
            mediaType: attachmentRow[DbInterface.attachments_media_type],
            data: data,
            altText: attachmentRow[DbInterface.attachments_alt_text],
            blurhash: attachmentRow[DbInterface.attachments_blurhash],
            focalPoint: focalPoint,
            size: size
        )
    }
}

enum DbInterfaceError: Error {
    case unexpected(String)
}
