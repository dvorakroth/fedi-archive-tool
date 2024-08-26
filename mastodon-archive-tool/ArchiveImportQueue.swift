//
//  ArchiveImportQueue.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 26.08.24.
//

import Foundation

class ArchiveImportQueue: ObservableObject {
    @Published var queue: [QueueItem] = []
    
    private var importInProgress = false
    private var globalIdCounter = 0
    
    private init() {}
    private static var singletonInstance: ArchiveImportQueue? = nil
    
    static func getQueue() -> ArchiveImportQueue {
        if self.singletonInstance == nil {
            self.singletonInstance = ArchiveImportQueue()
        }
        
        return self.singletonInstance!
    }
    
    func addToQueue(_ fileURL: URL) {
        globalIdCounter += 1
        queue.append(QueueItem(id: globalIdCounter, fileURL: fileURL, status: .waiting))
        startHandlingImports()
    }
    
    private func startHandlingImports() {
        if importInProgress {
            // no need to do anything, the currently running task handler will handle the next item from the queue when it's done
            return
        }
        
        importInProgress = true
        
        Task {
            while let nextImportIdx = getNextImportIdx() {
                let fileURL = queue[nextImportIdx].fileURL
                
                updateImportStatus(atIndex: nextImportIdx, to: .processing)
                
                do {
                    let _ = try await importArchive(fileURL)
                    updateImportStatus(atIndex: nextImportIdx, to: .done)
                    // TODO signal to main view that it needs to update?
                } catch {
                    // TODO better way to convert errors to strings?
                    updateImportStatus(atIndex: nextImportIdx, to: .error(error.localizedDescription))
                }
                
                await Task.yield()
            }
            
            importInProgress = false
        }
    }
    
    private func getNextImportIdx() -> Int? {
        return queue.firstIndex { item in
            switch item.status {
            case .waiting:
                return true
            default:
                return false
            }
        }
    }
    
    private func updateImportStatus(atIndex index: Int, to newState: ImportStatus) {
        DispatchQueue.main.schedule {
            self.queue[index].status = newState
        }
    }
}

struct QueueItem: Identifiable {
    let id: Int
    let fileURL: URL
    var status: ImportStatus
}

enum ImportStatus {
    case waiting
    case processing
    case error(String)
    case done
}
