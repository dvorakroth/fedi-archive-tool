//
//  ContentView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var db: DbInterface? = nil
    @State private var actors: [APubActor] = []
    
    var body: some View {
        NavigationView {
            List {
                Section("My Archives") {
                    ForEach(actors) { actor in
                        NavigationLink {
                            ActorView(actor: actor)
                        } label: {
                            HStack(content: {
                                if let icon = actor.icon {
                                    Image(uiImage: UIImage(data: icon.0)!).resizable().frame(width: 27, height: 27).padding(.trailing)
                                }
                                Text(actor.fullUsername)
                            })
                        }
                    }
                    
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
        }.task {
            do {
                actors = try APubActor.fetchAllActors()
            } catch {
                // TODO handle error gracefully
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}
