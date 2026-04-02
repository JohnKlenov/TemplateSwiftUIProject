//
//  EmbedPlayer.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//


//  Встраиваемый YouTube плеер с возможностью смены видео

import SwiftUI
import WebKit

// MARK: - YouTube Player View
struct EmbedPlayer: UIViewRepresentable {
    @Binding var videoId: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        // Настраиваем конфигурацию для лучшего воспроизведения
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        loadVideo(in: webView)
    }
    
    private func loadVideo(in webView: WKWebView) {
        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&modestbranding=1&rel=0&showinfo=0&autoplay=1"
        
        guard let url = URL(string: embedURL) else { return }
        
        var request = URLRequest(url: url)
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let referer = "https://\(bundleID)".lowercased()
        request.setValue(referer, forHTTPHeaderField: "Referer")
        
        webView.load(request)
    }
}
