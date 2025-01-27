//
//  ContentView.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import SwiftUI

struct ContentView: View {
    @State private var refreshId = UUID()
    @State private var selectedActorId: String? = nil
    
    @ObservedObject private var actorList = ActorList.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("My Archives") {
                    ForEach($actorList.actors) { actor in
                        NavigationLink(tag: "ACTOR: \(actor.id)", selection: $selectedActorId) {
                            ActorView(actor: actor.wrappedValue)
                                .navigationTitle(actor.wrappedValue.name)
                        } label: {
                            HStack(content: {
                                if let icon = actor.wrappedValue.icon {
                                    Image(uiImage: UIImage(data: icon.0)!).resizable().frame(width: 27, height: 27).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                                }
                                Text(actor.wrappedValue.fullUsername)
                            })
                        }
                    }
                    .onDelete { indexSet in
                        let actorIds = actorList.actors.get(indexSet: indexSet).map(\.id)
                        let displayNames = actorList.actors.get(indexSet: indexSet).map(\.fullUsername)
                        
                        ActorList.shared.actors.removeAll { actor in
                            actorIds.contains(actor.id)
                        }
                        ArchiveImportQueue.getQueue().addToQueue(delete: actorIds, withDisplayNames: displayNames)
                        
                        if let selectedActorId = selectedActorId {
                            if actorIds.firstIndex(of: selectedActorId) != nil {
                                refreshId = UUID()
                            }
                        }
                    }
                    
                    #if DEBUG
                    NavigationLink(tag: "TEST ACTOR", selection: $selectedActorId) {
                        ActorView(actor: MockData.actor, overridePostList: MockData.posts)
                            .navigationTitle(MockData.actor.name)
                    } label: {
                        Label("test actor", systemImage: "ant.circle")
                    }
                    #endif
                    
                    NavigationLink(tag: "IMPORT QUEUE", selection: $selectedActorId) {
                        AddArchiveView()
                    } label: {
                        Label("Add new archive", systemImage: "plus")
                    }
                }
                
                Section("Misc") {
                    NavigationLink(tag: "ABOUT", selection: $selectedActorId) {
                        AboutView().navigationTitle(Bundle.main.appName)
                    } label: {
                        Label("About \(Bundle.main.appName)", systemImage: "info.circle")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Archives")
            .toolbar {
                if actorList.actors.count > 0 {
                    EditButton()
                }
            }
        }
            .task {
                updateActorsList()
            }
            .id(refreshId)
    }
    
    func updateActorsList() {
        do {
            try actorList.forceRefresh()
        } catch {
            // TODO handle error gracefully
            print(error)
        }
    }
}

#Preview {
    ContentView()
}
