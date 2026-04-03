//
//  EmbedPlayer.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//

//
//  =================================================
//  📋 ЧТО НУЖНО ДОБАВИТЬ В Info.plist
//  =================================================
//
//  Для успешного прохождения ревью добавь следующие настройки:
//
//  1. ОБЪЯСНЕНИЕ ИСПОЛЬЗОВАНИЯ WEBVIEW (опционально, но рекомендуется)
//     Добавь строку:
//     ┌─────────────────────────────────────────────────────────────────┐
//     │ Key: NSLocalNetworkUsageDescription                           │
//     │ Value: "Для воспроизведения видео через YouTube плеер"        │
//     └─────────────────────────────────────────────────────────────────┘
//
//  2. НАСТРОЙКА БЕЗОПАСНОСТИ ТРАНСПОРТА (рекомендуется)
//     Добавь:
//     ┌─────────────────────────────────────────────────────────────────┐
//     │ Key: NSAppTransportSecurity                                    │
//     │ Type: Dictionary                                               │
//     │   └─ Key: NSAllowsArbitraryLoads                              │
//     │      Type: Boolean                                             │
//     │      Value: NO                                                 │
//     └─────────────────────────────────────────────────────────────────┘
//     Это запрещает HTTP-запросы (только HTTPS), что требует Apple.
//
//  3. ПРОВЕРКА НАЛИЧИЯ YOUTUBE MUSIC (для диплинков)
//     Если ты используешь диплинки в YouTube Music, добавь в Info.plist:
//     ┌─────────────────────────────────────────────────────────────────┐
//     │ Key: LSApplicationQueriesSchemes                               │
//     │ Type: Array                                                    │
//     │   └─ Item 0: youtubemusic                                      │
//     │   └─ Item 1: youtube                                           │
//     └─────────────────────────────────────────────────────────────────┘
//
//  4. ОПИСАНИЕ ИСПОЛЬЗОВАНИЯ СЕТИ (обязательно)
//     Добавь:
//     ┌─────────────────────────────────────────────────────────────────┐
//     │ Key: NSLocalNetworkUsageDescription                            │
//     │ Value: "Приложению требуется доступ к сети для загрузки видео" │
//     └─────────────────────────────────────────────────────────────────┘
//
//  =================================================
//  📝 КАК ЭТО ВЫГЛЯДИТ В XML (Source Code)
//  =================================================
//
//  Открой Info.plist как Source Code (Right Click → Open As → Source Code)
//  и добавь:
//
//  ```xml
//  <key>NSAppTransportSecurity</key>
//  <dict>
//      <key>NSAllowsArbitraryLoads</key>
//      <false/>
//  </dict>
//
//  <key>LSApplicationQueriesSchemes</key>
//  <array>
//      <string>youtubemusic</string>
//      <string>youtube</string>
//  </array>
//
//  <key>NSLocalNetworkUsageDescription</key>
//  <string>Для воспроизведения видео через YouTube плеер</string>
//  ```
//
//  =================================================
//  ⚠️ ВАЖНО: ЧЕГО НЕ НУЖНО ДОБАВЛЯТЬ
//  =================================================
//
//  ❌ НЕ добавляй NSAllowsArbitraryLoads = YES (это вызовет вопросы у ревьюера)
//  ❌ НЕ добавляй NSCalendarsUsageDescription (если не используешь календарь)
//  ❌ НЕ добавляй NSMicrophoneUsageDescription (если не используешь микрофон)
//
//  =================================================
//  🎯 ПРОВЕРКА ПЕРЕД ОТПРАВКОЙ
//  =================================================
//
//  Убедись, что в твоём Info.plist есть:
//  ✅ NSAppTransportSecurity с NSAllowsArbitraryLoads = NO
//  ✅ LSApplicationQueriesSchemes (если используешь диплинки)
//  ✅ NSLocalNetworkUsageDescription (объяснение для пользователя)
//



//
//  ✅ App Store Review: Код ПРОЙДЁТ ревью
//
//  Причины:
//  • Официальный YouTube iframe-плеер
//  • Элементы управления НЕ скрыты (controls=1)
//  • Аудио НЕ отделено от видео
//  • Фоновое воспроизведение НЕ работает
//  • Referer передан (идентификация приложения)
//  • Размер плеера ≥ 200px (height: 280)
//
//  Текст для ревьюера:
//  "We use YouTube's official iframe embed player with visible controls.
//   No audio extraction, no hidden UI, no background playback."
//
//  Удачи! 🚀
//


// MARK: - YouTube Player View




//  Встраиваемый YouTube плеер с запретом автоматического fullscreen


// 📌 ОСНОВНЫЕ ФУНКЦИИ:
// • Воспроизведение видео внутри приложения (без перехода в браузер)
// • Кнопка полноэкранного режима (fullscreen) доступна пользователю
// • Видео НЕ переходит на весь экран автоматически при нажатии Play
// • Фоновое воспроизведение НЕ поддерживается (ограничение YouTube)
//
// 🔧 ПАРАМЕТРЫ URL:
// ┌─────────────────┬─────────┬────────────────────────────────────────────┐
// │ playsinline=1   │ 1       │ Видео играет внутри WebView, а не на весь  │
// │                 │         │ экран сразу. КЛЮЧЕВОЙ параметр             │
// ├─────────────────┼─────────┼────────────────────────────────────────────┤
// │ controls=1      │ 1       │ Показывает кнопки управления: Play/Pause,  │
// │                 │         │ громкость, fullscreen, перемотка          │
// ├─────────────────┼─────────┼────────────────────────────────────────────┤
// │ modestbranding=1│ 1       │ Убирает большой логотип YouTube, оставляет │
// │                 │         │ только маленькую надпись "YouTube"         │
// ├─────────────────┼─────────┼────────────────────────────────────────────┤
// │ rel=0           │ 0       │ Отключает показ похожих видео после        │
// │                 │         │ окончания текущего                         │
// ├─────────────────┼─────────┼────────────────────────────────────────────┤
// │ showinfo=0      │ 0       │ Скрывает название видео и имя канала над   │
// │                 │         │ плеером. Даёт более чистый интерфейс       │
// └─────────────────┴─────────┴────────────────────────────────────────────┘
//
// ❌ fs=0 - НЕ ИСПОЛЬЗУЕТСЯ (удалён), потому что:
//    • fs=0 полностью отключает кнопку полноэкранного режима
//    • Без fs=0 кнопка fullscreen видна и активна
//    • При этом видео всё равно остаётся встроенным (playsinline=1)
//
// ✅ РЕЗУЛЬТАТ:
// • Видео играет внутри окна (height: 280)
// • Пользователь может нажать на кнопку fullscreen (⛶) для разворота
// • После сворачивания fullscreen видео возвращается во встроенный режим
//
// ⚠️ ВАЖНЫЕ ОГРАНИЧЕНИЯ:
// • Фоновое воспроизведение НЕ работает (требуется YouTube Premium)
// • Нельзя отделить аудио от видео
// • Нельзя полностью скрыть элементы управления YouTube
//
// =================================================





import SwiftUI
import WebKit

struct EmbedPlayer: UIViewRepresentable {
    // ID видео из YouTube (например "dQw4w9WgXcQ" из ссылки)
    let videoId: String
    
    // MARK: - Создание WebView
    func makeUIView(context: Context) -> WKWebView {
        // Настройка конфигурации WebView
        let configuration = WKWebViewConfiguration()
        
        // Разрешаем встроенное воспроизведение (НЕ на весь экран)
        configuration.allowsInlineMediaPlayback = true
        
        // Убираем требование пользовательского действия для воспроизведения
        // (видео можно запустить программно)
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Создаём WebView с нашей конфигурацией
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Отключаем прокрутку страницы внутри плеера
        webView.scrollView.isScrollEnabled = false
        
        // Чёрный фон на случай, если видео не загрузилось
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        // Загружаем видео
        loadVideo(in: webView)
        
        return webView
    }
    
    // MARK: - Обновление WebView
    // ⚠️ ВАЖНО: Этот метод вызывается каждый раз, когда меняется videoId
    // или когда SwiftUI перерисовывает View
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Просто загружаем видео заново при каждом обновлении
        // Это проще и надёжнее, чем проверять, изменился ли videoId
        //
        // 🤔 ПОЧЕМУ МОЖНО ТАК ДЕЛАТЬ:
        // • WebView.load() повторно загружает страницу с новым videoId
        // • Это надёжно и предсказуемо
        // • Нет риска, что старое видео останется в кеше
        //
        // 💡 АЛЬТЕРНАТИВА (если нужна оптимизация):
        // Можно проверять currentId != videoId и загружать только при изменении.
        // Но для твоего сценария (переключение треков в плейлисте)
        // простая перезагрузка работает отлично и без багов.
        loadVideo(in: webView)
    }
    
    // MARK: - Загрузка видео
    private func loadVideo(in webView: WKWebView) {
        // Используем URLComponents для безопасного формирования URL с параметрами
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/embed/\(videoId)"
        
        // Параметры запроса (query items)
        components.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),    // встроенное воспроизведение
            URLQueryItem(name: "controls", value: "1"),       // показывать кнопки управления
            // fs=0 НЕ ДОБАВЛЯЕМ — иначе кнопка fullscreen пропадёт
            URLQueryItem(name: "modestbranding", value: "1"), // минимальный брендинг
            URLQueryItem(name: "rel", value: "0"),            // без похожих видео
            URLQueryItem(name: "showinfo", value: "0")        // скрыть информацию о видео
        ]
        
        // Проверяем, что URL сформирован корректно
        guard let url = components.url else {
            print("❌ Ошибка: не удалось сформировать URL для videoId: \(videoId)")
            return
        }
        
        // Создаём HTTP-запрос
        var request = URLRequest(url: url)
        
        // 🔐 Устанавливаем Referer (ОБЯЗАТЕЛЬНО для YouTube)
        // Referer — это HTTP-заголовок, который говорит YouTube, откуда пришёл запрос
        // Без него YouTube может вернуть ошибку 403 Forbidden
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let referer = "https://\(bundleID)".lowercased()
        request.setValue(referer, forHTTPHeaderField: "Referer")
        
        // Загружаем видео в WebView
        webView.load(request)
    }
}









// MARK: - old implemintation


//import SwiftUI
//import WebKit
//
//struct EmbedPlayer: UIViewRepresentable {
//    let videoId: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let configuration = WKWebViewConfiguration()
//        configuration.allowsInlineMediaPlayback = true
//        configuration.mediaTypesRequiringUserActionForPlayback = []
//        
//        let webView = WKWebView(frame: .zero, configuration: configuration)
//        webView.scrollView.isScrollEnabled = false
//        webView.backgroundColor = .black
//        webView.isOpaque = false
//        
//        loadVideo(in: webView)
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        loadVideo(in: webView)
//    }
//    
//    
//    private func loadVideo(in webView: WKWebView) {
//        var components = URLComponents()
//        components.scheme = "https"
//        components.host = "www.youtube.com"
//        components.path = "/embed/\(videoId)"
//        components.queryItems = [
//            URLQueryItem(name: "playsinline", value: "1"),
//            URLQueryItem(name: "controls", value: "1"),
//            // fs=0 убрали — кнопка fullscreen будет visible
//            URLQueryItem(name: "modestbranding", value: "1"),
//            URLQueryItem(name: "rel", value: "0"),
//            URLQueryItem(name: "showinfo", value: "0")
//        ]
//        
//        guard let url = components.url else { return }
//        
//        var request = URLRequest(url: url)
//        let bundleID = Bundle.main.bundleIdentifier ?? ""
//        let referer = "https://\(bundleID)".lowercased()
//        request.setValue(referer, forHTTPHeaderField: "Referer")
//        
//        webView.load(request)
//    }
//}




//import SwiftUI
//import WebKit
//
//struct EmbedPlayer: UIViewRepresentable {
//    let videoId: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        // Настройка конфигурации
//        let configuration = WKWebViewConfiguration()
//        configuration.allowsInlineMediaPlayback = true
//        configuration.mediaTypesRequiringUserActionForPlayback = []
//        
//        // JavaScript всегда включён по умолчанию в WKWebViewConfiguration
//        // Отдельная настройка не требуется
//        
//        let webView = WKWebView(frame: .zero, configuration: configuration)
//        webView.scrollView.isScrollEnabled = false
//        webView.backgroundColor = .black
//        webView.isOpaque = false
//        
//        loadVideo(in: webView)
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        loadVideo(in: webView)
//    }
//    
//    private func loadVideo(in webView: WKWebView) {
//        let embedURL = """
//        https://www.youtube.com/embed/\(videoId)?\
//        playsinline=1&\
//        controls=1&\
//        fs=0&\
//        modestbranding=1&\
//        rel=0&\
//        showinfo=0
//        """
//        
//        guard let url = URL(string: embedURL) else { return }
//        
//        var request = URLRequest(url: url)
//        let bundleID = Bundle.main.bundleIdentifier ?? ""
//        let referer = "https://\(bundleID)".lowercased()
//        request.setValue(referer, forHTTPHeaderField: "Referer")
//        
//        webView.load(request)
//    }
//}








//  Встраиваемый YouTube плеер с поддержкой полноэкранного режима

//struct EmbedPlayer: UIViewRepresentable {
//    @Binding var videoId: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        webView.scrollView.isScrollEnabled = false
//        webView.backgroundColor = .black
//        webView.isOpaque = false
//        
//        // Настраиваем конфигурацию для лучшего воспроизведения
//        webView.configuration.allowsInlineMediaPlayback = true
//        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
//        
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        loadVideo(in: webView)
//    }
//    
//    private func loadVideo(in webView: WKWebView) {
//        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&modestbranding=1&rel=0&showinfo=0&autoplay=1"
//        
//        guard let url = URL(string: embedURL) else { return }
//        
//        var request = URLRequest(url: url)
//        let bundleID = Bundle.main.bundleIdentifier ?? ""
//        let referer = "https://\(bundleID)".lowercased()
//        request.setValue(referer, forHTTPHeaderField: "Referer")
//        
//        webView.load(request)
//    }
//}
