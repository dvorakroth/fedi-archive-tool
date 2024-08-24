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
    
    private let db: Connection
    
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
        
        /// > Assuming the library is compiled with foreign key constraints enabled, it must still be enabled by the application at runtime, using the PRAGMA foreign_keys command. For example:
        /// > `sqlite> PRAGMA foreign_keys = ON;`
        /// > Foreign key constraints are disabled by default (for backwards compatibility), so must be enabled separately **for each database connection.**
        ///
        /// — Excerpt from [SQLite Docs, Foreign Keys, Section 2](https://www.sqlite.org/foreignkeys.html#fk_enable) (emphasis added)
        try db.run("PRAGMA foreign_keys = ON;")
        
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
        
        try db.run(actors.create { t in
            t.column(actor_id, primaryKey: true)
            t.column(actor_username)
            t.column(actor_name)
            t.column(actor_bio)
            t.column(actor_url)
            t.column(actor_created)
            t.column(actor_table_json)
            t.column(actor_icon)
            t.column(actor_icon_type)
            t.column(actor_headerimage)
            t.column(actor_headerimage_type)
        })
        
        try db.run(notes.create { t in
            t.column(note_id, primaryKey: true)
            t.column(note_actor_id)
            t.column(note_published)
            t.column(note_visibility)
            t.column(note_url)
            t.column(note_replying_to_note_id)
            t.column(note_cw)
            t.column(note_content)
            t.column(note_sensitive)
            
            t.foreignKey(note_actor_id, references: actors, actor_id, delete: .cascade)
        })
        
        try db.run(actions.create { t in
            t.column(action_id, primaryKey: true)
            t.column(action_actor_id)
            t.column(action_published)
            t.column(action_action_type)
            t.column(action_same_user_note_id)
            t.column(action_other_user_note_id)
            
            t.foreignKey(action_actor_id, references: actors, actor_id, delete: .cascade)
            t.foreignKey(action_same_user_note_id, references: notes, note_id, delete: .cascade)
        })
        
        try db.run(attachments.create { t in
            t.column(attachments_note_id)
            t.column(attachments_order_num)
            t.column(attachments_media_type)
            t.column(attachments_data)
            t.column(attachments_alt_text)
            t.column(attachments_blurhash)
            t.column(attachments_focal_point_x)
            t.column(attachments_focal_point_y)
            t.column(attachments_width)
            t.column(attachments_height)
            
            t.primaryKey(attachments_note_id, attachments_order_num)
            t.foreignKey(attachments_note_id, references: notes, note_id, delete: .cascade)
        })
        
        try db.run(pollOptions.create { t in
            t.column(pollOptions_note_id)
            t.column(pollOptions_order_num)
            t.column(pollOptions_name)
            t.column(pollOptions_num_votes)
            
            t.primaryKey(pollOptions_note_id, pollOptions_order_num)
            t.foreignKey(pollOptions_note_id, references: notes, note_id, delete: .cascade)
        })
    }
}

fileprivate let actors = Table("actors")
fileprivate let actor_id = Expression<String>("id")
fileprivate let actor_username = Expression<String>("username")
fileprivate let actor_name = Expression<String>("name")
fileprivate let actor_bio = Expression<String>("bio")
fileprivate let actor_url = Expression<String>("url")
fileprivate let actor_created = Expression<Date>("created")
fileprivate let actor_table_json = Expression<String>("table_json")
fileprivate let actor_icon = Expression<SQLite.Blob?>("icon")
fileprivate let actor_icon_type = Expression<String?>("icon_type")
fileprivate let actor_headerimage = Expression<SQLite.Blob?>("headerimage")
fileprivate let actor_headerimage_type = Expression<String?>("headerimage_type")

fileprivate let actions = Table("actions")
fileprivate let action_id = Expression<String>("id")
fileprivate let action_actor_id = Expression<String>("actor_id")
fileprivate let action_published = Expression<Date>("published")
fileprivate let action_action_type = Expression<Int>("action_type")
fileprivate let action_same_user_note_id = Expression<String?>("same_user_note_id")
fileprivate let action_other_user_note_id = Expression<String?>("other_user_note_id")

fileprivate let notes = Table("notes")
fileprivate let note_id = Expression<String>("id")
fileprivate let note_actor_id = Expression<String>("actor_id")
fileprivate let note_published = Expression<Date>("published")
fileprivate let note_visibility = Expression<APubNoteVisibilityLevel.RawValue>("visibility")
fileprivate let note_url = Expression<String>("url")
fileprivate let note_replying_to_note_id = Expression<String?>("replying_to_note_id")
fileprivate let note_cw = Expression<String?>("cw")
fileprivate let note_content = Expression<String>("content")
fileprivate let note_sensitive = Expression<Bool>("sensitive")

fileprivate let attachments = Table("attachments")
fileprivate let attachments_note_id = Expression<String>("note_id")
fileprivate let attachments_order_num = Expression<Int>("order_num")
fileprivate let attachments_media_type = Expression<String>("media_type")
fileprivate let attachments_data = Expression<SQLite.Blob?>("data")
fileprivate let attachments_alt_text = Expression<String?>("alt_text")
fileprivate let attachments_blurhash = Expression<String?>("blurhash")
fileprivate let attachments_focal_point_x = Expression<Double?>("focal_point_x")
fileprivate let attachments_focal_point_y = Expression<Double?>("focal_point_y")
fileprivate let attachments_width = Expression<Int?>("width")
fileprivate let attachments_height = Expression<Int?>("height")

fileprivate let pollOptions = Table("pollOptions")
fileprivate let pollOptions_note_id = Expression<String>("note_id")
fileprivate let pollOptions_order_num = Expression<Int>("order_num")
fileprivate let pollOptions_name = Expression<String>("name")
fileprivate let pollOptions_num_votes = Expression<Int>("num_votes")


extension APubActor {
    static func fetchActor(byId id: String) throws -> APubActor? {
        let actorRow = try DbInterface.getDb().pluck(actors.where(actor_id == id))
        guard let actorRow = actorRow else {
            // nothing found
            return nil
        }
        
        return try APubActor(fromRow: actorRow)
    }
    
    static func fetchAllActors() throws -> [APubActor] {
        let actorsArr = try Array(try DbInterface.getDb().prepareRowIterator(
            actors
                .order(actor_username)
        ))
        return try actorsArr.map(APubActor.init(fromRow:))
    }
    
    func save() throws {
        let tableJson = String(
            data: try JSONSerialization.data(
                withJSONObject: table.map { (a, b) in [a, b] }
            ),
            encoding: .utf8
        )!
        
        try DbInterface.getDb().run(actors.insert(
            or: .replace,
            actor_id <- id,
            actor_username <- username,
            actor_name <- name,
            actor_bio <- bio,
            actor_url <- url,
            actor_created <- created,
            actor_table_json <- tableJson,
            actor_icon <- icon?.0.datatypeValue,
            actor_icon_type <- icon?.1,
            actor_headerimage <- headerImage?.0.datatypeValue,
            actor_headerimage_type <- headerImage?.1
        ))
    }
    
    static func deleteActors(withIds actorIds: [String]) throws {
        try DbInterface.getDb().transaction {
            try DbInterface.getDb().run(
                // all of the other related objects (actions, notes, etc) all have FOREIGN KEYs with ON DELETE CASCADE so it should be fine?
                actors.filter(actorIds.contains(actor_id)).delete()
            )
        }
    }
    
    private convenience init(fromRow actorRow: Row) throws {
        var table: [(String, String)] = []
        for row in try JSONSerialization.jsonObject(with: actorRow[actor_table_json].data(using: .utf8)!) as! [[String]] {
            table.append((row[0], row[1]))
        }
        
        let iconData = actorRow[actor_icon]
        let iconType = actorRow[actor_icon_type]
        let icon: (Data, String)?
        if let iconData = iconData, let iconType = iconType {
            icon = (Data.fromDatatypeValue(iconData), iconType)
        } else {
            icon = nil
        }
        
        let headerData = actorRow[actor_headerimage]
        let headerType = actorRow[actor_headerimage_type]
        let header: (Data, String)?
        if let headerData = headerData, let headerType = headerType {
            header = (Data.fromDatatypeValue(headerData), headerType)
        } else {
            header = nil
        }
        
        self.init(
            id: actorRow[actor_id],
            username: actorRow[actor_username],
            name: actorRow[actor_name],
            bio: actorRow[actor_bio],
            url: actorRow[actor_url],
            created: actorRow[actor_created],
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
        maxNumberOfPosts: Int? = nil,
        includeAnnounces: Bool = true
    ) throws -> [APubActionEntry] {
        let stringMatchCondition: Expression<Bool>
        if let matchingSearchString = matchingSearchString {
            stringMatchCondition = notes[note_content].like(
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
            maxDateCondition = actions[action_published] < toDateTimeExclusive
        } else {
            maxDateCondition = Expression(value: true)
        }
        
        let actionTypeCondition: Expression<Bool>
        if includeAnnounces {
            actionTypeCondition = Expression(value: true)
        } else {
            actionTypeCondition = actions[action_action_type] != 1
        }
        
        let entryRowsArr = try Array(try DbInterface.getDb().prepareRowIterator(
            actions
                .join(.leftOuter, notes, on: notes[note_id] == actions[action_same_user_note_id])
                .select(actions[*])
                .where(
                    stringMatchCondition
                        && maxDateCondition
                        && actionTypeCondition
                        && actions[action_actor_id] == actorId
                )
                .order(actions[action_published].desc)
                .limit(maxNumberOfPosts)
        ))
        
        return try entryRowsArr.map(APubActionEntry.init(fromRow:))
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
        
        try DbInterface.getDb().run(actions.insert(
            or: .replace,
            action_id <- self.id,
            action_actor_id <- self.actorId,
            action_published <- self.published,
            action_action_type <- actionType,
            action_same_user_note_id <- ownNoteId,
            action_other_user_note_id <- foreignNoteId
        ))
    }
    
    fileprivate convenience init(fromRow actionEntryRow: Row) throws {
        let id = actionEntryRow[action_id]
        let actorId = actionEntryRow[action_actor_id]
        let published = actionEntryRow[action_published]
        let actionType = actionEntryRow[action_action_type]
        let ownNoteId = actionEntryRow[action_same_user_note_id]
        let foreignNoteId = actionEntryRow[action_other_user_note_id]
        
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
        
        self.init(id: id, actorId: actorId, published: published, action: action)
    }
}

extension APubNote {
    static func fetchNote(byId id: String) throws -> APubNote? {
        let noteRow = try DbInterface.getDb().pluck(notes.where(note_id == id))
        guard let noteRow = noteRow else {
            return nil
        }
        
        return try APubNote(
            fromRow: noteRow,
            withMediaAttachments: try APubDocument.fetchDocuments(forNote: id),
            pollOptions: try APubPollOption.fetchPollOptions(forNote: id)
        )
    }
    
    func save() throws {
        try DbInterface.getDb().run(notes.insert(
            or: .replace,
            note_id <- self.id,
            note_actor_id <- self.actorId,
            note_published <- self.published,
            note_visibility <- self.visibilityLevel.rawValue,
            note_url <- self.url,
            note_replying_to_note_id <- self.replyingToNoteId,
            note_cw <- self.cw,
            note_content <- self.content,
            note_sensitive <- self.sensitive
        ))
        
        try APubDocument.deleteDocuments(forNote: self.id)
        if let mediaAttachments = self.mediaAttachments {
            for (idx, attachment) in mediaAttachments.enumerated() {
                try attachment.save(withNoteId: id, orderNum: idx)
            }
        }
        
        try APubPollOption.deletePollOptions(forNote: self.id)
        if let pollOptions = self.pollOptions {
            for (idx, pollOption) in pollOptions.enumerated() {
                try pollOption.save(withNoteId: id, orderNum: idx)
            }
        }
    }
    
    private convenience init(
        fromRow noteRow: Row,
        withMediaAttachments mediaAttachments: [APubDocument],
        pollOptions: [APubPollOption]
    ) throws {
        self.init(
            id: noteRow[note_id],
            actorId: noteRow[note_actor_id],
            published: noteRow[note_published],
            visibilityLevel: APubNoteVisibilityLevel(rawValue: noteRow[note_visibility]) ?? .unknown,
            url: noteRow[note_url],
            replyingToNoteId: noteRow[note_replying_to_note_id],
            cw: noteRow[note_cw],
            content: noteRow[note_content],
            sensitive: noteRow[note_sensitive],
            mediaAttachments: mediaAttachments,
            pollOptions: pollOptions
        )
    }
}

extension APubDocument {
    static func fetchDocuments(forNote noteId: String) throws -> [APubDocument] {
        let attachmentRows = try Array(try DbInterface.getDb().prepareRowIterator(
            attachments
                .where(attachments_note_id == noteId)
                .order(attachments_order_num)
        ))
        
        return try attachmentRows.map(APubDocument.init(withRow:))
    }
    
    static func fetchDocuments(
        forActor actorId: String,
        toDateTimeExclusive: Date? = nil,
        maxNumberOfPosts: Int?
    ) throws -> [(APubDocument, APubActionEntry)] {
        let maxDateCondition: Expression<Bool>
        if let toDateTimeExclusive = toDateTimeExclusive {
            maxDateCondition = actions[action_published] < toDateTimeExclusive
        } else {
            maxDateCondition = Expression(value: true)
        }
        
        let rows = try Array(try DbInterface.getDb().prepareRowIterator(
            attachments
                .join(actions, on: actions[action_id] == attachments[attachments_note_id])
                .where(
                    actions[action_actor_id] == actorId
                    && actions[action_action_type] == 0
                    && maxDateCondition
                )
                .order(
                    actions[action_published].desc,
                    attachments[attachments_order_num].asc
                )
                .limit(maxNumberOfPosts)
        ))
        
        return try rows.map { row in
            (try APubDocument(withRow: row), try APubActionEntry(fromRow: row))
        }
    }
    
    static func deleteDocuments(forNote noteId: String) throws -> Void {
        let attachmentsForNote = attachments.filter(
            attachments_note_id == noteId
        )
        try DbInterface.getDb().run(attachmentsForNote.delete())
    }
    
    func save(withNoteId noteId: String, orderNum: Int) throws {
        try DbInterface.getDb().run(attachments.insert(
            or: .replace,
            attachments_note_id <- noteId,
            attachments_order_num <- orderNum,
            attachments_media_type <- self.mediaType,
            attachments_data <- self.data?.datatypeValue,
            attachments_alt_text <- self.altText,
            attachments_blurhash <- self.blurhash,
            attachments_focal_point_x <- self.focalPoint?.0,
            attachments_focal_point_y <- self.focalPoint?.1,
            attachments_width <- self.size?.0,
            attachments_height <- self.size?.1
        ))
    }
    
    private convenience init(withRow attachmentRow: Row) throws {
        let blob = attachmentRow[attachments_data]
        let data: Data?
        if let blob = blob {
            data = Data.fromDatatypeValue(blob)
        } else {
            data = nil
        }
        
        
        let focalPointX = attachmentRow[attachments_focal_point_x]
        let focalPointY = attachmentRow[attachments_focal_point_y]
        let focalPoint: (Double, Double)?
        if let focalPointX = focalPointX, let focalPointY = focalPointY {
            focalPoint = (focalPointX, focalPointY)
        } else {
            focalPoint = nil
        }
        
        let width = attachmentRow[attachments_width]
        let height = attachmentRow[attachments_height]
        let size: (Int, Int)?
        if let width = width, let height = height {
            size = (width, height)
        } else {
            size = nil
        }
        
        self.init(
            mediaType: attachmentRow[attachments_media_type],
            data: data,
            altText: attachmentRow[attachments_alt_text],
            blurhash: attachmentRow[attachments_blurhash],
            focalPoint: focalPoint,
            size: size
        )
    }
}

extension APubPollOption {
    static func fetchPollOptions(forNote noteId: String) throws -> [APubPollOption] {
        let pollOptionRows = try Array(try DbInterface.getDb().prepareRowIterator(
            pollOptions
                .where(pollOptions_note_id == noteId)
                .order(pollOptions_order_num)
        ))
        
        return try pollOptionRows.map(Self.init(fromRow:))
    }
    
    static func deletePollOptions(forNote noteId: String) throws -> Void {
        let pollOptionsForNote = pollOptions.filter(
            pollOptions_note_id == noteId
        )
        try DbInterface.getDb().run(pollOptionsForNote.delete())
    }
    
    func save(withNoteId noteId: String, orderNum: Int) throws {
        try DbInterface.getDb().run(pollOptions.insert(
            or: .replace,
            pollOptions_note_id <- noteId,
            pollOptions_order_num <- orderNum,
            pollOptions_name <- self.name,
            pollOptions_num_votes <- self.numVotes
        ))
    }
    
    private init(fromRow pollOptionRow: Row) throws {
        self.init(
            name: pollOptionRow[pollOptions_name],
            numVotes: pollOptionRow[pollOptions_num_votes]
        )
    }
}

enum DbInterfaceError: Error {
    case unexpected(String)
}
