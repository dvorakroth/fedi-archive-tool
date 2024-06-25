//
//  ImageOrRectangle.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 25.06.24.
//

import SwiftUI

struct ImageOrRectangle: View {
    let image: Data?
    let fallbackColor: Color
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        if let image = image, let uiImage = UIImage(data: image) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else {
            Rectangle()
                .foregroundStyle(fallbackColor)
                .frame(width: width, height: height)
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
