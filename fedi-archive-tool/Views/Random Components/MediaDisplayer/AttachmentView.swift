//
//  AttachmentView.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 01.09.24.
//

import SwiftUI
import AVKit

struct AttachmentView: View {
    let actorId: String
    let attachment: APubDocument
    let onClose: () -> Void
    
    @State var saveShareSheetIsShown = false
    @State var altTextSheetIsShown = false
    @State fileprivate var mediaType: MediaType? = nil
    
    func initializeIfNecessary() {
        guard mediaType == nil else {
            return
        }
        
        if attachment.mediaType.starts(with: "image/") {
            let fallbackIcon = "questionmark.square.dashed"
            if let data = attachment.data, let image = UIImage(data: data) {
                mediaType = .image(image, fallbackIcon: fallbackIcon)
            } else {
                mediaType = .unknown(fallbackIcon: fallbackIcon)
            }
        } else if attachment.mediaType.starts(with: "video/") {
            let fallbackIcon = "video.square"
            if let mediaUrl = urlForMedia(atPath: attachment.path, forActorId: actorId) {
                mediaType = .audiovisual(AVPlayer(url: mediaUrl), fallbackIcon: fallbackIcon)
            } else {
                mediaType = .unknown(fallbackIcon: fallbackIcon)
            }
        } else if attachment.mediaType.starts(with: "audio/") {
            let fallbackIcon = "headphones.circle"
            if let mediaUrl = urlForMedia(atPath: attachment.path, forActorId: actorId) {
                mediaType = .audiovisual(AVPlayer(url: mediaUrl), fallbackIcon: fallbackIcon)
            } else {
                mediaType = .unknown(fallbackIcon: fallbackIcon)
            }
        } else {
            mediaType = .unknown(fallbackIcon: "questionmark.square.dashed")
        }
    }
    
    var body: some View {
        ZStack {
            switch mediaType {
            case .image(let uiImage, _):
                ZoomView(minZoom: 1, maxZoom: 5) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            case .audiovisual(let avPlayer, _):
                VideoPlayer(player: avPlayer)
            case .unknown(let fallbackIcon):
                GeometryReader { geo in
                    ZStack {
                        Image(systemName: fallbackIcon)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }.frame(width: geo.size.width, height: geo.size.height)
                }
            case .none:
                let _ = 0 // do nothing i guess!
            }
            
            VStack(spacing: 0) {
                HStack {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    
                    Spacer()
                    
                    if let altText = attachment.altText {
                        Button {
                            altTextSheetIsShown.toggle()
                        } label: {
                            Image(systemName: "alt").font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .sheet(isPresented: $altTextSheetIsShown) {
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    Text("Alt Text")
                                        .font(.title2)
                                        .padding()
                                    
                                    Spacer()
                                }
                                .overlay(alignment: .topLeading) {
                                    Button {
                                        altTextSheetIsShown = false
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                                    .padding()
                                }
                                
                                GeometryReader { geo in
                                    ScrollView {
                                        VStack {
                                            Spacer()
                                            Text(altText)
                                                .padding()
                                                .textSelection(.enabled)
                                            Spacer()
                                        }.frame(minHeight: geo.size.height)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let data = attachment.data {
                        Button {
                            saveShareSheetIsShown = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .popover(isPresented: $saveShareSheetIsShown) {
                            switch mediaType {
                            case .image(let uiImage, _):
                                ShareSheetView(ShareSheetContent.image(uiImage, data, originalFilename: (attachment.path as NSString).lastPathComponent))
                            case .audiovisual, .unknown:
                                if let mediaUrl = urlForMedia(atPath: attachment.path, forActorId: actorId) {
                                    ShareSheetView(ShareSheetContent.localUrl(mediaUrl))
                                }
                            case .none:
                                let _ = 0 // do nothing i guess??
                            }
                        }
                    }
                    
                    
                }.padding()
                
                Spacer()
            }
        }
        .onAppear {
            initializeIfNecessary()
        }
    }
}

fileprivate enum MediaType {
    case image(UIImage, fallbackIcon: String)
    case audiovisual(AVPlayer, fallbackIcon: String)
    case unknown(fallbackIcon: String)
}

#Preview {
    @State var controlsShown = true
    
    return AttachmentView(actorId: MockData.actor.id, attachment: MockData.attachments[0], onClose: {})
}
