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
    
    fileprivate init() {}
    private static var singletonInstance: ArchiveImportQueue? = nil
    
    static func getQueue() -> ArchiveImportQueue {
        if self.singletonInstance == nil {
            self.singletonInstance = ArchiveImportQueue()
        }
        
        return self.singletonInstance!
    }
    
    func addToQueue(import fileURL: URL) {
        globalIdCounter += 1
        queue.append(QueueItem(id: globalIdCounter, action: .addArchive(fileURL: fileURL), status: .waiting))
        startHandlingImports()
    }
    
    func addToQueue(delete actorIds: [String], withDisplayNames displayNames: [String]) {
        globalIdCounter += 1
        queue.append(QueueItem(
            id: globalIdCounter,
            action: .deleteArchives(actorIds: actorIds, displayNames: displayNames),
            status: .waiting
        ))
        startHandlingImports()
    }
    
    fileprivate func startHandlingImports() {
        if importInProgress {
            // no need to do anything, the currently running task handler will handle the next item from the queue when it's done
            return
        }
        
        importInProgress = true
        
        Task {
            while let nextImportIdx = await getNextImportIdx() {
                let action = queue[nextImportIdx].action
                updateImportStatus(atIndex: nextImportIdx, to: .processing(0.0))
                
                switch action {
                case .addArchive(let fileURL):
                    do {
                        let _ = try await importArchive(fileURL) { progress in
                            self.updateImportStatus(atIndex: nextImportIdx, to: .processing(progress))
                        }
                    } catch {
                        let mirror = Mirror(reflecting: error)
                        updateImportStatus(atIndex: nextImportIdx, to: .error("\(mirror.subjectType) - \(error)"))
                    }
                    
                case .deleteArchives(let actorIds, _):
                    let hideTask = Task { @MainActor in
                        ActorList.shared.actors.removeAll(where: { actorIds.contains($0.id) })
                    }
                    
                    let _ = await hideTask.result
                    
                    do {
                        try APubActor.deleteActors(withIds: actorIds)
                    } catch {
                        let mirror = Mirror(reflecting: error)
                        updateImportStatus(atIndex: nextImportIdx, to: .error("\(mirror.subjectType) - \(error)"))
                    }
                    
                    refreshActorsList()
                }
                
                
                updateImportStatus(atIndex: nextImportIdx, to: .done)
                
                await Task.yield()
            }
            
            importInProgress = false
        }
    }
    
    private func getNextImportIdx() async -> Int? {
        let task = Task { @MainActor in
            return queue.firstIndex { item in
                switch item.status {
                case .waiting:
                    return true
                default:
                    return false
                }
            }
        }
        
        do {
            return try await task.result.get()
        } catch {
            print("Error getting next queue idx: \(error)")
            return nil
        }
    }
    
    private func updateImportStatus(atIndex index: Int, to newState: ImportStatus) {
        DispatchQueue.main.schedule {
            self.queue[index].status = newState
        }
    }
    
    private func refreshActorsList() {
        DispatchQueue.main.schedule {
            do {
                try ActorList.shared.forceRefresh()
            } catch {
                print("Error refreshing actor list: \(error)")
            }
        }
    }
}

class MockArchiveImportQueue: ArchiveImportQueue {
    public init(queueItems: [QueueItem]) {
        super.init()
        self.queue = queueItems
    }
    
    override fileprivate func startHandlingImports() {
        // do nothing
    }
}

struct QueueItem: Identifiable {
    let id: Int
    let action: QueueAction
    var status: ImportStatus
}

enum QueueAction {
    case addArchive(fileURL: URL)
    case deleteArchives(actorIds: [String], displayNames: [String])
}

enum ImportStatus {
    case waiting
    case processing(Double)
    case error(String)
    case done
}
