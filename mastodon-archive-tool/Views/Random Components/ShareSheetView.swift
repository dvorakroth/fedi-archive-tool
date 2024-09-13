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
    
    init(fileData: Data, mimetype: String) {
        self.content = .fileData(fileData, mimetype: mimetype)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
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
            
        case .fileData(let fileData, let mimetype):
            let filename = "attachment" + (mimetypesToExtensions[mimetype] ?? ".bin")
            let tmpDir = FileManager.default.temporaryDirectory
            let fileUrl = tmpDir.appendingPathComponentNonDeprecated(filename)
            do {
                try fileData.write(to: fileUrl)
            } catch {
                print("Writing temp file \(fileUrl) encountered an error: \(error)")
                return UIViewController()
            }
            
            let v = UIActivityViewController(
                activityItems: [fileUrl],
                applicationActivities: nil //[MacCatalystSaveFileActivity(data: fileData, mimetype: mimetype)]
            )
            
            // kludge for now until i refactor some db shit: delete file after completion but only sometimes because this is quite finicky apparently
            v.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                } catch {
                    print("Deleting temp file \(fileUrl) encountered an error: \(error)")
                }
            }
            return v
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

fileprivate enum ShareSheetContent {
    case url(URL)
    case image(UIImage, Data, mimetype: String)
    case fileData(Data, mimetype: String)
}

#Preview {
    ShareSheetView(url: URL(string: "https://example.net/")!)
}
