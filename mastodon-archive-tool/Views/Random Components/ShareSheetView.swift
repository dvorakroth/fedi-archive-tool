//
//  ShareSheetView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 21.07.24.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    private let content: ShareSheetContent
    
    init(_ content: ShareSheetContent) {
        self.content = content
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
        
        case .localUrl(let url):
            return UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
        case .image(let image, let data, let originalFilename):
            return UIActivityViewController(
                activityItems: [image],
                applicationActivities: [MacCatalystSaveFileActivity(data: data, originalFilename: originalFilename)]
            )
            
//        case .fileData(let fileData, let mimetype):
//            let filename = "attachment" + (mimetypesToExtensions[mimetype] ?? ".bin")
//            let tmpDir = FileManager.default.temporaryDirectory
//            let fileUrl = tmpDir.appendingPathComponentNonDeprecated(filename)
//            do {
//                try fileData.write(to: fileUrl)
//            } catch {
//                print("Writing temp file \(fileUrl) encountered an error: \(error)")
//                return UIViewController()
//            }
//            
//            let v = UIActivityViewController(
//                activityItems: [fileUrl],
//                applicationActivities: nil //[MacCatalystSaveFileActivity(data: fileData, mimetype: mimetype)]
//            )
//            
//            // kludge for now until i refactor some db shit: delete file after completion but only sometimes because this is quite finicky apparently
//            v.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
//                do {
//                    try FileManager.default.removeItem(at: fileUrl)
//                } catch {
//                    print("Deleting temp file \(fileUrl) encountered an error: \(error)")
//                }
//            }
//            return v
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

enum ShareSheetContent {
    case url(URL)
    case localUrl(URL)
    case image(UIImage, Data, originalFilename: String)
//    case fileData(Data, mimetype: String)
}

#Preview {
    ShareSheetView(ShareSheetContent.url(URL(string: "https://example.net/")!))
}
