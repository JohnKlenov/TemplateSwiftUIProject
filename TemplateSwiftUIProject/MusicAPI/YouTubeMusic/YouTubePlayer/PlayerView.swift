//
//  PlayerView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//


//
// MARK: - YouTube Playback Notes (Important)
//
// 1. YouTube НЕ разрешает встраивать все видео в iframe.
//    Это ключевой момент. Многие музыкальные клипы (VEVO, официальные релизы,
//    премьеры, контент с авторскими правами, возрастные ограничения)
//    возвращают ошибку "Video unavailable" или "Error 153" даже в браузере
//    по адресу https://youtube.com/embed/<videoId>.
//
// 2. Если видео НЕ работает в браузере через /embed/, оно НЕ будет работать
//    ни в WKWebView, ни в IFrame Player, ни в кастомном HTML.
//    Это ограничение YouTube, а не ошибка приложения.
//
// 3. Поэтому часть треков проигрывается нормально, а часть — нет.
//    Это ожидаемое поведение, полностью зависящее от владельца контента.
//
// 4. Консольные сообщения вида:
//       "Invalidating grant <invalid NS/CF object> failed"
//       "RBSServiceErrorDomain"
//       "WebKit Media Playback assertion"
//    — это системные предупреждения iOS Simulator.
//    Они НЕ связаны с ошибками YouTube и НЕ влияют на работу плеера.
//
// 5. Лучший подход:
//      - сначала пытаться открыть видео через IFrame Player (WKWebView)
//      - если YouTube возвращает "Video unavailable" / "Error 153"
//        → автоматически переключаться на SafariView
//        (https://youtube.com/watch?v=<videoId>)
//
//    Такой fallback гарантирует, что пользователь сможет посмотреть ЛЮБОЕ видео,
//    даже если YouTube запрещает его встраивание.
//
// 6. Альтернативный вариант — YouTube iOS Player SDK.
//    Он иногда открывает больше видео, чем iframe, но:
//      - SDK устаревший
// - не обходит все ограничения YouTube
// - всё равно требует fallback для запрещённых видео.
//
// 7. Итог:
//    - IFrame Player → для разрешённых видео
//    - SafariView fallback → для запрещённых
//    - Это единственный легальный и стабильный способ интеграции YouTube.
//


//YouTube IFrame Player у нас есть, но он спрятан внутри WKWebView, и ты его просто не увидел глазами, потому что он загружается через HTML‑строку.

//import SwiftUI
//import WebKit
//
//
//struct PlayerView: UIViewRepresentable {
//    let videoId: String
//
//    func makeUIView(context: Context) -> WKWebView {
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
//        config.mediaTypesRequiringUserActionForPlayback = []
//
//        let webView = WKWebView(frame: .zero, configuration: config)
//
//        webView.customUserAgent =
//        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
//
//        let html = """
//        <!DOCTYPE html>
//        <html>
//        <body style="margin:0;background:black;">
//        <iframe
//            id="player"
//            type="text/html"
//            width="100%"
//            height="100%"
//            src="https://www.youtube.com/embed/\(videoId)?enablejsapi=1&playsinline=1&origin=https://localhost"
//            frameborder="0"
//            allow="autoplay; fullscreen"
//            allowfullscreen>
//        </iframe>
//        </body>
//        </html>
//        """
//
//        webView.loadHTMLString(html, baseURL: nil)
//        return webView
//    }
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {}
//}
//
//struct PlayerScreen: View {
//    @Environment(\.dismiss) private var dismiss
//    let videoId: String
//
//    var body: some View {
//        ZStack(alignment: .topLeading) {
//            PlayerView(videoId: videoId)
//                .ignoresSafeArea()
//
//            Button(action: { dismiss() }) {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 32))
//                    .foregroundColor(.white)
//                    .padding()
//            }
//        }
//    }
//}

















//import SwiftUI
//import SafariServices

//struct SafariPlayerView: UIViewControllerRepresentable {
//    let videoId: String
//
//    func makeUIViewController(context: Context) -> SFSafariViewController {
//        let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
//        return SFSafariViewController(url: url)
//    }
//
//    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
//}




import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewControllerRepresentable {
    let videoId: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        
        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&modestbranding=1&rel=0&showinfo=0"
        if let url = URL(string: embedURL) {
            var request = URLRequest(url: url)
            let bundleID = Bundle.main.bundleIdentifier ?? ""
            let referer = "https://\(bundleID)".lowercased()
            request.setValue(referer, forHTTPHeaderField: "Referer")
            webView.load(request)
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}








//import SwiftUI
//import WebKit
//
//struct YouTubePlayerView: UIViewRepresentable {
//    let videoId: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        webView.scrollView.isScrollEnabled = false // Убираем прокрутку
//        
//        // Формируем URL для встроенного плеера (embed)
//        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&modestbranding=1&rel=0&showinfo=0"
//        
//        if let url = URL(string: embedURL) {
//            var request = URLRequest(url: url)
//            
//            // Устанавливаем Referer (обязательно для YouTube)
//            let bundleID = Bundle.main.bundleIdentifier ?? ""
//            let referer = "https://\(bundleID)".lowercased()
//            request.setValue(referer, forHTTPHeaderField: "Referer")
//            
//            webView.load(request)
//        }
//        
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {}
//}
//
//// Использование:
//struct PlayerView: View {
//    let videoId: String
//    
//    var body: some View {
//        YouTubePlayerView(videoId: videoId)
//            .frame(height: 300) // Задай нужный размер
//    }
//}
























//import SwiftUI
//
//struct PlayerScreen: View {
//    @Environment(\.dismiss) private var dismiss
//
//    let videoId: String
//    let title: String
//    let artist: String
//
//    var body: some View {
//        ZStack {
//            // MARK: - Safari Player (основной и единственный)
//            VStack(spacing: 0) {
//                SafariWrappedPlayerView(videoId: videoId)
//                    .frame(width: 300, height: 400, alignment: .center)
////                    .frame(maxWidth: .infinity)
////                    .aspectRatio(16/9, contentMode: .fit)
////                    .background(Color.black)
////                    .clipped()
//
//                Spacer()
//            }
//            .ignoresSafeArea()
//
//            // MARK: - UI Overlay
//            VStack {
//                topBar
//                    .padding(.top, 20)
//
//                Spacer()
//
//                trackInfo
//
//                Spacer()
//
//                addButton
//                    .padding(.bottom, 40)
//            }
//            .padding(.horizontal, 24)
//        }
//        .background(Color.black)
//    }
//}
//
//private extension PlayerScreen {
//    var topBar: some View {
//        HStack {
//            Button(action: { dismiss() }) {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 32))
//                    .foregroundColor(.white)
//            }
//            Spacer()
//        }
//    }
//}
//
//private extension PlayerScreen {
//    var trackInfo: some View {
//        VStack(spacing: 6) {
//            Text(title)
//                .font(.title2.bold())
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//
//            Text(artist)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//        }
//    }
//}
//
//private extension PlayerScreen {
//    var addButton: some View {
//        Button(action: {
//            // TODO: добавить в корзину / плейлист
//        }) {
//            Image(systemName: "plus.circle.fill")
//                .font(.system(size: 48))
//                .foregroundColor(.white)
//        }
//    }
//}
//
//import SwiftUI
//import SafariServices
//
//struct SafariWrappedPlayerView: UIViewControllerRepresentable {
//    let videoId: String
//
//    func makeUIViewController(context: Context) -> SFSafariViewController {
//        let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
//        let vc = SFSafariViewController(url: url)
//        vc.preferredBarTintColor = .black
//        vc.preferredControlTintColor = .white
//        vc.dismissButtonStyle = .close
//        return vc
//    }
//
//    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
//}
//



//
//import Foundation
//import WebKit
//
//final class PlayerController: ObservableObject {
//    fileprivate weak var webView: WKWebView?
//
//    func attach(webView: WKWebView) {
//        self.webView = webView
//    }
//
//    func play() {
//        webView?.evaluateJavaScript("swiftPlay();", completionHandler: nil)
//    }
//
//    func pause() {
//        webView?.evaluateJavaScript("player && player.pauseVideo();", completionHandler: nil)
//    }
//}
//
//
//
//
//
//import SwiftUI
//
//struct PlayerScreen: View {
//    @Environment(\.dismiss) private var dismiss
//
//    let videoId: String
//    let title: String
//    let artist: String
//
//    @State private var useSafariFallback = false
//    @State private var isPlaying = false
//
//    @StateObject private var playerController = PlayerController()
//
//    var body: some View {
//        ZStack {
//            VStack(spacing: 0) {
//                VideoContainerView(
//                    videoId: videoId,
//                    useSafariFallback: $useSafariFallback,
//                    controller: playerController
//                )
//                .frame(maxWidth: .infinity)
//                .aspectRatio(16/9, contentMode: .fit)
//                .background(Color.black)
//
//                Spacer()
//            }
//            .ignoresSafeArea()
//
//            VStack {
//                topBar
//                Spacer()
//                trackInfo
//                Spacer()
//                controls
//                progressBar
//                    .padding(.bottom, 40)
//            }
//            .padding(.horizontal, 24)
//        }
//        .background(Color.black)
//    }
//}
//
//// MARK: - Top Bar
//private extension PlayerScreen {
//    var topBar: some View {
//        HStack {
//            Button(action: { dismiss() }) {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 32))
//                    .foregroundColor(.white)
//            }
//            Spacer()
//        }
//        .padding(.top, 20)
//    }
//}
//
//// MARK: - Track Info
//private extension PlayerScreen {
//    var trackInfo: some View {
//        VStack(spacing: 6) {
//            Text(title)
//                .font(.title2.bold())
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//
//            Text(artist)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//        }
//    }
//}
//
//// MARK: - Controls
//private extension PlayerScreen {
//    var controls: some View {
//        HStack(spacing: 40) {
//
//            Button(action: {}) {
//                Image(systemName: "backward.fill")
//                    .font(.system(size: 28))
//                    .foregroundColor(.white.opacity(useSafariFallback ? 0.3 : 1))
//            }
//            .disabled(useSafariFallback)
//
//            Button(action: {
//                if useSafariFallback { return }
//                isPlaying.toggle()
//                if isPlaying {
//                    playerController.play()
//                } else {
//                    playerController.pause()
//                }
//            }) {
//                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                    .font(.system(size: 60))
//                    .foregroundColor(.white.opacity(useSafariFallback ? 0.3 : 1))
//            }
//            .disabled(useSafariFallback)
//
//            Button(action: {}) {
//                Image(systemName: "forward.fill")
//                    .font(.system(size: 28))
//                    .foregroundColor(.white.opacity(useSafariFallback ? 0.3 : 1))
//            }
//            .disabled(useSafariFallback)
//
//            Button(action: {}) {
//                Image(systemName: "plus.circle.fill")
//                    .font(.system(size: 28))
//                    .foregroundColor(.white)
//            }
//        }
//        .padding(.bottom, 20)
//    }
//}
//
//// MARK: - Progress Bar
//private extension PlayerScreen {
//    var progressBar: some View {
//        VStack(spacing: 4) {
//            Slider(value: .constant(0))
//                .disabled(true)
//                .opacity(useSafariFallback ? 0.3 : 1)
//
//            HStack {
//                Text("0:00")
//                Spacer()
//                Text("0:00")
//            }
//            .font(.caption)
//            .foregroundColor(.gray.opacity(useSafariFallback ? 0.3 : 1))
//        }
//    }
//}
//
//
//
//import SwiftUI
//import WebKit
//
//struct VideoContainerView: View {
//    let videoId: String
//    @Binding var useSafariFallback: Bool
//    let controller: PlayerController
//
//    @State private var embedCheckCompleted = false
//
//    var body: some View {
//        ZStack {
//            if embedCheckCompleted {
//                if useSafariFallback {
//                    SafariWrappedPlayerView(videoId: videoId)
//                } else {
//                    CustomPlayerView(videoId: videoId, controller: controller)
//                }
//            } else {
//                Color.black
//                    .onAppear {
//                        checkEmbedAvailability()
//                    }
//            }
//        }
//    }
//
//    private func checkEmbedAvailability() {
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
//
//        let webView = WKWebView(frame: .zero, configuration: config)
//
//        let html = """
//        <!DOCTYPE html>
//        <html>
//        <body style="margin:0;background:black;">
//        <iframe
//            id="player"
//            width="100%"
//            height="100%"
//            src="https://www.youtube.com/embed/\(videoId)?playsinline=1&enablejsapi=1"
//            frameborder="0"
//            allow="autoplay; fullscreen"
//            allowfullscreen>
//        </iframe>
//        </body>
//        </html>
//        """
//
//        webView.loadHTMLString(html, baseURL: nil)
//
//        webView.navigationDelegate = WebViewDelegate { text in
//            DispatchQueue.main.async {
//                if text.contains("Video unavailable")
//                    || text.contains("Watch on YouTube")
//                    || text.contains("Error 153")
//                    || text.contains("Ошибка") {
//
//                    self.useSafariFallback = true
//                } else {
//                    self.useSafariFallback = false
//                }
//
//                self.embedCheckCompleted = true
//            }
//        }
//    }
//}
//
//final class WebViewDelegate: NSObject, WKNavigationDelegate {
//    let onFinish: (String) -> Void
//
//    init(onFinish: @escaping (String) -> Void) {
//        self.onFinish = onFinish
//    }
//
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        webView.evaluateJavaScript("document.body.innerText") { result, _ in
//            let text = result as? String ?? ""
//            self.onFinish(text)
//        }
//    }
//}
//
//
//import SwiftUI
//import WebKit
//
//struct CustomPlayerView: UIViewRepresentable {
//    let videoId: String
//    let controller: PlayerController
//
//    func makeUIView(context: Context) -> WKWebView {
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
//        config.mediaTypesRequiringUserActionForPlayback = []
//
//        let webView = WKWebView(frame: .zero, configuration: config)
//        webView.scrollView.isScrollEnabled = false
//        webView.backgroundColor = .black
//        webView.isOpaque = false
//
//        webView.customUserAgent =
//        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
//
//        controller.attach(webView: webView)
//
//        let html = """
//        <!DOCTYPE html>
//        <html>
//        <head>
//        <style>
//            html, body {
//                margin: 0;
//                padding: 0;
//                background-color: black;
//                overflow: hidden;
//                height: 100%;
//                width: 100%;
//            }
//            #player {
//                position: absolute;
//                top: 0;
//                left: 0;
//                width: 100%;
//                height: 100%;
//            }
//        </style>
//        <script src="https://www.youtube.com/iframe_api"></script>
//        <script>
//            var player;
//
//            function onYouTubeIframeAPIReady() {
//                setupPlayer();
//            }
//
//            function setupPlayer() {
//                if (typeof YT === 'undefined' || typeof YT.Player === 'undefined') {
//                    setTimeout(setupPlayer, 200);
//                    return;
//                }
//                player = new YT.Player('player', {
//                    videoId: '\(videoId)',
//                    playerVars: {
//                        'playsinline': 1,
//                        'autoplay': 0,
//                        'controls': 1
//                    }
//                });
//            }
//
//            function swiftPlay() {
//                if (player && player.playVideo) {
//                    player.playVideo();
//                } else {
//                    // если плеер ещё не готов — подождём и попробуем снова
//                    setTimeout(swiftPlay, 200);
//                }
//            }
//        </script>
//        </head>
//        <body>
//            <div id="player"></div>
//        </body>
//        </html>
//        """
//
//        webView.loadHTMLString(html, baseURL: nil)
//        return webView
//    }
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {}
//}
//
//
//
//import SwiftUI
//import SafariServices
//
//struct SafariWrappedPlayerView: UIViewControllerRepresentable {
//    let videoId: String
//
//    func makeUIViewController(context: Context) -> SFSafariViewController {
//        let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
//        let safariVC = SFSafariViewController(url: url)
//        safariVC.preferredBarTintColor = .black
//        safariVC.preferredControlTintColor = .white
//        safariVC.dismissButtonStyle = .close
//        return safariVC
//    }
//
//    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
//}

