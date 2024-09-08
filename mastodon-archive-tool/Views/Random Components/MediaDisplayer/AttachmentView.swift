//
//  AttachmentView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 01.09.24.
//

import SwiftUI

struct AttachmentView: View {
    let attachment: APubDocument
    @Binding var controlsShown: Bool
    let onClose: () -> Void
    
    @State var saveShareSheetIsShown = false
    @State var altTextSheetIsShown = false
    
    
    var body: some View {
        let uiImage: UIImage?
        let fallbackIconName: String
        
        if attachment.mediaType.starts(with: "image/") {
            if let data = attachment.data {
                let _ = uiImage = UIImage(data: data)
            } else {
                let _ = uiImage = nil
            }
            let _ = fallbackIconName = "questionmark.square.dashed"
        } else if attachment.mediaType.starts(with: "video/") {
            let _ = uiImage = nil
            let _ = fallbackIconName = "video.square"
        } else if attachment.mediaType.starts(with: "audio/") {
            let _ = uiImage = nil
            let _ = fallbackIconName = "headphones.circle"
        } else {
            let _ = uiImage = nil
            let _ = fallbackIconName = "questionmark.square.dashed"
        }
        
        ZStack {
            if let uiImage = uiImage {
                ZoomView(minZoom: 1, maxZoom: 5, enabled: !controlsShown) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .onTapGesture(count: 1) {
                    withAnimation {                            controlsShown.toggle()
                    }
                }
            } else {
                GeometryReader { geo in
                    ZStack {
                        Image(systemName: fallbackIconName)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .foregroundStyle(Color(red: 0, green: 0, blue: 0, opacity: 0.01)) // the foreground color is so that this rectangle stays clickable
                            .onTapGesture(count: 1) {
                                withAnimation {
                                    controlsShown.toggle()
                                }
                            }
                    }.frame(width: geo.size.width, height: geo.size.height)
                }
                
            }
            
            if controlsShown {
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
                        
                        if let uiImage = uiImage {
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
                                ShareSheetView(image: uiImage, data: attachment.data ?? Data(), mimetype: attachment.mediaType)
                            }
                        }
                        
                        
                    }.padding()
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    @State var controlsShown = true
    
    return AttachmentView(attachment: MockData.attachments[0], controlsShown: $controlsShown, onClose: {})
}
