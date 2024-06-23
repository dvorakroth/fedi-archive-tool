//
//  AddArchiveView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI

struct AddArchiveView: View {
    @State private var addArchiveState: AddArchiveState = .waiting
    @State private var showDocumentPicker = true
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let onSuccessfulLoad: () -> ()
    
    var body: some View {
        VStack {
            switch(addArchiveState) {
            case .waiting:
                Text("...")
            case .processing(filename: let filename):
                ProgressView().progressViewStyle(.circular)
                Text("Processing \(filename)...")
            case .error(filename: let filename, errorText: let errorText):
                if let filename = filename {
                    Text("Error processing \(filename)").font(.title)
                } else {
                    Text("Error opening file").font(.title)
                }
                Text(errorText)
            case .done(let actor):
                Text("Done importing archive for \(actor.fullUsername)!")
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Go back")
                }
            }
        }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.zip, .gzip],
                allowsMultipleSelection: false,
                onCompletion: self.openArchive
            )
    }
    
    func openArchive(urlOrError: Result<[URL], any Error>) {
        switch(urlOrError) {
        case .failure(let error):
            addArchiveState = .error(filename: nil, errorText: error.localizedDescription)
            
        case .success(let urls):
            let url = urls[0]
            self.addArchiveState = .processing(filename: url.lastPathComponent)
            print("trying to open archive at \(url.absoluteString)")
            
            Task {
                do {
                    let actor = try await readArchive(url)
                    self.addArchiveState = .done(actor)
                    self.onSuccessfulLoad()
                } catch {
                    self.addArchiveState = .error(filename: url.lastPathComponent, errorText: error.localizedDescription)
                }
            }
        }
        

    }
}

enum AddArchiveState {
    case waiting
    case processing(filename: String)
    case error(filename: String?, errorText: String)
    case done(APubActor)
}

#Preview {
    AddArchiveView() {}
}
