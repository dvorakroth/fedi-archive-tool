//
//  ConvertHTML.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 29.06.24.
//

import UIKit
import SwiftSoup

func convertHTML(_ htmlString: String/*, keepInvisibles: Bool = false*/) -> AttributedString {
//    let newHtmlString = keepInvisibles ? htmlString : stripInvisibles(fromHtmlString: htmlString)
//    
//    let result: NSAttributedString
//    do {
//        result = try NSAttributedString(
//            data: newHtmlString.data(using: .utf8)!,
//            options: [
//                .documentType: NSAttributedString.DocumentType.html,
//                .characterEncoding: NSNumber(value: NSUTF8StringEncoding)
//            ],
//            documentAttributes: nil
//        )
//    } catch {
//        print("Could not convert updated HTML to NSAtributedString: \(error)")
//        result = NSAttributedString(string: newHtmlString)
//    }
//    
//    return AttributedString(result)
    
    let doc: Document
    do {
        doc = try SwiftSoup.parseBodyFragment(htmlString)
    } catch {
        print("Error parsing HTML: \(error) (Original HTML: \(htmlString)")
        return AttributedString(htmlString)
    }
    
    return convertHTML(element: doc.body()!)
}

//fileprivate func stripInvisibles(fromHtmlString htmlString: String) -> String {
//    let doc: Document
//    do {
//        doc = try SwiftSoup.parseBodyFragment(htmlString)
//    } catch {
//        print("Error parsing HTML: \(error) (Original HTML: \(htmlString)")
//        return htmlString
//    }
//    
//    let invisibles: Elements?
//    do {
//        invisibles = try doc.body()!.getElementsByAttributeValue("class", "invisible")
//    } catch {
//        print("Could not get .invisible from HTML body: \(error)")
//        invisibles = nil
//    }
//
//    if let invisibles = invisibles {
//        for el in invisibles {
//            try? el.remove()
//        }
//    }
//    
//    let newHtmlString: String
//    do {
//        newHtmlString = try doc.body()!.html()
//    } catch {
//        print("Could not get HTML of updated body: \(error)")
//        newHtmlString = htmlString
//    }
//    
//    return newHtmlString
//}

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

fileprivate let BLOCK_DISPLAY_TAGS = ["p", "div", "h1", "h2", "h3", "h4", "h5", "h6"]

fileprivate func convertHTML(
    element: Element,
    parentAttributes: [CustomAttributes] = []
) -> AttributedString {
    if element.hasClass("invisible") {
        return AttributedString()
    }
    
    if element.tagName() == "br" {
        return AttributedString("\n")
    }
    
    var updatedAttributes = parentAttributes
    
    switch element.tagName() {
    case "b", "strong":
        updatedAttributes.append(.bold)
    case "i", "em":
        updatedAttributes.append(.italic)
    case "u", "ins":
        updatedAttributes.append(.underline)
    case "strike", "s", "del":
        updatedAttributes.append(.strikethrough)
    case "code", "pre":
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
    
    var result = AttributedString()
    var previousTagWasBlockDisplay = false
    
    for childNode in element.getChildNodes() {
        guard !(childNode is Comment || childNode is DocumentType) else {
            continue
        }
        
        if previousTagWasBlockDisplay {
            result += AttributedString("\n\n")
            previousTagWasBlockDisplay = false
        }
        
        if let childNode = childNode as? TextNode {
            result += AttributedString(
                childNode.text(),
                attributes: customAttributesToRealAttributes(updatedAttributes)
            )
        } else if let childElement = childNode as? Element {
            result += convertHTML(element: childElement, parentAttributes: updatedAttributes)
            
            if BLOCK_DISPLAY_TAGS.firstIndex(of: childElement.tagName()) != nil {
                previousTagWasBlockDisplay = true
            }
        }
    }
    
    return result
}


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
        
        // TODO blockquote???? idk how i'd do this at all lol
        
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
        requestedSize *= 0.75
        if subOrSuperLevel > 0 {
            baselineOffset += requestedSize * 0.5
        } else {
            baselineOffset -= requestedSize * 0.4
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

