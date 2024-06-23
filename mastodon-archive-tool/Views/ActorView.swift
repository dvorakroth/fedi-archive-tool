//
//  ActorView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI

struct ActorView: View {
    let actor: APubActor
    
    var body: some View {
        Text("Hello, \(actor.name)!")
    }
}

#Preview {
    ActorView(actor: APubActor(id: "123", username: "mx123", name: "Mx. 123", bio: "The elusive Mx. 123, at your service", url: "social.example.net/@123", created: Date(timeIntervalSince1970: TimeInterval(3600)), table: [("Pronouns", "they/them"), ("Am I real?", "No, I'm just a demo for the UI designer")], icon: nil, headerImage: nil))
}
