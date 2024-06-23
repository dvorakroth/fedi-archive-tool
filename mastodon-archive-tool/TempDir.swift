//
//  TempDir.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import Foundation

class TempDir {
    let url: URL
    
    init() throws {
        var createdDir: URL? = nil
        
        repeat {
            do {
                let attemptUrl: URL
                if #available(iOS 16.0, *) {
                    attemptUrl = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                } else {
                    // Fallback on earlier versions
                    attemptUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                }
                
                try FileManager.default.createDirectory(at: attemptUrl, withIntermediateDirectories: false)
                
                createdDir = attemptUrl
            } catch CocoaError.fileWriteFileExists {
                continue
            }
        } while createdDir == nil
        
        self.url = createdDir!
    }
    
    deinit {
        do {
            try FileManager.default.removeItem(at: self.url)
        } catch {
            print("Error while trying to delete temp dir \(url.absoluteString): \(error.localizedDescription)")
        }
    }
}
