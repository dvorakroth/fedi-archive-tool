//
//  ReadArchive.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import Foundation
import ZIPFoundation
import Tarscape
import DataCompression

func importArchive(_ url: URL) async throws -> APubActor {
    let getFileFromArchive: (String) async throws -> Data
    var tmpDir: TempDir? = nil
    
    guard url.startAccessingSecurityScopedResource() else {
        throw ArchiveReadingError.error("Can't get security scoped access")
    }
    defer {
        url.stopAccessingSecurityScopedResource()
    }
    
    if url.pathExtension == "zip" {
        let archive = try Archive(url: url, accessMode: .read)
        
        getFileFromArchive = { rawFilename in
            let filename: String
            if rawFilename.starts(with: "/") {
                let afterFirstChar = rawFilename.index(rawFilename.startIndex, offsetBy: 1)
                filename = String(rawFilename[afterFirstChar...])
            } else {
                filename = rawFilename
            }
            
            guard let entry = archive[filename] else {
                throw ArchiveReadingError.fileNotFoundInArchive(filename: filename)
            }
            
            var data: Data = Data()
            
            return try await withCheckedThrowingContinuation({ continuation in
                do {
                    _ = try archive.extract(entry, consumer: { chunk in
                        data += chunk
                        
                        if (data.count == entry.uncompressedSize) {
                            continuation.resume(returning: data)
                        }
                    })
                } catch {
                    continuation.resume(throwing: error)
                }
            })
        }
    } else if url.absoluteString.hasSuffix(".tar.gz") {
        tmpDir = try TempDir()
        let tarUrl: URL
        if #available(iOS 16.0, *) {
            tarUrl = tmpDir!.url.appending(path: url.lastPathComponent.dropLast(3))
        } else {
            tarUrl = tmpDir!.url.appendingPathComponent(String(url.lastPathComponent.dropLast(3)))
        }
        
        if let uncompressedData = try Data(contentsOf: url).gunzip() {
            try uncompressedData.write(to: tarUrl)
        } else {
            throw ArchiveReadingError.error("Failed to gunzip \(url.lastPathComponent)")
        }
        
        let archive = try KBTarUnarchiver(tarURL: tarUrl)
        try archive.loadAllEntries(lazily: true)
        
        getFileFromArchive = { filename in
            guard let entry = archive[filename] else {
                throw ArchiveReadingError.fileNotFoundInArchive(filename: filename)
            }
            
            // fun fact! tarscape is the only decent swift tar library i could find, but it' sbeen unmaintained for 3 years (and counting??) and it has all sorts of weird ass behaviors and bugs!!! such as!!!!! it returns files with their entire ass tar header AND with the last ${HEADER_SIZE} bytes straight up missing??????????? note to self: fork that shit lmao
            entry.fileLocation += 512
            defer { entry.fileLocation -= 512 }
            
            if let contents = entry.regularFileContents() {
                return contents
            } else {
                throw ArchiveReadingError.error("Could not read contents of file \(filename) in archive \(url.lastPathComponent)")
            }
        }
    } else {
        throw ArchiveReadingError.unrecognizedFormat("File extension is not .zip or .tar.gz on \(url.lastPathComponent)")
    }
    
    let actor = try await readActor(getFileFromArchive)
    let outbox = try await readOutbox(forActor: actor, getFileFromArchive)
    try outbox.atomicSave()
    
    return actor
}

enum ArchiveReadingError: Error {
    case unrecognizedFormat(_: String)
    case fileNotFoundInArchive(filename: String)
    case malformedFile(filename: String, details: String? = nil)
    case error(_: String)
}

fileprivate func readActor(_ getFileFromArchive: (String) async throws -> (Data)) async throws -> APubActor {
    let jsonObj = try JSONSerialization.jsonObject(
        with: try await getFileFromArchive("actor.json")
    )
    
    guard let jsonObj = jsonObj as? [String: Any] else {
        throw ArchiveReadingError.malformedFile(filename: "actor.json", details: nil)
    }
    
    return try await APubActor(fromJson: jsonObj, withFilesystemFetcher: getFileFromArchive)
}

fileprivate func readOutbox(forActor actor: APubActor, _ getFileFromArchive: (String) async throws -> (Data)) async throws -> APubOutbox {
    let jsonObj = try JSONSerialization.jsonObject(
        with: try await getFileFromArchive("outbox.json")
    )
    
    guard let jsonObj = jsonObj as? [String: Any] else {
        throw ArchiveReadingError.malformedFile(filename: "outbox.json", details: nil)
    }
    
    return try await APubOutbox(withActor: actor, fromJson: jsonObj, withFilesystemFetcher: getFileFromArchive)
}
