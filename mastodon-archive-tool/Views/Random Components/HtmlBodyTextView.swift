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
    
    private let listColumns = [
        GridItem(.fixed(10)),
        GridItem(.flexible(minimum: 10, maximum: 30), alignment: .top),
        GridItem(.flexible(), alignment: .leading)
    ]
    
    var body: some View {
        switch node {
        case .text(text: let attrStr):
            if attrStr.characters.count > 1 || !attrStr.characters.allSatisfy({ $0 == " "}) {
                Text(attrStr)
            }
        case .block(hasMargin: let hasMargin, children: let children):
            VStack(alignment: .leading) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node)
                }
            }.padding(.vertical, hasMargin ? 10 : 0)
        case .list(items: let children):
            LazyVGrid(columns: listColumns, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HStack {
                        Spacer()
                    }
                    HStack {
                        if case .listItem(let number, _) = node {
                            if let number = number {
                                Text("\(number).").padding(.vertical, 2)
                            } else {
                                Text("•").padding(.vertical, 2)
                            }
                        } else {
                            Spacer()
                        }
                    }
                    HStack {
                        HTMLElementView(node: node)
                    }
                }
            }
        case .listItem(number: _, children: let children):
            VStack(alignment: .leading) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node)
                }
            }.padding(.vertical, 2)
        case .blockquote(children: let children):
            HStack {
                VStack(alignment: .leading) {
                    ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                        HTMLElementView(node: node)
                    }
                }
                    .padding(.leading, 25)
                    .padding(.vertical, 10)
            }.overlay {
                HStack {
                    Rectangle().frame(width: 2).padding(.leading, 6)
                    Spacer()
                }
            }
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
        <ol>
            <p>well,</p>
            <li>one<br>real<br>thing</li>
            <li>two lorem ipsum dolor sit amet consectetur adipiscing velit does the word wrapping actually work this time</li>
            <li>three</li>
            <li>
                <ul>
                    <li>four point one, lorem ipsum dolor sit amet consectetur adipiscing velit</li>
                    <li>four point two</li>
                    <li>four point three</li>
                </ul>
            </li>
        </ol>
        <blockquote>
            <p>what is any of this anyway? <sup>2</sup>U<sub>2</sub> <s>nevermind</s></p>
            <p>none of anything is clear</p>
            <code>function test() {
        print("hello, world!\n");
        return 0;
    }</code>
            <blockquote>
                <p>will my amazing new code be able to handle nested blockquotes?</p>
                <br>
                <p>of course it will!</p>
            </blockquote>
        </blockquote>
    """)
}