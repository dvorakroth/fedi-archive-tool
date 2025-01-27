//
//  APubAction.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 16.06.24.
//

import Foundation

public class APubActionEntry: Identifiable {
    public let id: String;
    let actorId: String;
    let published: Date;
    let action: APubAction;
    
    init(id: String, actorId: String, published: Date, action: APubAction) {
        self.id = id
        self.actorId = actorId
        self.published = published
        self.action = action
    }
}

public extension APubActionEntry {
    convenience init(fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        
        let id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Action") as! String
        
        let actionNameForErrors = "Action \(id)"
        
        let actorId = try tryGet(field: "actor", ofType: .string, fromObject: json, called: actionNameForErrors) as! String
        
        let published = try tryGetDate(inField: "published", fromObject: json, called: actionNameForErrors)
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: actionNameForErrors) as! String
        
        let action: APubAction
        switch(type) {
        case "Announce":
            let (object, objectType) = try tryGet(field: "object", ofAnyTypeOf: [.string, .object], fromObject: json, called: actionNameForErrors)
            
            switch(objectType) {
            case .string:
                action = .announce(object as! String)
            case .object:
                let object = object as! [String: Any]
                action = .announce(try tryGet(field: "id", ofType: .string, fromObject: object, called: "object in \(actionNameForErrors)") as! String)
            default:
                throw APubParseError.wrongTypeForField("object", onObject: actionNameForErrors, expected: [.string, .object])
            }
            
            
        case "Create":
            let object = try tryGet(field: "object", ofType: .object, fromObject: json, called: actionNameForErrors) as! [String: Any]
            action = .create(try await APubNote(fromJson: object, withFilesystemFetcher: filesystemFetcher))
        
        default:
            throw APubParseError.wrongValueForField("type", onObject: actionNameForErrors, expected: "\"Announce\" or \"Create\"", found: type)
        }
        
        self.init(id: id, actorId: actorId, published: published, action: action)
    }
}

public enum APubAction {
    /// the action the user took was: publishing a post
    case create(APubNote)
    
    /// the action the user took was: boosting a user's post (their own or someone else's)
    case announce(String)
    
    /// the action the user took was: boosting their own post
    case announceOwn(APubNote)
    
    func getUrl() -> String {
        switch self {
        case .create(let note), .announceOwn(let note):
            return note.url
        case .announce(let url):
            return url
        }
    }
    
    func getNote() -> APubNote? {
        switch self {
        case .create(let note), .announceOwn(let note):
            return note
        default:
            return nil
        }
    }
}

public enum APubNoteVisibilityLevel: String {
    case _public = "PUBLIC"
    case unlisted = "UNLISTED"
    case followersOnly = "FOLLOWERS"
    case dm = "DM"
    case unknown = "UNKNOWN"
    
    private static let PUBLIC_VALUES: Set<String> = ["https://www.w3.org/ns/activitystreams#Public", "Public", "as:Public"]
    
    static func figureOutVisibilityLevel(fromToList toList: [String], ccList: [String], withActorId actorId: String) -> APubNoteVisibilityLevel {
        if PUBLIC_VALUES.intersection(toList).count > 0 {
            return ._public
        }
        
        if PUBLIC_VALUES.intersection(ccList).count > 0 {
            return .unlisted
        }
        
        let followersUrl = actorId + (actorId.hasSuffix("/") ? "" : "/") + "followers"
        if toList.firstIndex(of: followersUrl) != nil || ccList.firstIndex(of: followersUrl) != nil {
            return .followersOnly
        }
        
        return .dm
    }
}

/// this is a post
public class APubNote {
    let id: String
    let actorId: String
    let published: Date
    let visibilityLevel: APubNoteVisibilityLevel
    let url: String
    let replyingToNoteId: String?
    let cw: String?
    let content: String
    let searchableContent: String
    let sensitive: Bool
    let mediaAttachments: [APubDocument]?
    let pollOptions: [APubPollOption]?
    let pollEndTime: Date?
    let pollIsClosed: Bool?
    // TODO language tag?
    
    init(id: String, actorId: String, published: Date, visibilityLevel: APubNoteVisibilityLevel, url: String, replyingToNoteId: String?, cw: String?, content: String, searchableContent: String, sensitive: Bool, mediaAttachments: [APubDocument]?, pollOptions: [APubPollOption]?, pollEndTime: Date?, pollIsClosed: Bool?) {
        self.id = id
        self.actorId = actorId
        self.published = published
        self.visibilityLevel = visibilityLevel
        self.url = url
        self.replyingToNoteId = replyingToNoteId
        self.cw = cw
        self.content = content
        self.searchableContent = searchableContent
        self.sensitive = sensitive
        self.mediaAttachments = mediaAttachments
        self.pollOptions = pollOptions
        self.pollEndTime = pollEndTime
        self.pollIsClosed = pollIsClosed
    }
}

public extension APubNote {
    convenience init(fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        let id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Note") as! String
        
        let noteNameForErrors = "Note \(id)"
        
        let actorId = try tryGet(field: "attributedTo", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        if type != "Note" && type != "Question" {
            throw APubParseError.wrongValueForField("type", onObject: noteNameForErrors, expected: "\"Note\" or \"Question\"", found: type)
        }
        
        let published = try tryGetDate(inField: "published", fromObject: json, called: noteNameForErrors)
        
        let toList = try tryGetArray(inField: "to", fromObject: json, called: noteNameForErrors) { obj, itemNameForErrors, objNameForErrors in
            guard let obj = obj as? String else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.string])
            }
            
            return obj
        }
        let ccList = try tryGetArray(inField: "cc", fromObject: json, called: noteNameForErrors) { obj, itemNameForErrors, objNameForErrors in
            guard let obj = obj as? String else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.string])
            }
            
            return obj
        }
        let visibilityLevel = APubNoteVisibilityLevel.figureOutVisibilityLevel(fromToList: toList, ccList: ccList, withActorId: actorId)
        
        let url = try tryGet(field: "url", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        let replyingToNoteId = try tryGetNullable(field: "inReplyTo", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        let cw = try tryGetNullable(field: "summary", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        let content = try tryGet(field: "content", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        let searchableContent = stripHTML(content)
        let sensitive: Bool
        do {
            sensitive = try tryGetNullable(field: "sensitive", ofType: .boolean, fromObject: json, called: noteNameForErrors) as! Bool? ?? false
        } catch APubParseError.missingField(_, onObject: _) {
            sensitive = false
        }
        
        let mediaAttachments = try await tryGetArrayAsync(inField: "attachment", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
            (obj: Any, itemNameForErrors: String, objNameForErrors: String, _: Int, _: Int) throws -> APubDocument in
            
            guard let obj = obj as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try await APubDocument(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)", withFilesystemFetcher: filesystemFetcher)
        })
        
        let pollOptions: [APubPollOption]?
        let pollEndTime: Date?
        let pollIsClosed: Bool?
        if json.keys.contains("oneOf") {
            pollOptions = try tryGetArray(inField: "oneOf", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
                (obj: Any, itemNameForErrors: String, objNameForErrors: String) throws -> APubPollOption in
                
                guard let obj = obj as? [String: Any] else {
                    throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
                }
                
                return try APubPollOption(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)")
            })
            
            pollEndTime = try tryGetDateNullable(inField: "endTime", fromObject: json, called: noteNameForErrors)
            
            pollIsClosed = !(json["closed"] == nil || json["closed"] is NSNull)
        } else {
            pollOptions = nil
            pollEndTime = nil
            pollIsClosed = nil
        }
        
        self.init(id: id, actorId: actorId, published: published, visibilityLevel: visibilityLevel, url: url, replyingToNoteId: replyingToNoteId, cw: cw, content: content, searchableContent: searchableContent, sensitive: sensitive, mediaAttachments: mediaAttachments, pollOptions: pollOptions, pollEndTime: pollEndTime, pollIsClosed: pollIsClosed)
    }
}

/// this has an extremely confusing name in the ActivityPub/ActivityStreams/whatever standard, but it's basically just a media attachment on a post
public class APubDocument {
    let mediaType: String;
    let path: String;
    let data: Data?;
    let altText: String?;
    let blurhash: String?;
    let focalPoint: (Double, Double)?;
    let size: (Int, Int)?;
    
    init(mediaType: String, path: String, data: Data?, altText: String?, blurhash: String?, focalPoint: (Double, Double)?, size: (Int, Int)?) {
        self.mediaType = mediaType
        self.path = path
        self.data = data
        self.altText = altText
        self.blurhash = blurhash
        self.focalPoint = focalPoint
        self.size = size
    }
}

public extension APubDocument {
    convenience init(fromJson json: [String: Any], called objNameForErrors: String, withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        if type != "Document" {
            throw APubParseError.wrongValueForField("type", onObject: objNameForErrors, expected: "Document", found: type)
        }
        
        let mediaType = try tryGet(field: "mediaType", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        
        let path = try tryGet(field: "url", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        let data: Data?
        do {
            data = try await filesystemFetcher(path)
        } catch ArchiveReadingError.fileNotFoundInArchive(filename: _) {
            print("WARNING: File not found in archive: \(path)")
            data = nil
        }
        
        let altText = try tryGetNullable(field: "name", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        let blurhash = try tryGetNullable(field: "blurhash", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        
        let focalPointArr = try tryGetNullable(field: "focalPoint", ofType: .array, fromObject: json, called: objNameForErrors) as! [Any]?;
        
        let focalPoint: (Double, Double)?
        if let focalPointArr = focalPointArr {
            guard focalPointArr.count == 2, let focalPointArr = focalPointArr as? [NSNumber] else {
                throw APubParseError.wrongValueForField("focalPoint", onObject: objNameForErrors, expected: "an array with exactly two elements, both numbers", found: "\(focalPointArr)")
            }
            
            focalPoint = (focalPointArr[0].doubleValue, focalPointArr[1].doubleValue)
        } else {
            focalPoint = nil
        }
        
        let width = try tryGetNullable(field: "width", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        let height = try tryGetNullable(field: "height", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        
        let size: (Int, Int)?
        if let width = width, let height = height {
            size = (width.intValue, height.intValue)
        } else {
            size = nil
        }
        
        self.init(mediaType: mediaType, path: path, data: data, altText: altText, blurhash: blurhash, focalPoint: focalPoint, size: size)
    }
}

public struct APubPollOption {
    let name: String;
    let numVotes: Int;
}

public extension APubPollOption {
    init(fromJson json: [String: Any], called objNameForErrors: String) throws {
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        if type != "Note" {
            throw APubParseError.wrongValueForField("type", onObject: objNameForErrors, expected: "Note", found: type)
        }
        
        self.name = try tryGet(field: "name", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        
        let replies = try tryGet(field: "replies", ofType: .object, fromObject: json, called: objNameForErrors) as! [String: Any]
        let repliesNameForErrors = "replies in \(objNameForErrors)"
        
        let repliesType = try tryGet(field: "type", ofType: .string, fromObject: replies, called: repliesNameForErrors) as! String
        if repliesType != "Collection" {
            throw APubParseError.wrongValueForField("type", onObject: repliesNameForErrors, expected: "Collection", found: repliesType)
        }
        
        self.numVotes = (try tryGet(field: "totalItems", ofType: .number, fromObject: replies, called: repliesNameForErrors) as! NSNumber).intValue
    }
}
