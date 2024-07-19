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
//    @StateObject var dataSource = PostDataSource()
    
    init(actor: APubActor, overridePostList: [APubActionEntry]? = nil) {
        self.actor = actor
        self.overridePostList = overridePostList
    }
    
    var body: some View {
        VStack {
            TextField(
                "Search",
                text: $currentSearchInput
            )
            .onSubmit(onSubmit)
            .submitLabel(.search)
            .textFieldStyle(.roundedBorder)
            .padding(.all)
            
            Spacer()
        }
        .navigationTitle("Search")
    }
    
    func onSubmit() {
        print("search field sumbitted: \(currentSearchInput)")
    }
}

#Preview {
    SearchView(actor: MockData.actor)
}
