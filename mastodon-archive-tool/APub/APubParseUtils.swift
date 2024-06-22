//
//  APubParseError.swift
//  mastodon-archive-reader
//
//  Created by Wolfe on 19.06.24.
//

import Foundation

public enum APubParseError : Error {
    case missingField(String, onObject: String)
    case wrongTypeForField(String, onObject: String, expected: [JsonTypes])
    case wrongValueForField(String, onObject: String, expected: String)
}

public enum JsonTypes {
    case null
    case boolean
    case string
    case number
    case object
    case array
}

func tryGet(field: String, ofType type: JsonTypes, fromObject object: [String: Any], called objName: String) throws -> Any {
    
    guard let value = object[field] else {
        throw APubParseError.missingField(field, onObject: objName)
    }
    
    return try guardJsonType(type, ofValue: value, fromFieldCalled: field, inObjectCalled: objName)
}
    

func guardJsonType(_ type: JsonTypes, ofValue value: Any, fromFieldCalled field: String, inObjectCalled objName: String) throws -> Any {
    
    switch(type) {
    case .null:
        guard value is NSNull else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [.null])
        }
    case .boolean:
        guard value is Bool else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [type])
        }
    case .string:
        guard value is String else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [type])
        }
    case .number:
        guard value is NSNumber else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [type])
        }
    case .object:
        guard value is [String: Any] else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [type])
        }
    case .array:
        guard value is [Any] else {
            throw APubParseError.wrongTypeForField(field, onObject: objName, expected: [type])
        }
    }
    
    return value
}

func tryGet(field: String, ofAnyTypeOf typeList: [JsonTypes], fromObject object: [String: Any], called objName: String) throws -> (Any, JsonTypes) {
    
    guard let value = object[field] else {
        throw APubParseError.missingField(field, onObject: objName)
    }
    
    for type in typeList {
        do {
            return (try guardJsonType(type, ofValue: value, fromFieldCalled: field, inObjectCalled: objName), type)
        } catch APubParseError.wrongTypeForField( _, onObject: _, expected: _) {
            continue
        }
    }
    
    throw APubParseError.wrongTypeForField(field, onObject: objName, expected: typeList)
}

func tryGetNullable(field: String, ofType type: JsonTypes, fromObject object: [String: Any], called objName: String) throws -> Any? {
    
    guard let value = object[field] else {
        return nil
    }
    
    if value is NSNull {
        return nil
    }
    
    return try guardJsonType(type, ofValue: value, fromFieldCalled: field, inObjectCalled: objName)
}

func tryGetDate(inField field: String, fromObject object: [String: Any], called objName: String) throws -> Date {
    let dateStr = try tryGet(field: field, ofType: .string, fromObject: object, called: objName) as! String
    let dateFormatter = ISO8601DateFormatter()
    // TODO timezone?
    guard let date = dateFormatter.date(from: dateStr) else {
        throw APubParseError.wrongValueForField(field, onObject: objName, expected: "A Valid ISO 8601 date")
    }
    
    return date
}

func tryGetArray<T>(inField field: String, fromObject object: [String: Any], called objName: String, parsingObjectsUsing objParser: (Any, String, String) throws -> T) throws -> [T] {
    
    var result: [T] = []
    let arr = try tryGet(field: field, ofType: .array, fromObject: object, called: objName) as! [Any]
    
    for (index, item) in arr.enumerated() {
        let itemNameForErrors = "\(field)[\(index)]"
        
        result.append(try objParser(item, itemNameForErrors, objName))
    }
    
    return result
}
