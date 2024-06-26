//
//  APubAction.swift
//  mastodon-archive-reader
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
            throw APubParseError.wrongValueForField("type", onObject: actionNameForErrors, expected: "\"Announce\" or \"Create\"")
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
}

/// this is a post
public class APubNote {
    let id: String;
    let published: Date;
    let url: String;
    let replyingToNoteId: String?;
    let cw: String?;
    let content: String;
    let mediaAttachments: [APubDocument]?;
    let pollOptions: [APubPollOption]?;
    // TODO language tag?
    
    init(id: String, published: Date, url: String, replyingToNoteId: String?, cw: String?, content: String, mediaAttachments: [APubDocument]?, pollOptions: [APubPollOption]?) {
        self.id = id
        self.published = published
        self.url = url
        self.replyingToNoteId = replyingToNoteId
        self.cw = cw
        self.content = content
        self.mediaAttachments = mediaAttachments
        self.pollOptions = pollOptions
    }
}

public extension APubNote {
    convenience init(fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        let id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Note") as! String
        
        let noteNameForErrors = "Note \(id)"
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        if type != "Note" && type != "Question" {
            throw APubParseError.wrongValueForField("type", onObject: noteNameForErrors, expected: "\"Note\" or \"Question\"")
        }
        
        let published = try tryGetDate(inField: "published", fromObject: json, called: noteNameForErrors)
        
        let url = try tryGet(field: "url", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        let replyingToNoteId = try tryGetNullable(field: "inReplyTo", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        let cw = try tryGetNullable(field: "summary", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        let content = try tryGet(field: "content", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        let mediaAttachments = try await tryGetArrayAsync(inField: "attachment", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
            (obj: Any, itemNameForErrors: String, objNameForErrors: String) throws -> APubDocument in
            
            guard let obj = obj as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try await APubDocument(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)", withFilesystemFetcher: filesystemFetcher)
        })
        
        let pollOptions: [APubPollOption]?
        if json.keys.contains("oneOf") {
            pollOptions = try tryGetArray(inField: "oneOf", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
                (obj: Any, itemNameForErrors: String, objNameForErrors: String) throws -> APubPollOption in
                
                guard let obj = obj as? [String: Any] else {
                    throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
                }
                
                return try APubPollOption(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)")
            })
        } else {
            pollOptions = nil
        }
        
        self.init(id: id, published: published, url: url, replyingToNoteId: replyingToNoteId, cw: cw, content: content, mediaAttachments: mediaAttachments, pollOptions: pollOptions)
    }
}

/// this has an extremely confusing name in the ActivityPub/ActivityStreams/whatever standard, but it's basically just a media attachment on a post
public class APubDocument {
    let mediaType: String;
    let data: Data;
    let altText: String?;
    let blurhash: String?;
    let focalPoint: (Float, Float)?;
    let size: (UInt, UInt)?;
    
    init(mediaType: String, data: Data, altText: String?, blurhash: String?, focalPoint: (Float, Float)?, size: (UInt, UInt)?) {
        self.mediaType = mediaType
        self.data = data
        self.altText = altText
        self.blurhash = blurhash
        self.focalPoint = focalPoint
        self.size = size
    }
}

public extension APubDocument {
    convenience init(fromJson json: [String: Any], called objNameForErrors: String, withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        if try tryGet(field: "type", ofType: .string, fromObject: json, called: objNameForErrors) as! String != "Document" {
            throw APubParseError.wrongValueForField("type", onObject: objNameForErrors, expected: "Document")
        }
        
        let mediaType = try tryGet(field: "mediaType", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        
        let relativePath = try tryGet(field: "url", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        let data = try await filesystemFetcher(relativePath)
        
        let altText = try tryGetNullable(field: "name", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        let blurhash = try tryGetNullable(field: "blurhash", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        
        let focalPointArr = try tryGetNullable(field: "focalPoint", ofType: .array, fromObject: json, called: objNameForErrors) as! [Any]?;
        
        let focalPoint: (Float, Float)?
        if let focalPointArr = focalPointArr {
            guard focalPointArr.count == 2, let focalPointArr = focalPointArr as? [NSNumber] else {
                throw APubParseError.wrongValueForField("focalPoint", onObject: objNameForErrors, expected: "an array with exactly two elements, both numbers")
            }
            
            focalPoint = (focalPointArr[0].floatValue, focalPointArr[1].floatValue)
        } else {
            focalPoint = nil
        }
        
        let width = try tryGetNullable(field: "width", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        let height = try tryGetNullable(field: "height", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        
        let size: (UInt, UInt)?
        if let width = width, let height = height {
            size = (width.uintValue, height.uintValue)
        } else {
            size = nil
        }
        
        self.init(mediaType: mediaType, data: data, altText: altText, blurhash: blurhash, focalPoint: focalPoint, size: size)
    }
}

public struct APubPollOption {
    let name: String;
    let numVotes: UInt;
}

public extension APubPollOption {
    init(fromJson json: [String: Any], called objNameForErrors: String) throws {
        if try tryGet(field: "type", ofType: .string, fromObject: json, called: objNameForErrors) as! String != "Note" {
            throw APubParseError.wrongValueForField("type", onObject: objNameForErrors, expected: "Note")
        }
        
        self.name = try tryGet(field: "name", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        
        let replies = try tryGet(field: "replies", ofType: .object, fromObject: json, called: objNameForErrors) as! [String: Any]
        let repliesNameForErrors = "replies in \(objNameForErrors)"
        
        if try tryGet(field: "type", ofType: .string, fromObject: replies, called: repliesNameForErrors) as! String != "Collection" {
            throw APubParseError.wrongValueForField("type", onObject: repliesNameForErrors, expected: "Collection")
        }
        
        self.numVotes = (try tryGet(field: "totalItems", ofType: .number, fromObject: replies, called: repliesNameForErrors) as! NSNumber).uintValue
    }
}
