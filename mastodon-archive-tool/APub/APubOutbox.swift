//
//  APubOutbox.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 22.06.24.
//

import Foundation

public struct APubOutbox {
    let orderedItems: [APubActionEntry]
    weak var actor: APubActor?
}

public extension APubOutbox {
    init(forActor actor: APubActor, fromJson json: [String: Any], inDirectory: URL) throws {
        
        self.actor = actor
        
        if try tryGet(field: "type", ofType: .string, fromObject: json, called: "Outbox") as! String != "OrderedCollection" {
            throw APubParseError.wrongValueForField("type", onObject: "Outbox", expected: "OrderedCollection");
        }
        
        self.orderedItems = try tryGetArray(inField: "orderedItems", fromObject: json, called: "Outbox", parsingObjectsUsing: {
            (item: Any, itemNameForErrors: String, objNameForErrors: String) throws in
            
            guard let item = item as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try APubActionEntry(fromJson: item, inDirectory: inDirectory, withAPubActorStore: { actorId in
                if actorId == actor.id {
                    return actor
                } else {
                    return nil
                }
            })
        })
    }
}
