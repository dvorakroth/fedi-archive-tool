//
//  ActorView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI
import LazyPager

struct ActorView: View {
    let actor: APubActor
    let overridePostList: [APubActionEntry]?
    
    @State private var profileLinkShareSheetIsShown = false
    @State private var displayFilter = DisplayFilter.Posts
    @StateObject private var dataSource = PostDataSource()
    
//    @State var showFullscreenMedia = false
    @State var fullscreenMediaPreviewState: MediaPreviewState = .hidden
//    @State var fullscreenMediaIndex = 0
//    @State var fullscreenMediaPost: APubNote? = nil
    @State var fullscreenMediaBgOpacity: CGFloat = 1
    
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
                    
                    LazyVStack(spacing: 10) {
                        Divider()
                        ForEach(overridePostList ?? dataSource.posts) { post in
                            ActionView(actor: actor, action: post) { mediaIdx in
//                                fullscreenMediaPost = post.action.getNote()
//                                fullscreenMediaIndex = mediaIdx
//                                showFullscreenMedia = true
                                if let apubNote = post.action.getNote() {
                                    fullscreenMediaPreviewState = .shown(apubNote: apubNote, mediaIdx: mediaIdx)
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
        .fullScreenCover(isPresented: .init(get: {
            switch self.fullscreenMediaPreviewState {
            case .hidden:
                return false
            case .shown:
                return true
            }
        }, set: { newValue in
            if !newValue {
                self.fullscreenMediaPreviewState = .hidden
            } else {
                // ???? do nothing i guess??
                print("Warning: tried to directly set the full screen cover binding to true???")
            }
        })) {
            switch fullscreenMediaPreviewState {
            case .hidden:
                EmptyView()
            case .shown(let apubNote, let mediaIdx):
                LazyPager(data: apubNote.mediaAttachments ?? [], page: .init(get: {
                    mediaIdx
                }, set: { newIdx in
                    fullscreenMediaPreviewState = .shown(apubNote: apubNote, mediaIdx: newIdx)
                })) { attachment in
                    AttachmentPreviewView(attachment: attachment, hiddenByDefault: false)
                }
                .zoomable(min: 1, max: 5)
                .onDismiss(backgroundOpacity: $fullscreenMediaBgOpacity) {
                    fullscreenMediaPreviewState = .hidden
                }
                .background(.black.opacity(fullscreenMediaBgOpacity))
                .background(ClearFullScreenBackground())
                .ignoresSafeArea()
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

enum MediaPreviewState: Equatable {
    static func == (lhs: MediaPreviewState, rhs: MediaPreviewState) -> Bool {
        switch lhs {
        case .hidden:
            switch rhs {
            case .hidden:
                return true
            default:
                return false
            }
        case .shown(apubNote: let note1, mediaIdx: let idx1):
            switch rhs {
            case .shown(apubNote: let note2, mediaIdx: let idx2):
                return note1 === note2 && idx1 == idx2
            default:
                return false
            }
        }
    }
    
    case hidden
    case shown(apubNote: APubNote, mediaIdx: Int)
}

#Preview {
    ActorView(actor: MockData.actor, overridePostList: MockData.posts)
}
