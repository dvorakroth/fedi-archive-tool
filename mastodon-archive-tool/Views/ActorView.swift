//
//  ActorView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI

struct ActorView: View {
    let actor: APubActor
    let overridePostList: [APubActionEntry]?
    
    @StateObject private var dataSource = PostDataSource()
    
    init(actor: APubActor, overridePostList: [APubActionEntry]? = nil) {
        self.actor = actor
        self.overridePostList = overridePostList
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    ZStack {
                        VStack(spacing: 0) {
                            ImageOrRectangle(
                                image: .data(actor.headerImage?.0),
                                fallbackColor: .secondary,
                                fallbackIcon: nil,
                                width: geo.size.width,
                                height: 200,
                                contentMode: .fill
                            )
                            
                            HStack(spacing: 0) {
                                Spacer()
                                Button("Link to profile") {
                                    if let url = URL(string: actor.url) {
                                        showShareSheet(url: url)
                                    }
                                }.buttonStyle(.borderedProminent).padding(.trailing)
                            }.frame(height: 60)
                        }
                        
                        VStack(spacing: 0) {
                            Spacer().frame(height: 260 - 80)
                            HStack {
                                ImageOrRectangle(
                                    image: .data(actor.icon?.0),
                                    fallbackColor: .secondary,
                                    fallbackIcon: nil,
                                    width: 80,
                                    height: 80
                                )
                                    .cornerRadius(8)
                                    .padding(.leading)
    
                                Spacer()
                            }
                        }
                    }
                    
                    HStack {
                        Text(actor.name).padding(.leading).font(.title)
                        Spacer()
                    }
                    
                    HStack {
                        Text(actor.fullUsername).padding(.leading).font(.caption)
                        Spacer()
                    }
                    
                    //                Spacer().frame(height: 15)
                    Text(" ")
                    
                    HStack {
                        Text(convertHTML(actor.bio))
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    //                Spacer().frame(height: 15)
                    Text(" ")
                    
                    HStack {
                        Text("Signed up " + formatDateWithoutTime(actor.created))
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    Spacer().frame(height: 15)
                    //                Text(" ")
                    
                    if (actor.table.count > 0) {
                        ActorTable(actor.table)
                    }
                    
                    //                Spacer().frame(height: 15)
                    Text(" ")
                    
                    LazyVStack(spacing: 10) {
                        Divider()
                        ForEach(overridePostList ?? dataSource.posts) { post in
                            ActionView(actor: actor, action: post)
                                .onAppear {
                                    loadMorePostsIfNeeded(currentEarliest: post)
                                }
                            Divider()
                        }
    
                        if dataSource.isLoading || overridePostList != nil {
                            Spacer().frame(height: 10)
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                    .onAppear {
                        loadMorePostsIfNeeded()
                    }
                    
                    
                    Spacer()
                }
            }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: SearchView(actor: actor)) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
        }
    }
    
    func loadMorePostsIfNeeded(currentEarliest: APubActionEntry? = nil) {
        guard overridePostList == nil else {
            return
        }

        do {
            try dataSource.loadMorePostsIfNeeded(
                forActorId: actor.id,
                currentEarliestPost: currentEarliest
            )
        } catch {
            // TODO some kind of error state?
            print("Error fetching posts: \(error)")
        }
    }
}

fileprivate class PostDataSource: ObservableObject {
    @Published var posts = [APubActionEntry]()
    @Published var isLoading = false
    
    private var canLoadMore = true
    
    private let POSTS_PER_PAGE = 10
    
    func loadMorePostsIfNeeded(forActorId actorId: String, currentEarliestPost: APubActionEntry?) throws {
        if let currentEarliestPost = currentEarliestPost, let currentLast = posts.last {
            if currentEarliestPost.id != currentLast.id {
                return
            }
        }
        
        try loadMorePosts(forActorId: actorId)
    }
    
    private func loadMorePosts(forActorId actorId: String) throws {
        guard !isLoading && canLoadMore else {
            return
        }
        
        isLoading = true
        
        // TODO maybe make this async lol
        let morePosts = try APubActionEntry.fetchActionEntries(
            fromActorId: actorId,
            toDateTimeExclusive: posts.last?.published,
            maxNumberOfPosts: POSTS_PER_PAGE
        )
        
        if morePosts.count < POSTS_PER_PAGE {
            self.canLoadMore = false
        }
        
        if morePosts.count > 0 {
            self.posts = self.posts + morePosts
        }
        
        self.isLoading = false
    }
}

#Preview {
    ActorView(actor: MockData.actor, overridePostList: MockData.posts)
}
