//
//  ImageOrRectangle.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import SwiftUI

enum ImageOrData {
    case image(UIImage?)
    case data(Data?)
    
    func getUiImage() -> UIImage? {
        switch self {
        case .image(let u):
            return u
        case .data(let d):
            if let d = d {
                return UIImage(data: d)
            } else {
                return nil
            }
        }
    }
}

struct ImageOrRectangle: View {
    let image: ImageOrData?
    let fallbackColor: Color
    let fallbackIcon: (name: String, color: UIColor, size: CGFloat)?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        if let uiImage = image?.getUiImage() {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
        } else {
            ZStack {
                Rectangle()
                    .foregroundStyle(fallbackColor)
                    .frame(width: width, height: height)
                if let (name, color, size) = fallbackIcon {
                    let config = UIImage.SymbolConfiguration(pointSize: size).applying(UIImage.SymbolConfiguration(paletteColors: [color]))
                    if let image = UIImage(systemName: name, withConfiguration: config) {
                        Image(uiImage: image)
                    }
                }
            }
        }
    }
    
    func cornerRadius(_ radius: CGFloat) -> some View {
        modifier(CornerRadiusModifier(radius))
    }
}

struct CornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    
    init(_ radius: CGFloat) {
        self.radius = radius
    }
    
    func body(content: Content) -> some View {
        content.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
