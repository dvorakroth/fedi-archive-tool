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
            switch state {
            case .hidden:
                return false
            case .shown:
                return true
            }
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
                AttachmentView(attachment: attachment) {
                    _$isPresented.wrappedValue = false
                }
            }
            // don't use the LazyPager's `zoomable` function because some items might not be zoomable (for example, missing/undisplayable media placeholders)
            .onDismiss(backgroundOpacity: $bgOpacity) {
                state = .hidden
            }
            .background(.black.opacity(bgOpacity))
            .background(ClearFullScreenBackground())
//            .ignoresSafeArea()
        }
    }
}

typealias MediaViewerCallback = (_: [APubDocument], _: Int) -> Void

fileprivate enum MediaViewerState {
    case hidden
    case shown(attachments: [APubDocument], attachmentIdx: Int)
}

#Preview {
    MediaDisplayer { showMedia in
        Button {
            showMedia(MockData.attachments, 0)
        } label: {
            Text("Show Media")
        }
        .onAppear {
            showMedia(MockData.attachments, 0)
        }
    }
}
