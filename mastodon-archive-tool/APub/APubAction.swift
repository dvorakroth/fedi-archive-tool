//
//  APubAction.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 16.06.24.
//

import Foundation

public struct APubActionEntry {
    let id: String;
    weak var actor: APubActor?;
    let published: Date;
    let action: APubAction;
}

public extension APubActionEntry {
    init(fromJson json: [String: Any], inDirectory: URL, withAPubActorStore getAPubActor: (String) -> APubActor?) throws {
        
        self.id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Action") as! String
        
        let actionNameForErrors = "Action \(self.id)"
        
        let actorId = try tryGet(field: "actor", ofType: .string, fromObject: json, called: actionNameForErrors) as! String
        guard let actor = getAPubActor(actorId) else {
            throw APubParseError.wrongValueForField("actor", onObject: actionNameForErrors, expected: "a valid Actor id")
        }
        self.actor = actor
        
        self.published = try tryGetDate(inField: "published", fromObject: json, called: actionNameForErrors)
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: actionNameForErrors) as! String
        
        switch(type) {
        case "Announce":
            let (object, objectType) = try tryGet(field: "object", ofAnyTypeOf: [.string, .object], fromObject: json, called: actionNameForErrors)
            
            switch(objectType) {
            case .string:
                self.action = .announce(object as! String)
            case .object:
                let object = object as! [String: Any]
                self.action = .announce(try tryGet(field: "id", ofType: .string, fromObject: object, called: "object in \(actionNameForErrors)") as! String)
            default:
                throw APubParseError.wrongTypeForField("object", onObject: actionNameForErrors, expected: [.string, .object])
            }
            
            
        case "Create":
            let object = try tryGet(field: "object", ofType: .object, fromObject: json, called: actionNameForErrors) as! [String: Any]
            self.action = .create(try APubNote(fromJson: object, inDirectory: inDirectory))
        
        default:
            throw APubParseError.wrongValueForField("type", onObject: actionNameForErrors, expected: "\"Announce\" or \"Create\"")
        }
    }
}

public enum APubAction {
    /// the action the user took was: publishing a post
    case create(APubNote)
    
    /// the action the user took was: boosting a user's post (their own or someone else's)
    case announce(String)
}

/// this is a post
public struct APubNote {
    let id: String;
    let published: Date;
    let url: String;
    let replyingToNoteId: String?;
    let cw: String?;
    let content: String;
    let mediaAttachments: [APubDocument]?;
    let pollOptions: [APubPollOption]?;
    // TODO language tag?
}

public extension APubNote {
    init(fromJson json: [String: Any], inDirectory: URL) throws {
        self.id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Note") as! String
        
        let noteNameForErrors = "Note \(self.id)"
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        if type != "Note" && type != "Question" {
            throw APubParseError.wrongValueForField("type", onObject: noteNameForErrors, expected: "\"Note\" or \"Question\"")
        }
        
        self.published = try tryGetDate(inField: "published", fromObject: json, called: noteNameForErrors)
        
        self.url = try tryGet(field: "url", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        self.replyingToNoteId = try tryGetNullable(field: "inReplyTo", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        self.cw = try tryGetNullable(field: "summary", ofType: .string, fromObject: json, called: noteNameForErrors) as! String?
        self.content = try tryGet(field: "content", ofType: .string, fromObject: json, called: noteNameForErrors) as! String
        
        self.mediaAttachments = try tryGetArray(inField: "attachment", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
            (obj: Any, itemNameForErrors: String, objNameForErrors: String) throws -> APubDocument in
            
            guard let obj = obj as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try APubDocument(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)", inDirectory: inDirectory)
        })
        
        if json.keys.contains("oneOf") {
            self.pollOptions = try tryGetArray(inField: "oneOf", fromObject: json, called: noteNameForErrors, parsingObjectsUsing: {
                (obj: Any, itemNameForErrors: String, objNameForErrors: String) throws -> APubPollOption in
                
                guard let obj = obj as? [String: Any] else {
                    throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
                }
                
                return try APubPollOption(fromJson: obj, called: "\(itemNameForErrors) in \(objNameForErrors)")
            })
        } else {
            self.pollOptions = nil
        }
    }
}

/// this has an extremely confusing name in the ActivityPub/ActivityStreams/whatever standard, but it's basically just a media attachment on a post
public struct APubDocument {
    let mediaType: String;
    let filePath: URL;
    let altText: String?;
    let blurhash: String?;
    let focalPoint: (Float, Float)?;
    let size: (UInt, UInt)?;
}

public extension APubDocument {
    init(fromJson json: [String: Any], called objNameForErrors: String, inDirectory: URL) throws {
        if try tryGet(field: "type", ofType: .string, fromObject: json, called: objNameForErrors) as! String != "Document" {
            throw APubParseError.wrongValueForField("type", onObject: objNameForErrors, expected: "Document")
        }
        
        self.mediaType = try tryGet(field: "mediaType", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        
        let relativePath = try tryGet(field: "url", ofType: .string, fromObject: json, called: objNameForErrors) as! String
        if #available(macOS 13.0, iOS 16.0, *) {
            self.filePath = inDirectory.appending(path: relativePath)
        } else {
            // Fallback on earlier versions
            self.filePath = inDirectory.appendingPathComponent(relativePath)
        }
        
        self.altText = try tryGetNullable(field: "name", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        self.blurhash = try tryGetNullable(field: "blurhash", ofType: .string, fromObject: json, called: objNameForErrors) as! String?
        
        let focalPointArr = try tryGetNullable(field: "focalPoint", ofType: .array, fromObject: json, called: objNameForErrors) as! [Any]?;
        
        if let focalPointArr = focalPointArr {
            guard focalPointArr.count == 2, let focalPointArr = focalPointArr as? [NSNumber] else {
                throw APubParseError.wrongValueForField("focalPoint", onObject: objNameForErrors, expected: "an array with exactly two elements, both numbers")
            }
            
            self.focalPoint = (focalPointArr[0].floatValue, focalPointArr[1].floatValue)
        } else {
            self.focalPoint = nil
        }
        
        let width = try tryGetNullable(field: "width", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        let height = try tryGetNullable(field: "height", ofType: .number, fromObject: json, called: objNameForErrors) as! NSNumber?
        
        if let width = width, let height = height {
            self.size = (width.uintValue, height.uintValue)
        } else {
            self.size = nil
        }
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
