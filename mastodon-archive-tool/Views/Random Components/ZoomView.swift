//
//  ZoomView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 01.09.24.
//

import SwiftUI

struct ZoomView<Content>: UIViewRepresentable where Content: View {
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let content: Content
    
    init(minZoom: CGFloat, maxZoom: CGFloat, @ViewBuilder content: () -> Content) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let uiScrollView = UIScrollView()
        uiScrollView.delegate = context.coordinator
        uiScrollView.minimumZoomScale = minZoom
        uiScrollView.maximumZoomScale = maxZoom
        uiScrollView.bouncesZoom = true
        
        if let hostedView = context.coordinator.hostingController.view {
            hostedView.translatesAutoresizingMaskIntoConstraints = true
            hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostedView.frame = uiScrollView.bounds
            uiScrollView.addSubview(hostedView)
        }
        
        return uiScrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
        uiView.minimumZoomScale = minZoom
        uiView.maximumZoomScale = maxZoom
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: content))
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
