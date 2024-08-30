//
//  AttachmentPreviewView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 13.07.24.
//

import SwiftUI
import AVKit
import BlurHash

enum AttachmentType {
    case image
    case video
    case audio
    case unknown
}

struct AttachmentPreviewView: View {
    let attachment: APubDocument
    let attachmentType: AttachmentType
    let onImageTapped: (() -> Void)?
    
    @State var blurhashImage: UIImage?;
    @State var isHidden: Bool
    
    init(attachment: APubDocument, hiddenByDefault: Bool, onImageTapped: (() -> Void)? = nil) {
        self.attachment = attachment
        
        if attachment.mediaType.starts(with: "image/") {
            self.attachmentType = .image
        } else if attachment.mediaType.starts(with: "video/") {
            self.attachmentType = .video
        } else if attachment.mediaType.starts(with: "audio/") {
            self.attachmentType = .audio
        } else {
            self.attachmentType = .unknown
        }
        
        self.isHidden = hiddenByDefault
        self.onImageTapped = onImageTapped
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if isHidden {
                    ImageOrRectangle(
                        image: .image(blurhashImage),
                        fallbackColor: .secondary,
                        fallbackIcon: nil,
                        width: geo.size.width,
                        height: 150
                    )
                        .cornerRadius(5)
                        .task {
                            guard blurhashImage == nil else {
                                return
                            }
                            
                            if let blurhash = attachment.blurhash {
                                let newImage = await withCheckedContinuation { continuation in
                                    Task.detached(priority: .medium) {
                                        continuation.resume(returning: UIImage(blurHash: blurhash, size: CGSize(width: 500, height: 250)))
                                    }
                                }
                                
                                withAnimation {
                                    blurhashImage = newImage
                                }
                            }
                        }
                    
                    Button("Show media") {
                        withAnimation {
                            isHidden.toggle()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    let image: Data?
                    let fallbackIconName: String
                    
                    switch (attachmentType) {
                    case .image:
                        let _ = image = attachment.data
                        let _ = fallbackIconName = "questionmark.square.dashed"
                    case .video:
                        let _ = image = nil
                        let _ = fallbackIconName = "video.square"
                    case .audio:
                        let _ = image = nil
                        let _ = fallbackIconName = "headphones.circle"
                    case .unknown:
                        let _ = image = nil
                        let _ = fallbackIconName = "questionmark.square.dashed"
                    }
                    
                    ImageOrRectangle(
                        image: .data(image),
                        fallbackColor: .secondary,
                        fallbackIcon: (
                            name: fallbackIconName,
                            color: .secondaryLabel,
                            size: 45
                        ),
                        width: geo.size.width,
                        height: 150,
                        contentMode: .fit
                    ).cornerRadius(5)
                        .onTapGesture {
                            if let onImageTapped = onImageTapped {
                                onImageTapped()
                            }
                        }
                    
                    VStack {
                        HStack {
                            Button(
                                action: {
                                    withAnimation {
                                        isHidden.toggle()
                                    }
                                },
                                label: {
                                    Image(systemName: "eye.slash")
                                }
                            )
                            .buttonStyle(.borderedProminent)
                            .padding(.leading)
                            .padding(.top)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }.frame(height: 150)
    }
}

#Preview {
    AttachmentPreviewView(attachment: APubDocument(mediaType: "image/png", data: nil, altText: "a picture of a dog", blurhash: "WA9Z_$j[00%2%M9ZE1jsxtWBa}xt00j?~pNGM{%M-:j[M|t7WBIU", focalPoint: nil, size: nil), hiddenByDefault: true)
}
