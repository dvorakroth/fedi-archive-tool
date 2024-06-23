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
    
    @State private var db: DbInterface? = nil
    
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
        .task {
            do {
                self.db = try DbInterface.getDbInterface()
            } catch {
                print("error getting the db: \(error)")
            }
        }
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
