//
//  ActionView.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 26.06.24.
//

import SwiftUI

struct ActionView: View {
    let actor: APubActor
    let action: APubActionEntry
    let onMediaClicked: ((_: Int) -> Void)?
    
    var body: some View {
        switch action.action {
        case .announce(let url):
            AnnounceView(actor: actor, announcedUrl: url)
        case .create(let note):
            PostView(actor: actor, post: note, announcedBy: nil, onMediaClicked: onMediaClicked)
        case .announceOwn(let note):
            PostView(actor: actor, post: note, announcedBy: actor, onMediaClicked: onMediaClicked)
        }
    }
}
