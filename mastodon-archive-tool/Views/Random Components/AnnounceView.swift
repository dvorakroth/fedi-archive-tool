//
//  AnnounceView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 26.08.24.
//

import SwiftUI

struct AnnounceView: View {
    let actor: APubActor
    let announcedUrl: String
    
    @State var permalinkShareSheetIsShown = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                
                Image(systemName: "arrow.2.squarepath").scaleEffect(CGSize(width: 0.7, height: 0.7))
                
                Text("\(actor.name) boosted:").font(.caption)
                
                Spacer()
            }
            
            Spacer().frame(height: 15)
            
            Text("(post not found in archive)").italic()
            
            HStack {
                Spacer()
                
                Button("Permalink", systemImage: "link"){
                    permalinkShareSheetIsShown.toggle()
                }
                .font(.caption)
                .popover(isPresented: $permalinkShareSheetIsShown, content: {
                    if let url = URL(string: announcedUrl) {
                        ShareSheetView(ShareSheetContent.url(url))
                    } else {
                        Text("Could not parse post URL: \(announcedUrl)")
                    }
                })
            }
            
            Spacer().frame(height: 15)
        }.padding(.horizontal)
    }
}


#Preview {
    AnnounceView(
        actor: MockData.actor,
        announcedUrl: "https://social.example.net/posts/123"
    )
}
