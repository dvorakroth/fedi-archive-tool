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
    
    var body: some View {
        VStack {
            Spacer().frame(height: 15)
            
            List {
                ForEach(importQueue.queue, id: \.id) { item in
                    QueueItemView(queueItem: item)
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

struct QueueItemView: View {
    let queueItem: QueueItem
    
    @State var showErrorModal = false
    
    var body: some View {
        HStack {
            switch queueItem.status {
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
            case .error(let errorText):
                Button {
                    showErrorModal = true
                } label: {
                    Image(systemName: "exclamationmark.circle.fill").renderingMode(.original)
                        .frame(width: 27, height: 27)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                }.sheet(isPresented: $showErrorModal) {
                    GeometryReader { geo in
                        ScrollView {
                            VStack {
                                VStack {
                                    Text("Error importing \(queueItem.fileURL.lastPathComponent)").font(.title)
                                    Spacer().frame(height: 15)
                                    Text(errorText).fixedSize(horizontal: false, vertical: true)
                                    Spacer().frame(height: 15)
                                    Button("Done") {
                                        showErrorModal = false
                                    }.buttonStyle(.borderedProminent)
                                }.padding(.all)
                            }.frame(minHeight: geo.size.height)
                        }
                    }
                }
            }
            Text("\(queueItem.fileURL.lastPathComponent)")
            Spacer()
        }
    }
}

#Preview {
    AddArchiveView()
}
