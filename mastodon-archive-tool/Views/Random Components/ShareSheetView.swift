//
//  ShareSheetView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 21.07.24.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: [
                OpenInBrowserActivity()
            ]
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareSheetView(url: URL(string: "https://example.net/")!)
}
