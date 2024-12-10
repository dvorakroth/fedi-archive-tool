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
            case .processing(let progress):
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(GodDamnCircularProgressViewStyle())
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
                                    Text(errorText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
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

/**
 the built-in circular progress view style doesn't work on iOS/iPadOS (always shows the indeterminite infinitely-spinning one) so i had to make my fucking own
 
 some developer at apple computer incorporated has already had to contend with writing probably basically this exact code once before and yet here i am having to redo it because reusing built-in things is impossible!!!!!!
 
 and the worst/best part of this, is how apple warns you about this in the `ProgressView` documentation:
 
   > On platforms other than macOS, the circular style may appear as an indeterminate indicator instead.
 
 "may"????? my sibling in deity you developed the other platforms YOU CAN TELL ME WHAT THE BEHAVIOR WILL BE ON THOSE OTHER PLATFORMS YOU DEVELOPED
 
 just another normal day in the Computer industry!!!!!!!!!
 */
struct GodDamnCircularProgressViewStyle: ProgressViewStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geom in
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .fill(colorScheme == .light ? .black : .white)
                    .opacity(0.15)
                    .frame(width: geom.size.width * 0.7, height: geom.size.width * 0.7)
                    .padding(.horizontal, geom.size.width * 0.15)
                    .padding(.vertical, geom.size.height * 0.15)
                
                Circle()
                    .trim(from: 0, to: configuration.fractionCompleted ?? 1.0)
                    .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .fill(Color.accentColor)
                    .rotationEffect(.degrees(-90.0))
                    .animation(.linear, value: configuration.fractionCompleted)
                    .frame(width: geom.size.width * 0.7, height: geom.size.width * 0.7)
                    .padding(.horizontal, geom.size.width * 0.15)
                    .padding(.vertical, geom.size.height * 0.15)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AddArchiveView(importQueue: MockArchiveImportQueue(queueItems: [
        QueueItem(
            id: 1,
            fileURL: URL(string: "file:///path/to/archive.zip")!,
            status: .processing(0.6)
        )
    ]))
}
