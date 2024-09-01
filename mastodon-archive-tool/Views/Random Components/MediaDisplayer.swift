//
//  MediaDisplayer.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 31.08.24.
//

import SwiftUI
import LazyPager

struct MediaDisplayer<Content>: View where Content: View {
    let content: (_: @escaping MediaViewerCallback) -> Content
    
    @State fileprivate var state: MediaViewerState = .hidden
    @State var bgOpacity: CGFloat = 1
    
    var _$isPresented: Binding<Bool> {
        Binding<Bool> {
            state != .hidden
        } set: { newValue in
            if !newValue {
                state = .hidden
            } else {
                // ???? do nothing i guess??
                print("Warning: tried to directly set _$fullscreenMediaIsPresented to true???")
            }
        }
    }
    
    var _$attachments: Binding<[APubDocument]> {
        Binding<[APubDocument]> {
            switch state {
            case .hidden:
                return []
            case .shown(let attachments, _):
                return attachments
            }
        } set: { _ in
            print("??? tried to set _$attachments directly!")
        }
    }
    
    var _$attachmentIdx: Binding<Int> {
        Binding<Int> {
            switch state {
            case .hidden:
                return 0
            case .shown(_, let attachmentIdx):
                return attachmentIdx
            }
        } set: { newIdx in
            switch state {
            case .hidden:
                break
            case .shown(let attachments, _):
                state = .shown(attachments: attachments, attachmentIdx: newIdx)
            }
        }

    }

    
    init(@ViewBuilder content: @escaping (_: @escaping MediaViewerCallback) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content({ attachments, attachmentIdx in
            state = .shown(attachments: attachments, attachmentIdx: attachmentIdx)
        })
        .fullScreenCover(isPresented: _$isPresented) {
            LazyPager(data: _$attachments.wrappedValue, page: _$attachmentIdx) { attachment in
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
                
                VStack {
                    if let uiImage = uiImage {
                        ZoomView(minZoom: 1, maxZoom: 5) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    } else {
                        Image(systemName: fallbackIconName).font(.title)
                    }
                }
            }
            // don't use the LazyPager's `zoomable` function because some items might not be zoomable (for example, missing/undisplayable media placeholders)
            .onDismiss(backgroundOpacity: $bgOpacity) {
                state = .hidden
            }
            .background(.black.opacity(bgOpacity))
            .background(ClearFullScreenBackground())
            .ignoresSafeArea()
        }
    }
}

typealias MediaViewerCallback = (_: [APubDocument], _: Int) -> Void

fileprivate enum MediaViewerState: Equatable {
    static func == (lhs: MediaViewerState, rhs: MediaViewerState) -> Bool {
        switch lhs {
        case .hidden:
            switch rhs {
            case .hidden:
                return true
            default:
                return false
            }
        case .shown(attachments: let attachments1, attachmentIdx: let idx1):
            switch rhs {
            case .shown(attachments: let attachments2, attachmentIdx: let idx2):
                return zip(attachments1, attachments2).allSatisfy({ a1, a2 in
                    a1 === a2
                }) && idx1 == idx2
            default:
                return false
            }
        }
    }
    
    case hidden
    case shown(attachments: [APubDocument], attachmentIdx: Int)
}
