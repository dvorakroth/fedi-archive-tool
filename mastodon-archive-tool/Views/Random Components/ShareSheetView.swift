//
//  ShareSheetView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 21.07.24.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    private let content: ShareSheetContent
    
    init(url: URL) {
        self.content = .url(url)
    }
    
    init(image: UIImage) {
        self.content = .image(image)
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        switch content {
        case .url(let url):
            return UIActivityViewController(
                activityItems: [url],
                applicationActivities: [
                    OpenInBrowserActivity()
                ]
            )
            
        case .image(let image):
            let activities: [UIActivity]
//            #if targetEnvironment(macCatalyst)
//            activities = [MacCatalystSaveFileActivity()]
//            #else
            activities = []
//            #endif
            
            return UIActivityViewController(
                activityItems: [image],
                applicationActivities: activities
            )
        }
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

fileprivate enum ShareSheetContent {
    case url(URL)
    case image(UIImage)
}

#Preview {
    ShareSheetView(url: URL(string: "https://example.net/")!)
}
