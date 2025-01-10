//
//  ConvertHTML.swift
//  fedi-archive-tool
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
    
    let blocks = convertHTMLToBlocks(element: document.body()!, defaultFont: UIFont.preferredFont(forTextStyle: .body))
    
    return stripFormattingFromBlocks(blocks)
}

fileprivate func stripFormattingFromBlocks(_ blocks: [ParsedHTMLNode]) -> String {
    var result = ""
    
    for block in blocks {
        switch block {
        case .text(text: let text, isRtl: _):
            result += text.characters
        case .listItem(number: let number, children: let children, isRtl: _):
            if let number = number {
                result += " \(number). "
            }
            fallthrough
        case .block(hasMargin: _, children: let children, isRtl: _):
            fallthrough
        case .list(items: let children, isRtl: _):
            fallthrough
        case .blockquote(children: let children, isRtl: _):
            result += " " + stripFormattingFromBlocks(children)
        }
    }
    
    return result
}

func getOnlyAtMentions(htmlString: String, defaultFont: UIFont) -> AttributedString? {
    let document: Document
    do {
        document = try SwiftSoup.parseBodyFragment(htmlString)
    } catch {
        print("Error parsing HTML: \(error)")
        return nil
    }
    
    return getOnlyAtMentions(element: document.body()!, defaultFont: defaultFont)
}

func getOnlyAtMentions(element: Element, defaultFont: UIFont) -> AttributedString? {
    let blocks = convertHTMLToBlocks(element: element, defaultFont: defaultFont)
    let textBlocks = getOnlyText(fromBlocks: blocks)
    
    let allMentions = textBlocks.flatMap { str in
        str.distinctRanges {
            run in run.isMention == true
        }.map { range in
            var result = AttributedString(String(str[range].characters))
            result.link = str[range].link
            return result
        }
    }
    
    if allMentions.count == 0 {
        return nil
    } else {
        return allMentions.reduce(into: AttributedString()) { partialResult, str in
            if partialResult.characters.count > 0 {
                partialResult += " "
            }
            
            partialResult += str
        }
    }
}

fileprivate func getOnlyText(fromBlocks blocks: [ParsedHTMLNode]) -> [AttributedString] {
    var result: [AttributedString] = []
    
    for block in blocks {
        switch block {
        case .text(let text, _):
            result.append(text)
        case .block(_, let children, _):
            fallthrough
        case .listItem(_, let children, _):
            fallthrough
        case .list(let children, _):
            fallthrough
        case .blockquote(let children, _):
            result.append(contentsOf: getOnlyText(fromBlocks: children))
        }
    }
    
    return result
}

func convertHTMLToBlocks(element: Element, defaultFont: UIFont) -> [ParsedHTMLNode] {
    return convertHTMLToBlocks(element: element, parentAttributes: [], defaultFont: defaultFont) ?? []
}

indirect enum ParsedHTMLNode {
    case text(text: AttributedString, isRtl: Bool? = nil)
    case block(hasMargin: Bool, children: [ParsedHTMLNode], isRtl: Bool = false)
    case listItem(number: Int?, children: [ParsedHTMLNode], isRtl: Bool = false)
    case list(items: [ParsedHTMLNode], isRtl: Bool = false)
    case blockquote(children: [ParsedHTMLNode], isRtl: Bool = false)
}

fileprivate func convertHTMLToBlocks(
    element: Element,
    parentAttributes: [CustomAttributes],
    defaultFont: UIFont
) -> [ParsedHTMLNode]? {
    if element.hasClass("invisible") {
        return nil
    }
    
    let tagName = element.tagName()
    
    if tagName == "br" {
        return [.text(text: AttributedString("\n", customAttributes: parentAttributes, defaultFont: defaultFont))]
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
            updatedAttributes.append(.link(to: href, isMention: element.hasClass("mention")))
        }
    default: break
    }
    
    var convertedChildren: [ParsedHTMLNode] = []
    
    for childNode in element.getChildNodes() {
        guard !(childNode is Comment || childNode is DocumentType) else {
            continue
        }
        
        if let childNode = childNode as? TextNode {
            let text = keepNewlines
                ? childNode.getWholeText()
                : (childNode.text().replacingOccurrences(of: "\n", with: ""))
            
            let attrsContainMentionLink = updatedAttributes.contains { attr in
                if case .link(_, let isMention) = attr {
                    return isMention
                }
                
                return false
            }
            
            convertedChildren.append(.text(
                text: AttributedString(
                    text,
                    customAttributes: updatedAttributes,
                    defaultFont: defaultFont
                ),
                isRtl: attrsContainMentionLink ? nil : text.guessIfRtl()
            ))
        } else if let childElement = childNode as? Element {
            convertedChildren.append(contentsOf: convertHTMLToBlocks(element: childElement, parentAttributes: updatedAttributes, defaultFont: defaultFont) ?? [])
        }
    }
    
    // unify adjacent text nodes
    convertedChildren = convertedChildren.reduce(into: []) { result, child in
        guard result.count >= 1 else {
            result.append(child)
            return
        }
        
        if case .text(text: let newText, isRtl: let newIsRtl) = child {
            if case .text(text: let prevText, isRtl: let prevIsRtl) = result.last {
                result.remove(at: result.count - 1)
                result.append(ParsedHTMLNode.text(text: prevText + newText, isRtl: prevIsRtl ?? newIsRtl))
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
            case .text(text: let text, isRtl: let isRtl):
                return .text(text: text.trimmingSpacesAtStartEndAndAroundNewlines(), isRtl: isRtl)
            default:
                return child
            }
        }
        
        // remove text nodes that are entirely whitespace?
        convertedChildren = convertedChildren.filter {
            child in
            switch child {
            case .text(text: let text, isRtl: _):
                return !text.characters.isEmpty
            default:
                return true
            }
        }
    }
    
    let allChildrenAreRtl = convertedChildren.reduce(into: nil as Bool?) { result, child in
        switch child {
        case .text(text: _, isRtl: let isRtl):
            if let isRtl = isRtl {
                result = (result ?? true) && isRtl
            }
        case .block(hasMargin: _, children: _, isRtl: let isRtl):
            fallthrough
        case .listItem(number: _, children: _, isRtl: let isRtl):
            fallthrough
        case .list(items: _, isRtl: let isRtl):
            fallthrough
        case .blockquote(children: _, isRtl: let isRtl):
            result = (result ?? true) && isRtl
        }
    } ?? false
    
    switch tagName {
    case "li":
        return [.listItem(number: nil, children: convertedChildren, isRtl: allChildrenAreRtl)]
    case "ul":
        return [.list(items: convertedChildren, isRtl: allChildrenAreRtl)]
    case "ol":
        var listItemCounter = 1
        for (idx, child) in convertedChildren.enumerated() {
            if case .listItem(number: _, children: let children, isRtl: _) = child {
                convertedChildren[idx] = .listItem(number: listItemCounter, children: children)
                listItemCounter += 1
            }
        }
        return [.list(items: convertedChildren, isRtl: allChildrenAreRtl)]
    case "blockquote":
        return [.blockquote(children: convertedChildren, isRtl: allChildrenAreRtl)]
    default:
        break
    }
    
    if BLOCK_DISPLAY_TAGS.firstIndex(of: tagName) != nil {
        return [.block(hasMargin: tagName.starts(with: "h"), children: convertedChildren, isRtl: allChildrenAreRtl)]
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
    case link(to: String, isMention: Bool = false)
}

fileprivate let BLOCK_DISPLAY_TAGS = ["p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "pre"]

fileprivate extension AttributedString {
    init(_ string: String, customAttributes: [CustomAttributes], defaultFont: UIFont) {
        self.init(string)
        
        
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
                self.underlineStyle = .single
            
            case .strikethrough:
                self.strikethroughStyle = .single
                
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
                
            case .link(to: let href, isMention: let isMention):
                if let url = URL(string: href) {
                    self.link = url
                } else {
                    print("Could not parse URL: \(href)")
                }
                
                if isMention {
                    self.isMention = true
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
        self.baselineOffset = baselineOffset
        
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
        
        self.font = font
    }
}

enum IsMentionAttribute : AttributedStringKey {
    typealias Value = Bool
    static let name = "isMention"
}

struct IsMentionStyleAttributes : AttributeScope {
    let isMention: IsMentionAttribute
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<IsMentionStyleAttributes, T>) -> T {
        return self[T.self]
    }
}
