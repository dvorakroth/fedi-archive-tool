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
    
    init(image: UIImage, data: Data, mimetype: String) {
        self.content = .image(image, data, mimetype: mimetype)
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
            
        case .image(let image, let data, let mimetype):
            return UIActivityViewController(
                activityItems: [image],
                applicationActivities: [MacCatalystSaveFileActivity(data: data, mimetype: mimetype)]
            )
        }
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

fileprivate enum ShareSheetContent {
    case url(URL)
    case image(UIImage, Data, mimetype: String)
}

#Preview {
    ShareSheetView(url: URL(string: "https://example.net/")!)
}
