//
//  PostView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 26.06.24.
//

import SwiftUI

struct PostView: View {
    let actor: APubActor
    let post: APubNote
    let announcedBy: APubActor?
    
    @State var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let announcedBy = announcedBy {
                HStack(spacing: 0) {
                    Spacer()
                    
                    Image(systemName: "arrow.2.squarepath").scaleEffect(CGSize(width: 0.7, height: 0.7))
                    
                    Text("\(announcedBy.name) boosted:").font(.caption)
                    
                    Spacer()
                }
                
                Spacer().frame(height: 15)
            }
            
            HStack {
                ImageOrRectangle(image: .data(actor.icon?.0), fallbackColor: .secondary, fallbackIcon: nil, width: 50, height: 50).cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text(actor.name)
                    Text(actor.fullUsername).font(.caption)
                }
                
                Spacer()
            }
            
            Spacer().frame(height: 10)
            
            if let cw = post.cw {
                Text(cw)
                
                let hasAttachments: Bool
                if let mediaAttachments = post.mediaAttachments {
                    if mediaAttachments.count > 0 {
                        let _ = hasAttachments = true
                    } else {
                        let _ = hasAttachments = false
                    }
                } else {
                    let _ = hasAttachments = false
                }
                
                Button(self.isExpanded ? "Show less" : "Show more", systemImage: hasAttachments ? "paperclip" : "") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .padding(.zero)
            }
            
            if post.cw == nil || isExpanded {
                if post.cw != nil {
                    Spacer().frame(height: 10)
                }
                Text(convertHTML(post.content))
            }
            
            if let mediaAttachments = post.mediaAttachments {
                if mediaAttachments.count > 0 && (self.isExpanded || post.cw == nil) {
                    let attachmentPairs = divideIntoPairs(mediaAttachments)
                    Spacer().frame(height: 15)
                    VStack {
                        ForEach(attachmentPairs, id: \.id) { (id: _, first, second) in
                            if let second = second {
                                HStack {
                                    AttachmentPreviewView(attachment: first, hiddenByDefault: post.sensitive)
                                    AttachmentPreviewView(attachment: second, hiddenByDefault: post.sensitive)
                                }
                            } else {
                                AttachmentPreviewView(attachment: first, hiddenByDefault: post.sensitive)
                            }
                        }
                    }
                }
            }
            
            Spacer().frame(height: 15)
            
            HStack {
                Text(formatLongDateTime(post.published)).font(.caption)
                
                Spacer()
                
                Button("Permalink") {
                    if let url = URL(string: post.url) {
                        UIApplication.shared.open(url)
                    }
                }.font(.caption)
            }
            
            Spacer().frame(height: 15)
        }.padding(.horizontal)
    }
}

#Preview {
    PostView(
        actor: MockData.actor,
        post: MockData.posts[2].action.getNote()!,
        announcedBy: MockData.actor
    )
}
