//
//  ReadArchive.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import Foundation
import ZIPFoundation
import Tarscape
import DataCompression

let IMPORT_PROGRESS_STARTED = 0.05;
let IMPORT_PROGRESS_READ_ACTOR = 0.1;
let IMPORT_PROGRESS_READ_POSTS = 0.9;
let IMPORT_PROGRESS_WROTE_DB = 0.95;
let IMPORT_PROGRESS_WROTE_MEDIA = 1.0;

func importArchive(_ url: URL, progressCallback: @escaping (Double) -> ()) async throws -> APubActor {
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
        let tarUrl = tmpDir!.url.appendingPathComponentNonDeprecated(String(url.lastPathComponent.dropLast(3)))
        
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
    
    progressCallback(IMPORT_PROGRESS_STARTED)
    
    let actor = try await readActor(getFileFromArchive)
    progressCallback(IMPORT_PROGRESS_READ_ACTOR)
    
    let outbox = try await readOutbox(
        forActor: actor,
        getFileFromArchive: getFileFromArchive,
        progressCallback: { outboxProgress in
            progressCallback(
                (IMPORT_PROGRESS_READ_POSTS - IMPORT_PROGRESS_READ_ACTOR) * outboxProgress
                + IMPORT_PROGRESS_READ_ACTOR
            )
        }
    )
    
    try outbox.atomicSave() { progressStage in
        switch progressStage {
        case .doneWritingDb:
            progressCallback(IMPORT_PROGRESS_WROTE_DB)
        case .doneWritingMediaFiles:
            progressCallback(IMPORT_PROGRESS_WROTE_MEDIA)
        }
    }
    
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

fileprivate func readOutbox(
    forActor actor: APubActor,
    getFileFromArchive: (String) async throws -> (Data),
    progressCallback: (Double) -> ()
) async throws -> APubOutbox {
    let jsonObj = try JSONSerialization.jsonObject(
        with: try await getFileFromArchive("outbox.json")
    )
    
    guard let jsonObj = jsonObj as? [String: Any] else {
        throw ArchiveReadingError.malformedFile(filename: "outbox.json", details: nil)
    }
    
    return try await APubOutbox(
        withActor: actor,
        fromJson: jsonObj, 
        withFilesystemFetcher: getFileFromArchive,
        progressCallback: progressCallback
    )
}
