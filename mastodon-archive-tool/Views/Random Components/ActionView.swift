//
//  ActionView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 26.06.24.
//

import SwiftUI

struct ActionView: View {
    let actor: APubActor
    let action: APubActionEntry
    
    var body: some View {
        switch action.action {
        case .announce(let url):
            AnnounceView(actor: actor, announcedUrl: url)
        case .create(let note):
            PostView(actor: actor, post: note, announcedBy: nil)
        case .announceOwn(let note):
            PostView(actor: actor, post: note, announcedBy: actor)
        }
    }
}

struct AnnounceView: View {
    let actor: APubActor
    let announcedUrl: String
    
    var body: some View {
        Text("TODO: AnnounceView")
    }
}
