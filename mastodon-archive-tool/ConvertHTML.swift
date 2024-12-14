//
//  ConvertHTML.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 29.06.24.
//

import UIKit
import SwiftSoup


func stripHTML(_ htmlString: String) -> String {
    let document: Document
    do {
        document = try SwiftSoup.parseBodyFragment(htmlString)
    } catch {
        print("Error parsing HTML: \(error)")
        return htmlString
    }
    
    let blocks = convertHTMLToBlocks(element: document.body()!)
    
    return stripFormattingFromBlocks(blocks)
}

fileprivate func stripFormattingFromBlocks(_ blocks: [ParsedHTMLNode]) -> String {
    var result = ""
    
    for block in blocks {
        switch block {
        case .text(text: let text):
            result += text.characters
        case .listItem(number: let number, children: let children):
            if let number = number {
                result += " \(number). "
            }
            fallthrough
        case .block(hasMargin: _, children: let children):
            fallthrough
        case .list(items: let children):
            fallthrough
        case .blockquote(children: let children):
            result += " " + stripFormattingFromBlocks(children)
        }
    }
    
    return result
}

func convertHTMLToBlocks(element: Element) -> [ParsedHTMLNode] {
    return convertHTMLToBlocks(element: element, parentAttributes: []) ?? []
}

indirect enum ParsedHTMLNode {
    case text(text: AttributedString)
    case block(hasMargin: Bool, children: [ParsedHTMLNode])
    case listItem(number: Int?, children: [ParsedHTMLNode])
    case list(items: [ParsedHTMLNode])
    case blockquote(children: [ParsedHTMLNode])
}

fileprivate func convertHTMLToBlocks(
    element: Element,
    parentAttributes: [CustomAttributes]
) -> [ParsedHTMLNode]? {
    if element.hasClass("invisible") {
        return nil
    }
    
    let tagName = element.tagName()
    
    if tagName == "br" {
        return [.text(text: AttributedString(
            "\n",
            attributes: customAttributesToRealAttributes(parentAttributes)
        ))]
    }
    
    var updatedAttributes = parentAttributes
    var keepNewlines = false
    
    switch tagName {
    case "b", "strong":
        updatedAttributes.append(.bold)
    case "i", "em":
        updatedAttributes.append(.italic)
    case "u", "ins":
        updatedAttributes.append(.underline)
    case "strike", "s", "del":
        updatedAttributes.append(.strikethrough)
    case "pre":
        keepNewlines = true
        fallthrough
    case "code":
        updatedAttributes.append(.code)
    case "blockquote":
        updatedAttributes.append(.blockquote)
    case "sub":
        updatedAttributes.append(.sub)
    case "sup":
        updatedAttributes.append(.sup)
    case "h1":
        updatedAttributes.append(.heading(1))
    case "h2":
        updatedAttributes.append(.heading(2))
    case "h3":
        updatedAttributes.append(.heading(3))
    case "h4":
        updatedAttributes.append(.heading(4))
    case "h5":
        updatedAttributes.append(.heading(5))
    case "h6":
        updatedAttributes.append(.heading(6))
    case "a":
        if let href = try? element.attr("href") {
            updatedAttributes.append(.link(to: href))
        }
    default: break
    }
    
    var convertedChildren: [ParsedHTMLNode] = []
    
    for childNode in element.getChildNodes() {
        guard !(childNode is Comment || childNode is DocumentType) else {
            continue
        }
        
        if let childNode = childNode as? TextNode {
            convertedChildren.append(.text(text: AttributedString(
                keepNewlines
                    ? childNode.getWholeText()
                    : (childNode.text().replacingOccurrences(of: "\n", with: "")),
                attributes: customAttributesToRealAttributes(updatedAttributes)
            )))
        } else if let childElement = childNode as? Element {
            convertedChildren.append(contentsOf: convertHTMLToBlocks(element: childElement, parentAttributes: updatedAttributes) ?? [])
        }
    }
    
    // unify adjacent text nodes
    convertedChildren = convertedChildren.reduce(into: []) { result, child in
        guard result.count >= 1 else {
            result.append(child)
            return
        }
        
        if case .text(let newText) = child {
            if case .text(let prevText) = result.last {
                result.remove(at: result.count - 1)
                result.append(.text(text: prevText + newText))
                return
            }
        }
        
        result.append(child)
    }
    
    if !keepNewlines {
        // trim spaces at the beginnings and ends of lines
        convertedChildren = convertedChildren.map {
            child in
            switch child {
            case .text(text: let text):
                return .text(text: text.trimmingSpacesAtStartEndAndAroundNewlines())
            default:
                return child
            }
        }
        
        // remove text nodes that are entirely whitespace?
        convertedChildren = convertedChildren.filter {
            child in
            switch child {
            case .text(text: let text):
                return !text.characters.isEmpty
            default:
                return true
            }
        }
    }
    
    switch tagName {
    case "li":
        return [.listItem(number: nil, children: convertedChildren)]
    case "ul":
        return [.list(items: convertedChildren)]
    case "ol":
        var listItemCounter = 1
        for (idx, child) in convertedChildren.enumerated() {
            if case .listItem(_, let children) = child {
                convertedChildren[idx] = .listItem(number: listItemCounter, children: children)
                listItemCounter += 1
            }
        }
        return [.list(items: convertedChildren)]
    case "blockquote":
        return [.blockquote(children: convertedChildren)]
    default:
        break
    }
    
    if BLOCK_DISPLAY_TAGS.firstIndex(of: tagName) != nil {
        return [.block(hasMargin: tagName.starts(with: "h"), children: convertedChildren)]
    }
    
    return convertedChildren
}

fileprivate enum CustomAttributes {
    case bold
    case italic
    case underline
    case strikethrough
    case code
    case blockquote
    case sub
    case sup
    case heading(Int)
    case link(to: String)
}

fileprivate let BLOCK_DISPLAY_TAGS = ["p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "pre"]

fileprivate func customAttributesToRealAttributes(_ customAttributes: [CustomAttributes]) -> AttributeContainer {
    var result: [NSAttributedString.Key: Any] = [:]
    
    let defaultFont = UIFont.preferredFont(forTextStyle: .body)
    
    var requestedSize: CGFloat = defaultFont.pointSize
    var shouldBeBold = false
    var shouldBeItalic = false
    var shouldBeMonospaced = false
    var subOrSuperLevel = 0
    
    for customAttribute in customAttributes {
        switch customAttribute {
        case .bold:
            shouldBeBold = true
            
        case .italic:
            shouldBeItalic = true
            
        case .underline:
            result[.underlineStyle] = NSUnderlineStyle.single.rawValue
        
        case .strikethrough:
            result[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            
        case .code:
            shouldBeMonospaced = true
        
        case .sub:
            subOrSuperLevel -= 1
        
        case .sup:
            subOrSuperLevel += 1
            
        case .heading(let level):
            shouldBeBold = true
            
            switch level {
            case 1:
                requestedSize *= 2
            case 2:
                requestedSize *= 1.5
            case 3:
                requestedSize *= 1.17
            case 4:
                requestedSize *= 1
            case 5:
                requestedSize *= 0.83
            case 6:
                requestedSize *= 0.67
            default: break
            }
            
        case .link(to: let href):
            if let url = URL(string: href) {
                result[.link] = url
            } else {
                print("Could not parse URL: \(href)")
            }
        
        default: break
        }
    }
    
    var baselineOffset: CGFloat = 0
    for _ in 0..<abs(subOrSuperLevel) {
        requestedSize *= 0.65
        if subOrSuperLevel > 0 {
            baselineOffset += requestedSize * 0.45
        } else {
            baselineOffset -= requestedSize * 0.2
        }
    }
    result[.baselineOffset] = baselineOffset
    
    var symbolicTraits: UIFontDescriptor.SymbolicTraits = []
    if shouldBeBold {
        symbolicTraits.insert(.traitBold)
    }
    if shouldBeItalic {
        symbolicTraits.insert(.traitItalic)
    }
    if shouldBeMonospaced {
        symbolicTraits.insert(.traitMonoSpace)
    }
    
    let font = UIFont(
        descriptor: defaultFont.fontDescriptor.withSymbolicTraits(symbolicTraits)!,
        size: requestedSize
    )
    
    result[.font] = font
    
    return AttributeContainer(result)
}
