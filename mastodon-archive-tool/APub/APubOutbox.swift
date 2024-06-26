//
//  APubOutbox.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 22.06.24.
//

import Foundation

public class APubOutbox {
    let orderedItems: [APubActionEntry]
    
    init(orderedItems: [APubActionEntry]) {
        self.orderedItems = orderedItems
    }
}

public extension APubOutbox {
    convenience init(fromJson json: [String: Any], withFilesystemFetcher filesystemFetcher: (String) async throws -> (Data)) async throws {
        
        if try tryGet(field: "type", ofType: .string, fromObject: json, called: "Outbox") as! String != "OrderedCollection" {
            throw APubParseError.wrongValueForField("type", onObject: "Outbox", expected: "OrderedCollection");
        }
        
        let orderedItems = try await tryGetArrayAsync(inField: "orderedItems", fromObject: json, called: "Outbox", parsingObjectsUsing: {
            (item: Any, itemNameForErrors: String, objNameForErrors: String) throws in
            
            guard let item = item as? [String: Any] else {
                throw APubParseError.wrongTypeForField(itemNameForErrors, onObject: objNameForErrors, expected: [.object])
            }
            
            return try await APubActionEntry(fromJson: item, withFilesystemFetcher: filesystemFetcher)
        })
        
        self.init(orderedItems: orderedItems)
    }
}
