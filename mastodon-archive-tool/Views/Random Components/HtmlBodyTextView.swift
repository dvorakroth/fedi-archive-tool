//
//  HtmlBodyTextView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 10.12.24.
//

import SwiftUI
import SwiftSoup

struct HtmlBodyTextView: View {
    private let parsedHtml: ParseState
    
    init(htmlString: String) {
        do {
            let document = try SwiftSoup.parseBodyFragment(htmlString)
            
            parsedHtml = .success(convertHTMLToBlocks(element: document.body()!))
        } catch {
            parsedHtml = .error("Error parsing HTML: \(error)\n\nOriginal HTML: \(htmlString)")
            
        }
    }
    
    var body: some View {
        switch parsedHtml {
        case .success(let nodes):
            VStack(alignment: .leading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node)
                }
            }
        case .error(let errorText):
            Text(errorText)
        }
    }
}

fileprivate enum ParseState {
    case success([ParsedHTMLNode])
    case error(String)
}

fileprivate struct HTMLElementView: View {
    let node: ParsedHTMLNode
    
    var body: some View {
        switch node {
        case .text(text: let attrStr):
            if attrStr.characters.count > 1 || !attrStr.characters.allSatisfy({ $0 == " "}) {
                Text(attrStr)
            }
        case .block(children: let children):
            VStack(alignment: .leading) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node)
                }
            }.padding(.vertical)
        default:
            Text("TODO;")
        }
        
    }
}

#Preview {
    HtmlBodyTextView(htmlString: """
        <h1>Test post</h1>
        <p>hello,
            world! this   is a long text string but the main point of it all is really that what you should do is you should
            <a href=\"https://ish.works/\">click <b>here</b></a>
        </p>
        <ul>
            <li>one</li>
            <li>two</li>
            <li>three</li>
        </ul>
    """)
}
