//
//  HtmlBodyTextView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 10.12.24.
//

import SwiftUI
import SwiftSoup

struct HtmlBodyTextView: View {
    @Environment(\.sizeCategory) var sizeCategory
    
    let htmlString: String

    
    private func parseHtml() -> ParseState {
        let document: Document
        do {
            document = try SwiftSoup.parseBodyFragment(htmlString)
        } catch {
            return .error("Error parsing HTML: \(error)\n\nOriginal HTML: \(htmlString)")
        }
        
        return .success(convertHTMLToBlocks(
            element: document.body()!,
            defaultFont: UIFont.preferredFont(forTextStyle: .body)
        ))
    }
    
    var body: some View {
        switch parseHtml() {
        case .success(let nodes):
            VStack(alignment: .leading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node, isFirst: idx == 0, isLast: idx == nodes.count - 1)
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
    let isFirst: Bool
    let isLast: Bool
    
    private let listColumns = [
        GridItem(.fixed(10)),
        GridItem(.flexible(minimum: 10, maximum: 30), alignment: .top),
        GridItem(.flexible(), alignment: .leading)
    ]
    
    var body: some View {
        switch node {
        case .text(text: let attrStr):
            if attrStr.characters.count > 1 || !attrStr.characters.allSatisfy({ $0 == " "}) {
                Text(attrStr).fixedSize(horizontal: false, vertical: true)
            }
        case .block(hasMargin: let hasMargin, children: let children):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node, isFirst: idx == 0, isLast: idx == children.count - 1)
                }
            }
                .padding(.top, (isFirst && !hasMargin ? 0 : 10))
                .padding(.bottom, (isLast && !hasMargin ? 0 : 10))
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
                        HTMLElementView(node: node, isFirst: idx == 0, isLast: idx == children.count - 1)
                    }
                }
            }
        case .listItem(number: _, children: let children):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                    HTMLElementView(node: node, isFirst: idx == 0, isLast: idx == children.count - 1)
                }
            }.padding(.vertical, 2)
        case .blockquote(children: let children):
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { (idx, node) in
                        HTMLElementView(node: node, isFirst: idx == 0, isLast: idx == children.count - 1)
                    }
                }
                    .padding(.leading, 15)
            }.overlay {
                HStack {
                    Rectangle().frame(width: 2).padding(.leading, 2)
                    Spacer()
                }
            }
            .padding(.top, isFirst ? 0 : 10)
            .padding(.bottom, isLast ? 0 : 10)
        }
        
    }
}

#Preview {
    ScrollView {
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
                    <li>doin some weird <a href="mailto:ish@example.net">shit <h1>hello</h1> ugh</a> but i guess it works!</li>
                </ul>
            </li>
        </ol>
        <blockquote>
            <p>what is any of this anyway? <sup>2</sup>U<sub>2</sub> <s>nevermind</s></p>
            <p>none of anything is clear</p>
            <p>if only i could render html without <code>resorting
    to any of</code> this drudgery!
            <pre>function test() {
        print("hello, world!\\n");<b>jkl</b>
        return 0;
    }</pre></p>
            <blockquote>
                <p>will my amazing new code be able to handle nested blockquotes?
                <br>
                of course it will!</p>
                <blockquote>
                    <p>amazing</p>
                </blockquote>
            </blockquote>
        </blockquote>
    """)
    }.padding()
}
