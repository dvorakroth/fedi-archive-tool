//
//  AttachmentView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 01.09.24.
//

import SwiftUI
import AVKit

struct AttachmentView: View {
    let attachment: APubDocument
    let onClose: () -> Void
    
    @State var saveShareSheetIsShown = false
    @State var altTextSheetIsShown = false
    @State var tmpAVDir: TempDir? = nil
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
            if let mediaUrl = writeAVToTempDir() {
                mediaType = .audiovisual(AVPlayer(url: mediaUrl), fallbackIcon: fallbackIcon)
            } else {
                mediaType = .unknown(fallbackIcon: fallbackIcon)
            }
        } else if attachment.mediaType.starts(with: "audio/") {
            let fallbackIcon = "headphones.circle"
            if let mediaUrl = writeAVToTempDir() {
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
                                ShareSheetView(image: uiImage, data: attachment.data ?? Data(), mimetype: attachment.mediaType)
                            case .audiovisual, .unknown:
                                ShareSheetView(fileData: data, mimetype: attachment.mediaType)
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

    func writeAVToTempDir() -> URL? {
        guard let data = attachment.data else {
            return nil
        }
        
        let needToCreateFile: Bool
        
        if tmpAVDir == nil {
            do {
                tmpAVDir = try TempDir()
            } catch {
                print("Error creating temporary directory: \(error)")
                return nil
            }
            
            needToCreateFile = true
        } else {
            needToCreateFile = false
        }
        
        let fileExtension = mimetypesToExtensions[attachment.mediaType] ?? ".bin"
        let fileUrl: URL = tmpAVDir!.url.appendingPathComponentNonDeprecated("mediaFile" + fileExtension)
        
        if needToCreateFile {
            do {
                try data.write(to: fileUrl)
            } catch {
                print("Error writing video to temporary directory: \(error)")
                return nil
            }
        }
        
        return fileUrl
    }
}

fileprivate enum MediaType {
    case image(UIImage, fallbackIcon: String)
    case audiovisual(AVPlayer, fallbackIcon: String)
    case unknown(fallbackIcon: String)
}

#Preview {
    @State var controlsShown = true
    
    return AttachmentView(attachment: MockData.attachments[0], onClose: {})
}
