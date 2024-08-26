//
//  AddArchiveView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI

struct AddArchiveView: View {
    @ObservedObject var importQueue = ArchiveImportQueue.getQueue()
    
    @State private var showDocumentPicker = false
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let onSuccessfulLoad: () -> ()
    
    var body: some View {
        VStack {
            Spacer().frame(height: 15)
            
            List {
                ForEach(importQueue.queue, id: \.id) { item in
                    HStack {
                        switch item.status {
                        case .waiting:
                            Image(systemName: "clock")
                                .frame(width: 27, height: 27)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                        case .processing:
                            ProgressView().progressViewStyle(.circular)
                                .frame(width: 27, height: 27)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                        case .done:
                            Image(systemName: "checkmark.circle.fill").renderingMode(.template).foregroundStyle(.green)
                                .frame(width: 27, height: 27)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                        case .error:
                            Image(systemName: "exclamationmark.circle.fill").renderingMode(.original)
                                .frame(width: 27, height: 27)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                        }
                        Text("\(item.fileURL.lastPathComponent)")
                        Spacer()
                    }
                }
                
                Button(action: {
                    showDocumentPicker = true
                }, label: {
                    Label("Add new archive", systemImage: "plus")
                })
            }
        }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.zip, .gzip],
                allowsMultipleSelection: false,
                onCompletion: self.openArchive
            )
            .navigationTitle("Import Queue")
    }
    
    func openArchive(urlOrError: Result<[URL], any Error>) {
        switch(urlOrError) {
        case .failure(let error):
            // TODO ...something?
            print(error)
            
        case .success(let urls):
            importQueue.addToQueue(urls[0])
        }
    }
}

#Preview {
    AddArchiveView() {}
}
