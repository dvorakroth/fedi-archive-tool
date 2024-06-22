//
//  Actor.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 14.06.24.
//

import Foundation

public class APubActor {
    let id: String;
    let name: String;
    let bio: String;
    let url: String;
    let created: Date;
    let table: [(String, String)];
    let iconPath: URL?;
    let headerImagePath: URL?;
    
    init(id: String, name: String, bio: String, url: String, created: Date, table: [(String, String)], iconPath: URL?, headerImagePath: URL?) {
        self.id = id
        self.name = name
        self.bio = bio
        self.url = url
        self.created = created
        self.table = table
        self.iconPath = iconPath
        self.headerImagePath = headerImagePath
    }
}

public extension APubActor {
    convenience init(fromJson json: [String: Any], inDirectory: URL) throws {
        let id = try tryGet(field: "id", ofType: .string, fromObject: json, called: "Actor") as! String
        
        let actorNameForErrors = "Actor \(id)"
        
        
        let name = try tryGet(field: "name", ofType: .string, fromObject: json, called: actorNameForErrors) as! String
        let bio = try tryGet(field: "summary", ofType: .string, fromObject: json, called: actorNameForErrors) as! String
        let url = try tryGet(field: "url", ofType: .string, fromObject: json, called: actorNameForErrors) as! String
        
        let created = try tryGetDate(inField: "published", fromObject: json, called: actorNameForErrors)
        
        let table = try tryGetArray(
            inField: "attachment",
            fromObject: json, called: actorNameForErrors,
            parsingObjectsUsing: {
                (row: Any, itemNameForErrors: String, objNameForErrors: String) throws -> (String, String) in
                
                guard let row = row as? [String: Any] else {
                    throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
                }
                
                return try APubActor.parseTableRow(fromJson: row, called: "\(itemNameForErrors) in \(objNameForErrors)")
        })
        
        let iconPath = try APubActor.parseImage(fromField: "icon", ofJson: json, inDirectory: inDirectory, asPartOfActor: actorNameForErrors)
        
        let headerImagePath = try APubActor.parseImage(fromField: "image", ofJson: json, inDirectory: inDirectory, asPartOfActor: actorNameForErrors)
        
        self.init(id: id, name: name, bio: bio, url: url, created: created, table: table, iconPath: iconPath, headerImagePath: headerImagePath)
    }
    
    private static func parseImage(fromField fieldName: String, ofJson json: [String: Any], inDirectory: URL, asPartOfActor actorName: String) throws -> URL? {
        
        let imageField = try tryGetNullable(field: fieldName, ofType: .object, fromObject: json, called: actorName) as! [String: Any]?
        
        guard let imageField = imageField else {
            return nil
        }
        
        let imagePath = try tryGet(field: "url", ofType: .string, fromObject: imageField, called: "\(fieldName) on \(actorName)") as! String
        
        if #available(macOS 13.0, iOS 16.0, *) {
            return inDirectory.appending(path: imagePath)
        } else {
            // Fallback on earlier versions
            return inDirectory.appendingPathComponent(imagePath)
        }
    }
    
    private static func parseTableRow(fromJson json: [String: Any], called nameForErrors: String) throws -> (String, String) {
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: nameForErrors) as! String
        guard type == "PropertyValue" else {
            throw APubParseError.wrongValueForField("type", onObject: nameForErrors, expected: "PropertyValue")
        }
                
        let name = try tryGet(field: "name", ofType: .string, fromObject: json, called: nameForErrors) as! String
        let value = try tryGet(field: "value", ofType: .string, fromObject: json, called: nameForErrors) as! String
        
        return (name, value)
    }
}
