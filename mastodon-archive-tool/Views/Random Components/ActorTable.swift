//
//  ActorTable.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import SwiftUI

struct ActorTable: View {
    let table: [(String, String)];
    
    init(_ table: [(String, String)]) {
        self.table = table
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Divider()
            ForEach(table, id: \(String, String).0) { (title, content) in
                VStack(spacing: 4) {
                    HStack {
                        Text(title).font(.caption)
                        Spacer()
                    }.padding(.horizontal)
                    HStack {
                        Text(convertHTML(content)).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }.padding(.horizontal)
                    Spacer().frame(height: 4)
                    Divider()
                }
            }
        }
    }
}

#Preview {
    ActorTable([
        ("Pronouns", "they/them"),
        ("Amateur nouns", "har/har")
    ])
}
