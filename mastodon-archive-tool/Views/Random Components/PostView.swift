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
    let onMediaClicked: ((_: Int) -> Void)?
    
    @State var isExpanded = false
    @State var permalinkShareSheetIsShown = false
    
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
                    HStack {
                        Text(actor.name)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 2) {
                            if post.replyingToNoteId != nil {
                                Image(systemName: "bubble.left.and.bubble.right")
                            }
                            
                            Image(systemName: post.visibilityLevel.systemImageName)
                        }
                            .padding(.top, 2)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(actor.fullUsername)
                        .font(.caption)
                        .lineLimit(1)
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
                
                let hasPollOptions: Bool
                if let pollOptions = post.pollOptions {
                    if pollOptions.count > 0 {
                        let _ = hasPollOptions = true
                    } else {
                        let _ = hasPollOptions = false
                    }
                } else {
                    let _ = hasPollOptions = false
                }
                
                Spacer().frame(height: 10)
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    let text = self.isExpanded ? "Show less" : "Show more"
                    
                    if hasAttachments {
                        Image(systemName: "paperclip")
                    }
                    
                    if hasPollOptions {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    
                    Text(text)
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
            
            if let pollOptions = post.pollOptions {
                if pollOptions.count > 0 && (self.isExpanded || post.cw == nil) {
                    
                    Spacer().frame(height: 8)
                    PollView(
                        pollOptions: pollOptions,
                        endTime: post.pollEndTime,
                        isClosed: post.pollIsClosed ?? false
                    )
                }
            }
            
            if let mediaAttachments = post.mediaAttachments {
                if mediaAttachments.count > 0 && (self.isExpanded || post.cw == nil) {
                    let attachmentPairs = divideIntoPairs(mediaAttachments)
                    Spacer().frame(height: 15)
                    VStack {
                        ForEach(attachmentPairs, id: \.id) { (pairIdx, first, second) in
                            if let second = second {
                                HStack {
                                    AttachmentPreviewView(attachment: first, hiddenByDefault: post.sensitive) {
                                        if let onMediaClicked = onMediaClicked {
                                            onMediaClicked(pairIdx * 2)
                                        }
                                    }
                                    AttachmentPreviewView(attachment: second, hiddenByDefault: post.sensitive) {
                                        if let onMediaClicked = onMediaClicked {
                                            onMediaClicked(pairIdx * 2 + 1)
                                        }
                                    }
                                }
                            } else {
                                AttachmentPreviewView(attachment: first, hiddenByDefault: post.sensitive) {
                                    if let onMediaClicked = onMediaClicked {
                                        onMediaClicked(pairIdx * 2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer().frame(height: 15)
            
            HStack {
                Text(formatLongDateTime(post.published)).font(.caption)
                
                Spacer()
                
                Button("Permalink", systemImage: "link"){
                    permalinkShareSheetIsShown.toggle()
                }
                    .font(.caption)
                    .popover(isPresented: $permalinkShareSheetIsShown, content: {
                        if let url = URL(string: post.url) {
                            ShareSheetView(ShareSheetContent.url(url))
                        } else {
                            Text("Could not parse post URL: \(post.url)")
                        }
                    })
            }
            
            Spacer().frame(height: 15)
        }.padding(.horizontal)
    }
}

#Preview {
    ScrollView {
        PostView(
            actor: MockData.actor,
            post: MockData.posts[1].action.getNote()!,
            announcedBy: MockData.actor,
            onMediaClicked: nil
        )
    }
}

extension APubNoteVisibilityLevel {
    var systemImageName: String {
        get {
            switch self {
            case ._public:
                return "globe.europe.africa.fill"
            case .unlisted:
                return "moon"
            case .followersOnly:
                return "lock"
            case .dm:
                return "envelope"
            case .unknown:
                return "circle.badge.questionmark"
            }
        }
    }
}
