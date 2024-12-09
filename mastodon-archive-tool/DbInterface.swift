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
    fileprivate static let MEDIA_DIR = "mediaPerActor"
    private static let CURRENT_DB_VERSION = 1
    
    private let db: Connection
    
    private init() throws {
        let containingDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dbFile: String = containingDir.appendingPathComponentNonDeprecated(DbInterface.DB_FILENAME).absoluteURL.path
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
            t.column(actor_icon_path)
            t.column(actor_icon_type)
            t.column(actor_headerimage_path)
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
            t.column(note_searchable_content)
            t.column(note_sensitive)
            t.column(note_poll_end_time)
            t.column(note_poll_is_closed)
            
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
            t.column(attachments_data_path)
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
fileprivate let actor_icon_path = Expression<String?>("icon_path")
fileprivate let actor_icon_type = Expression<String?>("icon_type")
fileprivate let actor_headerimage_path = Expression<String?>("headerimage_path")
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
fileprivate let note_searchable_content = Expression<String>("searchable_content")
fileprivate let note_sensitive = Expression<Bool>("sensitive")
fileprivate let note_poll_end_time = Expression<Date?>("poll_end_time")
fileprivate let note_poll_is_closed = Expression<Bool?>("poll_is_closed")

fileprivate let attachments = Table("attachments")
fileprivate let attachments_note_id = Expression<String>("note_id")
fileprivate let attachments_order_num = Expression<Int>("order_num")
fileprivate let attachments_media_type = Expression<String>("media_type")
fileprivate let attachments_data_path = Expression<String>("data_path")
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

fileprivate func directoryForSavingMedia(actorId: String, namePrefix: String? = nil, createIfDoesntExist: Bool = true) throws -> URL {
    let containingDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let mediaDir = containingDir.appendingPathComponentNonDeprecated(DbInterface.MEDIA_DIR)
    try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
    
    let actorIdAsHex = actorId.data(using: .utf8)!.hexString
    let actorMediaDir = mediaDir.appendingPathComponentNonDeprecated((namePrefix ?? "") + actorIdAsHex)
    
    if createIfDoesntExist {
        try FileManager.default.createDirectory(at: actorMediaDir, withIntermediateDirectories: true)
    }
    
    return actorMediaDir
}

func urlForMedia(atPath path: String, forActorId actorId: String) -> URL? {
    let actorMediaDir: URL
    
    do {
        actorMediaDir = try directoryForSavingMedia(actorId: actorId)
    } catch {
        print("Getting media directory for actorId \(actorId) encountered an error: \(error)")
        return nil
    }
    
    return actorMediaDir.appendingPathComponentNonDeprecated(path)
}

fileprivate func readMedia(atPath path: String, forActorId actorId: String) -> Data? {
    let mediaUrl = urlForMedia(atPath: path, forActorId: actorId)
    guard let mediaUrl = mediaUrl else {
        return nil
    }
    
    do {
        return try Data(contentsOf: mediaUrl)
    } catch {
        print("Reading media file at \(mediaUrl) encountered an error: \(error)")
        return nil
    }
}

class ActorList: ObservableObject {
    @Published var actors: [APubActor] = []
    
    private init() {}
    static let shared = ActorList()
    
    func forceRefresh() throws {
        self.actors = try APubActor.fetchAllActors()
    }
}

extension APubOutbox {
    func atomicSave() throws {
        try DbInterface.getDb().transaction {
            try DbInterface.getDb().run(
                actors.where(actor_id == self.actor.id).delete()
            )
            
            try self.actor.save()
            for actionEntry in self.orderedItems {
                try actionEntry.save()
            }
            
            try saveAllMedia()
        }
        
        DispatchQueue.main.schedule {
            do {
                try ActorList.shared.forceRefresh()
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func saveAllMedia() throws {
        let mediaDirFinal = try directoryForSavingMedia(actorId: self.actor.id, createIfDoesntExist: false)
        let mediaDirTmpInWriting = try directoryForSavingMedia(actorId: self.actor.id, namePrefix: "TMP_IN_WRITING_" + UUID().uuidString + "_")
        var mediaDirTmpInDeletion: URL? = nil
        defer {
            if FileManager.default.fileExists(atPath: mediaDirTmpInWriting.path) {
                do {
                    try FileManager.default.removeItem(at: mediaDirTmpInWriting)
                } catch {
                    print("Error trying to delete \(mediaDirTmpInWriting): \(error)")
                }
            }
            
            if let mediaDirTmp2 = mediaDirTmpInDeletion {
                if FileManager.default.fileExists(atPath: mediaDirTmp2.path) {
                    do {
                        try FileManager.default.removeItem(at: mediaDirTmp2)
                    } catch {
                        print("Error trying to delete \(mediaDirTmp2): \(error)")
                    }
                }
            }
        }
        
        // profile & header pics
        try self.actor.saveAllMedia(to: mediaDirTmpInWriting)
        
        // posts
        for actionEntry in self.orderedItems {
            try actionEntry.saveAllMedia(to: mediaDirTmpInWriting)
        }
        
        if FileManager.default.fileExists(atPath: mediaDirFinal.path) {
            mediaDirTmpInDeletion = try directoryForSavingMedia(
                actorId: self.actor.id,
                namePrefix: "TMP_IN_DELETION_" + UUID().uuidString + "_",
                createIfDoesntExist: false
            )
            try FileManager.default.moveItem(at: mediaDirFinal, to: mediaDirTmpInDeletion!)
        }
        
        do {
            try FileManager.default.moveItem(at: mediaDirTmpInWriting, to: mediaDirFinal)
        } catch {
            print("Error moving \(mediaDirTmpInWriting) to \(mediaDirFinal), trying to rollback")
            
            if let mediaDirTmp2_ = mediaDirTmpInDeletion {
                try FileManager.default.moveItem(at: mediaDirTmp2_, to: mediaDirFinal)
                mediaDirTmpInDeletion = nil
            }
            
            throw error
        }
    }
}

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
    
    fileprivate func save() throws {
        let tableJson = String(
            data: try JSONSerialization.data(
                withJSONObject: table.map { (a, b) in [a, b] }
            ),
            encoding: .utf8
        )!
        
        try DbInterface.getDb().run(actors.upsert(
            actor_id <- id,
            actor_username <- username,
            actor_name <- name,
            actor_bio <- bio,
            actor_url <- url,
            actor_created <- created,
            actor_table_json <- tableJson,
            actor_icon_path <- icon?.path,
            actor_icon_type <- icon?.mediaType,
            actor_headerimage_path <- headerImage?.path,
            actor_headerimage_type <- headerImage?.mediaType,
            onConflictOf: actor_id
        ))
    }
    
    static func deleteActors(withIds actorIds: [String]) throws {
        try DbInterface.getDb().transaction {
            try DbInterface.getDb().run(
                // all of the other related objects (actions, notes, etc) all have FOREIGN KEYs with ON DELETE CASCADE so it should be fine?
                actors.filter(actorIds.contains(actor_id)).delete()
            )
        }
        
        // delete all of these actors' media from the filesystem too
        for actorId in actorIds {
            let mediaDir = try directoryForSavingMedia(actorId: actorId)
            if FileManager.default.fileExists(atPath: mediaDir.normalPath) {
                try FileManager.default.removeItem(at: mediaDir)
            }
        }
    }
    
    private convenience init(fromRow actorRow: Row) throws {
        let actorId = actorRow[actor_id]
        
        var table: [(String, String)] = []
        for row in try JSONSerialization.jsonObject(with: actorRow[actor_table_json].data(using: .utf8)!) as! [[String]] {
            table.append((row[0], row[1]))
        }
        
        let iconPath = actorRow[actor_icon_path]
        let iconType = actorRow[actor_icon_type]
        let icon: (data: Data, path: String, mediaType: String)?
        if let iconPath = iconPath, let iconType = iconType, let iconData = readMedia(atPath: iconPath, forActorId: actorId) {
            icon = (data: iconData, path: iconPath, mediaType: iconType)
        } else {
            icon = nil
        }
        
        let headerPath = actorRow[actor_headerimage_path]
        let headerType = actorRow[actor_headerimage_type]
        let header: (data: Data, path: String, mediaType: String)?
        if let headerPath = headerPath, let headerType = headerType, let headerData = readMedia(atPath: headerPath, forActorId: actorId) {
            header = (data: headerData, path: headerPath, mediaType: headerType)
        } else {
            header = nil
        }
        
        self.init(
            id: actorId,
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
    
    fileprivate func saveAllMedia(to mediaDir: URL) throws {
        if let (data, path, _) = self.icon {
            let iconPath = mediaDir.appendingPathComponentNonDeprecated(path)
            try data.write(to: iconPath, creatingDirectory: true)
        }
        
        if let (data, path, _) = self.headerImage {
            let headerPath = mediaDir.appendingPathComponentNonDeprecated(path)
            try data.write(to: headerPath, creatingDirectory: true)
        }
    }
}

extension APubActionEntry {
    static func fetchActionEntries(
        fromActorId actorId: String,
        matchingSearchString: String? = nil,
        toDateTimeExclusive: Date? = nil,
        maxNumberOfPosts: Int? = nil,
        includeAnnounces: Bool = true,
        includeReplies: Bool = true,
        onlyIncludePostsWithMedia: Bool = false,
        onlyDMs: Bool = false
    ) throws -> [APubActionEntry] {
        let stringMatchCondition: Expression<Bool>
        if let matchingSearchString = matchingSearchString {
            let substringExp =
            "%"
            + escapeExpressionForSqlLike(
                matchingSearchString,
                usingEscapeChar: "\\"
            )
            + "%"
            
            stringMatchCondition =
            notes[note_searchable_content].like(substringExp) ||
            (notes[note_cw] ?? Expression(value: "")).like(substringExp) ||
            Expression("EXISTS(SELECT 1 FROM attachments WHERE attachments.note_id = notes.id AND attachments.alt_text IS NOT NULL AND attachments.alt_text LIKE ? LIMIT 1)", [substringExp]) ||
            Expression("EXISTS(SELECT 1 FROM pollOptions WHERE pollOptions.note_id = notes.id AND pollOptions.name LIKE ? LIMIT 1)", [substringExp])
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
        
        let repliesCondition: Expression<Bool>
        if includeReplies {
            repliesCondition = Expression(value: true)
        } else {
            repliesCondition = (
                actions[action_action_type] == 1 || // either this is an announce
                notes[note_replying_to_note_id] ?? "NIL" == "NIL" // or this is not a reply
                // using `?? "NIL"` to do the NULL comparison because SQLite.Swift is all weird about using `=== nil` and returns an `Expression<Bool?>` instead of `Expression<Bool>`
            )
        }
        
        let mediaCondition: Expression<Bool>
        if onlyIncludePostsWithMedia {
            mediaCondition = Expression("EXISTS(SELECT 1 FROM attachments WHERE attachments.note_id = notes.id LIMIT 1)", [])
        } else {
            mediaCondition = Expression(value: true)
        }
        
        let dmsCondition: Expression<Bool>
        if onlyDMs {
            dmsCondition = notes[note_visibility] == APubNoteVisibilityLevel.dm.rawValue
        } else {
            dmsCondition = Expression(value: true)
        }
        
        let entryRowsArr = try Array(try DbInterface.getDb().prepareRowIterator(
            actions
                .join(.leftOuter, notes, on: notes[note_id] == (actions[action_same_user_note_id] ?? actions[action_other_user_note_id]))
                .select(actions[*], notes[*])
                .where(
                    stringMatchCondition
                    && maxDateCondition
                    && actionTypeCondition
                    && repliesCondition
                    && mediaCondition
                    && dmsCondition
                    && actions[action_actor_id] == actorId
                )
                .order(actions[action_published].desc)
                .limit(maxNumberOfPosts)
        ))
        
        return try entryRowsArr.map(APubActionEntry.init(fromRow:))
    }
    
    fileprivate func save() throws {
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
            
            if try APubNote.doesNoteExist(noteId: noteId) {
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
        
        try DbInterface.getDb().run(actions.upsert(
            action_id <- self.id,
            action_actor_id <- self.actorId,
            action_published <- self.published,
            action_action_type <- actionType,
            action_same_user_note_id <- ownNoteId,
            action_other_user_note_id <- foreignNoteId,
            onConflictOf: action_id
        ))
    }
    
    fileprivate convenience init(fromRow actionEntryAndNoteRow: Row) throws {
        let id = actionEntryAndNoteRow[actions[action_id]]
        let actorId = actionEntryAndNoteRow[actions[action_actor_id]]
        let published = actionEntryAndNoteRow[actions[action_published]]
        let actionType = actionEntryAndNoteRow[actions[action_action_type]]
        let ownNoteId = actionEntryAndNoteRow[actions[action_same_user_note_id]]
        let foreignNoteId = actionEntryAndNoteRow[actions[action_other_user_note_id]]
        
        let action: APubAction
        switch actionType {
        case 0:
            action = .create(try APubNote(fromRow: actionEntryAndNoteRow))
        case 1:
            let foundNoteId = actionEntryAndNoteRow[notes[Expression<String?>("id")]]
            
            if foundNoteId != nil {
                let ownNote = try APubNote(fromRow: actionEntryAndNoteRow)
                action = .announceOwn(ownNote)
            } else {
                action = .announce(ownNoteId ?? foreignNoteId!)
            }
        default:
            throw DbInterfaceError.unexpected("APubActionEntry \(id) has unrecognized action type: \(actionType)")
        }
        
        self.init(id: id, actorId: actorId, published: published, action: action)
    }
    
    fileprivate func saveAllMedia(to mediaDir: URL) throws {
        switch self.action {
        case .create(let note):
            try note.saveAllMedia(to: mediaDir)
        default:
            break
        }
    }
}

extension APubNote {
    static func fetchNote(byId id: String) throws -> APubNote? {
        let noteRow = try DbInterface.getDb().pluck(notes.select(notes[*]).where(note_id == id))
        guard let noteRow = noteRow else {
            return nil
        }
        
        return try APubNote(fromRow: noteRow)
    }
    
    static func doesNoteExist(noteId: String) throws -> Bool {
        try DbInterface.getDb().prepare("SELECT EXISTS(SELECT 1 FROM notes WHERE id = ? LIMIT 1);", noteId).scalar() as! Int64 == 1
    }
    
    fileprivate func save() throws {
        try DbInterface.getDb().run(notes.upsert(
            note_id <- self.id,
            note_actor_id <- self.actorId,
            note_published <- self.published,
            note_visibility <- self.visibilityLevel.rawValue,
            note_url <- self.url,
            note_replying_to_note_id <- self.replyingToNoteId,
            note_cw <- self.cw,
            note_content <- self.content,
            note_searchable_content <- self.searchableContent,
            note_sensitive <- self.sensitive,
            note_poll_end_time <- self.pollEndTime,
            note_poll_is_closed <- self.pollIsClosed,
            onConflictOf: note_id
        ))
        
        try APubDocument.deleteDocuments(forNote: self.id, actorId: self.actorId)
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
    
    fileprivate convenience init(
        fromRow noteRow: Row,
        withMediaAttachments mediaAttachments: [APubDocument]? = nil,
        pollOptions: [APubPollOption]? = nil
    ) throws {
        let id = noteRow[notes[note_id]]
        let actorId = noteRow[notes[note_actor_id]]
        
        let mediaAttachments = try mediaAttachments ?? APubDocument.fetchDocuments(forNote: id, actorId: actorId)
        let pollOptions = try pollOptions ?? APubPollOption.fetchPollOptions(forNote: id)
        
        self.init(
            id: id,
            actorId: actorId,
            published: noteRow[notes[note_published]],
            visibilityLevel: APubNoteVisibilityLevel(rawValue: noteRow[notes[note_visibility]]) ?? .unknown,
            url: noteRow[notes[note_url]],
            replyingToNoteId: noteRow[notes[note_replying_to_note_id]],
            cw: noteRow[notes[note_cw]],
            content: noteRow[notes[note_content]],
            searchableContent: noteRow[notes[note_searchable_content]],
            sensitive: noteRow[notes[note_sensitive]],
            mediaAttachments: mediaAttachments,
            pollOptions: pollOptions,
            pollEndTime: noteRow[notes[note_poll_end_time]],
            pollIsClosed: noteRow[notes[note_poll_is_closed]]
        )
    }
    
    fileprivate func saveAllMedia(to mediaDir: URL) throws {
        for attachment in self.mediaAttachments ?? [] {
            try attachment.saveMedia(to: mediaDir)
        }
    }
}

extension APubDocument {
    static func fetchDocuments(forNote noteId: String, actorId: String) throws -> [APubDocument] {
        let attachmentRows = try Array(try DbInterface.getDb().prepareRowIterator(
            attachments
                .where(attachments_note_id == noteId)
                .order(attachments_order_num)
        ))
        
        return try attachmentRows.map { try APubDocument(withRow: $0, forActorId: actorId) }
    }
    
    //    static func fetchDocuments(
    //        forActor actorId: String,
    //        toDateTimeExclusive: Date? = nil,
    //        maxNumberOfPosts: Int?
    //    ) throws -> [(APubDocument, APubActionEntry)] {
    //        let maxDateCondition: Expression<Bool>
    //        if let toDateTimeExclusive = toDateTimeExclusive {
    //            maxDateCondition = actions[action_published] < toDateTimeExclusive
    //        } else {
    //            maxDateCondition = Expression(value: true)
    //        }
    //
    //        let rows = try Array(try DbInterface.getDb().prepareRowIterator(
    //            attachments
    //                .join(actions, on: actions[action_id] == attachments[attachments_note_id])
    //                .where(
    //                    actions[action_actor_id] == actorId
    //                    && actions[action_action_type] == 0
    //                    && maxDateCondition
    //                )
    //                .order(
    //                    actions[action_published].desc,
    //                    attachments[attachments_order_num].asc
    //                )
    //                .limit(maxNumberOfPosts)
    //        ))
    //
    //        return try rows.map { row in
    //            (try APubDocument(withRow: row, forActorId: actorId), try APubActionEntry(fromRow: row))
    //        }
    //    }
    
    static func deleteDocuments(forNote noteId: String, actorId: String) throws -> Void {
        let attachmentsForNote = attachments.filter(
            attachments_note_id == noteId
        )
        
        // fetch media data file paths
        let mediaPaths = try Array(try DbInterface.getDb().prepareRowIterator(
            attachmentsForNote.select(attachments_data_path)
        ))
        
        // try to delete them all
        for mediaFileRow in mediaPaths {
            let mediaPath = mediaFileRow[attachments_data_path]
            
            do {
                let mediaDir = try directoryForSavingMedia(actorId: actorId)
                let mediaUrl = mediaDir.appendingPathComponentNonDeprecated(mediaPath)
                
                try FileManager.default.removeItem(at: mediaUrl)
            } catch {
                print("Deleting media file \(mediaPath) for actor \(actorId) encountered an error: \(error)")
            }
        }
        
        // actually delete from the db
        try DbInterface.getDb().run(attachmentsForNote.delete())
    }
    
    fileprivate func save(withNoteId noteId: String, orderNum: Int) throws {
        // ideally, this should be using `.upsert()` as well, but realistically, that function doesn't support `ON CONFLICT` with multiple columns; but it's OK because there's no tables that FK-reference this one, so there's no risk of anything getting deleted
        try DbInterface.getDb().run(attachments.insert(
            or: .replace,
            attachments_note_id <- noteId,
            attachments_order_num <- orderNum,
            attachments_media_type <- self.mediaType,
            attachments_data_path <- self.path,
            attachments_alt_text <- self.altText,
            attachments_blurhash <- self.blurhash,
            attachments_focal_point_x <- self.focalPoint?.0,
            attachments_focal_point_y <- self.focalPoint?.1,
            attachments_width <- self.size?.0,
            attachments_height <- self.size?.1
        ))
    }
    
    private convenience init(withRow attachmentRow: Row, forActorId actorId: String) throws {
        let path = attachmentRow[attachments_data_path]
        let data = readMedia(atPath: path, forActorId: actorId)
        
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
            path: path,
            data: data,
            altText: attachmentRow[attachments_alt_text],
            blurhash: attachmentRow[attachments_blurhash],
            focalPoint: focalPoint,
            size: size
        )
    }
    
    fileprivate func saveMedia(to mediaDir: URL) throws {
        guard let data = data else {
            return
        }
        
        let filePath = mediaDir.appendingPathComponentNonDeprecated(self.path)
        try data.write(to: filePath, creatingDirectory: true)
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
    
    fileprivate func save(withNoteId noteId: String, orderNum: Int) throws {
        // ideally, this should be using `.upsert()` as well, but realistically, that function doesn't support `ON CONFLICT` with multiple columns; but it's OK because there's no tables that FK-reference this one, so there's no risk of anything getting deleted
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
