//
//  ContentView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 22.06.24.
//

import SwiftUI

struct ContentView: View {
    @State private var showDocumentPicker = false
    @State private var archiveUrl: URL? = nil
    
    var body: some View {
        VStack {
            Button(action: {showDocumentPicker.toggle()}, label: {
                Image(systemName: "folder.badge.plus")
                Text("Open an Archive")
                    .fileImporter(
                        isPresented: $showDocumentPicker,
                        allowedContentTypes: [.zip, .gzip],
                        allowsMultipleSelection: false,
                        onCompletion: self.openArchive
                    )
            })
        }
        .padding()
    }
        
    func openArchive(urlOrError: Result<[URL], any Error>) {
        switch(urlOrError) {
        case .failure(_):
            return //?
        case .success(let urls):
            self.archiveUrl = urls[0]
            print("should be opening archive at \(archiveUrl?.absoluteString ?? "nil")")
        }
    }
}

#Preview {
    ContentView()
}
