//
//  APubOutbox.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 22.06.24.
//

import Foundation

public class APubOutbox {
    let actor: APubActor
    let orderedItems: [APubActionEntry]
    
    init(actor: APubActor, orderedItems: [APubActionEntry]) {
        self.actor = actor
        self.orderedItems = orderedItems
    }
}

public extension APubOutbox {
    convenience init(withActor actor: APubActor, fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        
        let type = try tryGet(field: "type", ofType: .string, fromObject: json, called: "Outbox") as! String
        if type != "OrderedCollection" {
            throw APubParseError.wrongValueForField("type", onObject: "Outbox", expected: "OrderedCollection", found: type);
        }
        
        let orderedItems = try await tryGetArrayAsync(inField: "orderedItems", fromObject: json, called: "Outbox", parsingObjectsUsing: {
            (item: Any, itemNameForErrors: String, objNameForErrors: String) throws in
            
            guard let item = item as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try await APubActionEntry(fromJson: item, withFilesystemFetcher: filesystemFetcher)
        })
        
        self.init(actor: actor, orderedItems: orderedItems)
    }
}
