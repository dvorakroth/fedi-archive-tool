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
    let icon: (Data, String)?;
    let headerImage: (Data, String)?;
    
    init(id: String, name: String, bio: String, url: String, created: Date, table: [(String, String)], icon: (Data, String)?, headerImage: (Data, String)?) {
        self.id = id
        self.name = name
        self.bio = bio
        self.url = url
        self.created = created
        self.table = table
        self.icon = icon
        self.headerImage = headerImage
    }
}

public extension APubActor {
    convenience init(fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) throws -> (Data)) throws {
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
        
        let icon = try APubActor.parseImage(fromField: "icon", ofJson: json, withFilesystemFetcher: filesystemFetcher, asPartOfActor: actorNameForErrors)
        
        let headerImage = try APubActor.parseImage(fromField: "image", ofJson: json, withFilesystemFetcher: filesystemFetcher, asPartOfActor: actorNameForErrors)
        
        self.init(id: id, name: name, bio: bio, url: url, created: created, table: table, icon: icon, headerImage: headerImage)
    }
    
    private static func parseImage(fromField fieldName: String, ofJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) throws -> (Data), asPartOfActor actorName: String) throws -> (Data, String)? {
        
        let imageField = try tryGetNullable(field: fieldName, ofType: .object, fromObject: json, called: actorName) as! [String: Any]?
        
        guard let imageField = imageField else {
            return nil
        }
        
        let imagePath = try tryGet(field: "url", ofType: .string, fromObject: imageField, called: "\(fieldName) on \(actorName)") as! String
        let imageType = try tryGet(field: "mediaType", ofType: .string, fromObject: imageField, called: "\(fieldName) on \(actorName)") as! String
        
        return (try filesystemFetcher(imagePath), imageType)
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
