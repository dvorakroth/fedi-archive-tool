//
//  SearchView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 19.07.24.
//

import SwiftUI

struct SearchView: View {
    let actor: APubActor
    let overridePostList: [APubActionEntry]?
    
    @State var currentSearchInput: String = ""
    @StateObject private var dataSource = PostSearchDataSource()
    
    private static let topId = "TOP_OF_SCROLL_VIEW"
    
    init(actor: APubActor, overridePostList: [APubActionEntry]? = nil) {
        self.actor = actor
        self.overridePostList = overridePostList
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { reader in
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        TextField(
                            "Search",
                            text: $currentSearchInput
                        )
                        .onSubmit({
                            reader.scrollTo(Self.topId, anchor: .top)
                            onSubmit()
                        })
                        .submitLabel(.search)
                        .textFieldStyle(.roundedBorder)
                        .padding(.all)
                        .overlay(
                            Button(action: {
                                currentSearchInput = ""
                                reader.scrollTo(Self.topId, anchor: .top)
                                onSubmit()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .opacity(currentSearchInput.isEmpty ? 0 : 1)
                                    .padding()
                            }
                                .buttonStyle(.plain)
                                .foregroundStyle(.tertiary)
                                .padding(.all, 7),
                            
                            alignment: .trailing
                        )
                    }
                    .background(.tertiary)
                    
//                    Spacer()
                
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            Divider().id(Self.topId)
                            
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
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
    
    func onSubmit() {
        print("search field sumbitted: \(currentSearchInput)")
        do {
            try dataSource.newSearchString(currentSearchInput, forActorId: actor.id)
        } catch {
            print("Error fetching posts: \(error)")
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

fileprivate class PostSearchDataSource: ObservableObject {
    @Published var posts = [APubActionEntry]()
    @Published var isLoading = false
    
    private var canLoadMore = true
    private var currentSearchString: String? = nil
    
    private let POSTS_PER_PAGE = 10
    
    func newSearchString(_ newSearchString: String?, forActorId actorId: String) throws {
        if newSearchString == nil || newSearchString?.count == 0 {
            currentSearchString = nil
        } else {
            currentSearchString = newSearchString
        }
        posts = []
        isLoading = false
        canLoadMore = true
        
        try loadMorePostsIfNeeded(forActorId: actorId, currentEarliestPost: nil)
    }
    
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
        
        let morePosts: [APubActionEntry]
        
        if let currentSearchString = currentSearchString {
            // TODO maybe make this async lol
            morePosts = try APubActionEntry.fetchActionEntries(
                fromActorId: actorId,
                matchingSearchString: currentSearchString,
                toDateTimeExclusive: posts.last?.published,
                maxNumberOfPosts: POSTS_PER_PAGE,
                includeAnnounces: false
            )
        } else {
            morePosts = []
        }
        
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
    SearchView(actor: MockData.actor, overridePostList: MockData.posts)
}
