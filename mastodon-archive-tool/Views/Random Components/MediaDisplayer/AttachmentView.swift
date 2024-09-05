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
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        HStack {
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
                                .padding()
                                .popover(isPresented: $saveShareSheetIsShown, content: {
                                    ShareSheetView(image: uiImage, data: attachment.data ?? Data(), mimetype: attachment.mediaType)
                                })
                            }
                            
                            Spacer()
                            
                            Button {
                                onClose()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .padding()
                        }.padding()
                        
                        Spacer()
                        
                        if let altText = attachment.altText {
                            LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0, blue: 0, opacity: 0),
                                    Color(red: 0, green: 0, blue: 0, opacity: 0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: geo.size.width, height: 20)
                            
                            Text(altText)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(width: geo.size.width)
                                .background {
                                    Color(red: 0, green: 0, blue: 0, opacity: 0.8)
                                }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @State var controlsShown = true
    
    return AttachmentView(attachment: MockData.attachments[0], controlsShown: $controlsShown, onClose: {})
}
