//
//  ReadArchive.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import Foundation
import ZIPFoundation
import Tarscape

func readArchive(_ url: URL) throws {
    if url.pathExtension == "zip" {
        // TODO
    } else if url.absoluteString.hasSuffix(".tar.gz") {
        // TODO
    } else {
        throw ArchiveReadingError.error("File extension is not .zip or .tar.gz on \(url.absoluteString)")
    }
}

enum ArchiveReadingError: Error {
    case error(_: String)
}
