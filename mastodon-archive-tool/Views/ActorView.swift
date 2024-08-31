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
    
    @State private var profileLinkShareSheetIsShown = false
    @State private var displayFilter = DisplayFilter.Posts
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
                                    profileLinkShareSheetIsShown.toggle()
                                }
                                    .buttonStyle(.borderedProminent)
                                    .padding(.trailing)
                                    .popover(isPresented: $profileLinkShareSheetIsShown, content: {
                                        if let url = URL(string: actor.url) {
                                            ShareSheetView(url: url)
                                        } else {
                                            Text("Could not parse user URL: \(actor.url)")
                                        }
                                    })
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
                    
                    Spacer().frame(height: 15)
//                    Text(" ")
                    
                    HStack {
                        Spacer()
                        
                        Button("Posts", systemImage: "note.text") {
                            withAnimation {
                                displayFilter = DisplayFilter.Posts
                                categoryChanged()
                            }
                        }
                        .disabled(displayFilter == DisplayFilter.Posts)
                        
                        Spacer()
                        
                        Button("incl. Replies", systemImage: "bubble.left.and.bubble.right") {
                            withAnimation {
                                displayFilter = DisplayFilter.PostsAndReplies
                                categoryChanged()
                            }
                        }
                        .disabled(displayFilter == DisplayFilter.PostsAndReplies)
                        
                        Spacer()
                        
                        Button("Media", systemImage: "photo") {
                            withAnimation {
                                displayFilter = DisplayFilter.Media
                                categoryChanged()
                            }
                        }
                        .disabled(displayFilter == DisplayFilter.Media)
                        
                        Spacer()
                    }
                    
                    Spacer().frame(height: 15)
                    
                    MediaDisplayer { displayMedia in
                        LazyVStack(spacing: 10) {
                            Divider()
                            ForEach(overridePostList ?? dataSource.posts) { post in
                                ActionView(actor: actor, action: post) { mediaIdx in
                                    if let apubNote = post.action.getNote() {
                                        displayMedia(apubNote.mediaAttachments ?? [], mediaIdx)
                                    }
                                }
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
    
    func categoryChanged() {
        guard overridePostList == nil else {
            return
        }
        
        do {
            try dataSource.resetAndReloadPosts(ofType: displayFilter, forActorId: actor.id)
        } catch {
            // TODO some kind of error state?
            print("Error fetching posts: \(error)")
        }
    }
    
    func loadMorePostsIfNeeded(currentEarliest: APubActionEntry? = nil) {
        guard overridePostList == nil else {
            return
        }

        do {
            try dataSource.loadMorePostsIfNeeded(
                ofType: displayFilter,
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
    
    func resetAndReloadPosts(ofType postType: DisplayFilter, forActorId actorId: String) throws {
        isLoading = false
        canLoadMore = true
        posts = []
        
        try loadMorePosts(ofType: postType, forActorId: actorId)
    }
    
    func loadMorePostsIfNeeded(ofType postType: DisplayFilter, forActorId actorId: String, currentEarliestPost: APubActionEntry?) throws {
        if let currentEarliestPost = currentEarliestPost, let currentLast = posts.last {
            if currentEarliestPost.id != currentLast.id {
                return
            }
        }
        
        try loadMorePosts(ofType: postType, forActorId: actorId)
    }
    
    private func loadMorePosts(ofType postType: DisplayFilter, forActorId actorId: String) throws {
        guard !isLoading && canLoadMore else {
            return
        }
        
        isLoading = true
        
        let includeAnnounces: Bool
        let includeReplies: Bool
        let onlyIncludePostsWithMedia: Bool
        
        switch postType {
        case .Posts:
            includeAnnounces = true
            includeReplies = false
            onlyIncludePostsWithMedia = false
            
        case .PostsAndReplies:
            includeAnnounces = true
            includeReplies = true
            onlyIncludePostsWithMedia = false
            
        case .Media:
            includeAnnounces = false
            includeReplies = true
            onlyIncludePostsWithMedia = true
        }
        
        // TODO maybe make this async lol
        let morePosts = try APubActionEntry.fetchActionEntries(
            fromActorId: actorId,
            toDateTimeExclusive: posts.last?.published,
            maxNumberOfPosts: POSTS_PER_PAGE,
            includeAnnounces: includeAnnounces,
            includeReplies: includeReplies,
            onlyIncludePostsWithMedia: onlyIncludePostsWithMedia
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

fileprivate enum DisplayFilter {
    case Posts
    case PostsAndReplies
    case Media
}

#Preview {
    ActorView(actor: MockData.actor, overridePostList: MockData.posts)
}
