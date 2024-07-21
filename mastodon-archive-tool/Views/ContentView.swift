//
//  ContentView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import SwiftUI

struct ContentView: View {
    @State private var actors: [APubActor] = []
    @State private var refreshId = UUID()
    @State private var selectedActorId: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section("My Archives") {
                    ForEach($actors) { actor in
                        NavigationLink(tag: actor.id, selection: $selectedActorId) {
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
                        do {
                            let actorIds = actors.get(indexSet: indexSet).map(\.id)
                            
                            try APubActor.deleteActors(withIds: actorIds)
                            actors.remove(atOffsets: indexSet)
                            
                            if let selectedActorId = selectedActorId {
                                if actorIds.firstIndex(of: selectedActorId) != nil {
                                    withAnimation {
                                        refreshId = UUID()
                                    }
                                }
                            }
                        } catch {
                            // TODO handle error gracefully
                            print(error.localizedDescription)
                        }
                    }
                    
                    #if DEBUG
                    NavigationLink {
                        ActorView(actor: MockData.actor, overridePostList: MockData.posts)
                            .navigationTitle(MockData.actor.name)
                    } label: {
                        Label("test actor", systemImage: "ant.circle")
                    }
                    #endif
                    
                    NavigationLink {
                        AddArchiveView() {
                            do {
                                actors = try APubActor.fetchAllActors()
                            } catch {
                                // TODO handle this error i guess!
                                print(error.localizedDescription)
                            }
                        }
                    } label: {
                        Label("Add new archive", systemImage: "plus")
                    }
                }
                
                Section("Misc") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Archives")
            .toolbar {
                if actors.count > 0 {
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
            actors = try APubActor.fetchAllActors()
        } catch {
            // TODO handle error gracefully
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
