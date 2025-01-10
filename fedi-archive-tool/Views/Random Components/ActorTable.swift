//
//  ActorTable.swift
//  fedi-archive-tool
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
                        HtmlBodyTextView(htmlString: content)
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
        ("Amateur nouns", "<a href=\"https://example.com/\">har/har</a>")
    ])
}
