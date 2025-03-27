//
//  WebImageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.02.25.
//


///SDWebImage кеширует изображения как в памяти, так и на диске.
///Кешированные изображения повторно используются, что уменьшает количество сетевых запросов и повышает производительность.
///Поскольку изображения кешируются, при прокрутке назад к тому же элементу запрос сети не будет повторяться.
///При наличии 1000 изображений, если каждое изображение большое, использование памяти может увеличиться. Однако SDWebImage управляет памятью, автоматически очищая наименее использованные изображения при нехватке памяти.
///Большие размеры изображений: Изображения высокого разрешения потребляют больше памяти. Рассмотрите возможность изменения размера изображений на сервере или перед их отображением.

//Настройка кеша SDWebImage
///SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024 // 100 МБ
///SDImageCache.shared.config.maxDiskSize = 500 * 1024 * 1024 // 500 МБ
///Вы можете тонко настроить время истечения кеша, интервалы очистки и т.д.
///Если возможно, обслуживайте меньшие миниатюрные изображения для списков и загружайте полноразмерные изображения на деталях.
///WebImage(url: url, options: [.scaleDownLargeImages]) // Опция для уменьшения больших изображений
///Опция .scaleDownLargeImages: Эта опция уменьшает использование памяти, уменьшая большие изображения, превышающие целевой размер.


// MARK: - Критические ошибки, которые мы логируем


// MARK: - NSURLErrorDomain

///NSURLErrorBadURL (-1000) – битый URL (например, http://example .com)
///NSURLErrorUnsupportedURL (-1002) – неподдерживаемая схема (например, ftp://)
///NSURLErrorCannotFindHost (-1003) – хост не существует
///NSURLErrorCannotConnectToHost (-1004) – фатальная ошибка подключения
///NSURLErrorDNSLookupFailed (-1006) – DNS не может разрешить хост
///NSURLErrorHTTPTooManyRedirects (-1007) – бесконечный редирект (Практически это означает, что при выполнении HTTP-запроса произошёл «бесконечный» цикл перенаправлений, что нарушает нормальное поведение соединения.)
///NSURLErrorSecureConnectionFailed (-1200) – ошибка SSL/TLS (Эта ошибка возникает, когда попытка установить безопасное соединение (через SSL/TLS) завершается неудачей. Ошибка также может возникать, если сервер неправильно настроен для обеспечения HTTPS-соединения, либо если происходит сбой в процессе рукопожатия SSL/TLS.)



// MARK: - SDWebImageErrorDomain

///.invalidURL   Некорректный URL изображения
///.badImageData     Поврежденные данные изображения (JPEG с битыми данными)
/// .invalidDownloadStatusCode    HTTP 404/500 и другие серверные ошибки
///.blackListed    URL в черном списке



// MARK: - Временные ошибки (игнорируем)

///NSURLErrorTimedOut (-1001) – таймаут
///NSURLErrorNetworkConnectionLost (-1005) – соединение прервано
///NSURLErrorNotConnectedToInternet (-1009) – нет интернета

///.cancelled – отмена загрузки (пользовательская или системная)
///.cacheNotModified + .invalidDownloadOperation + .invalidDownloadResponse + .invalidDownloadContentType

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

///https://firebasestorage.googleapis.com/v0/b/templateswiftui.appspot.com/o/Malls%2F998a8459755389.5a2e89a931ef4.jpeg?alt=media&token=b6fc6474-4e60-4205-9da5-d8f80c01cb6b



struct WebImageView: View {
    let url: URL?
    let placeholderColor: Color
    let width: CGFloat
    let height: CGFloat
    let debugMode: Bool = true// Флаг для отладки
    
    @State private var lastError: String?

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
        } placeholder: {
            placeholderColor
                .frame(width: width, height: height)
        }
        .onFailure { error in
            handleError(error)
        }
        .indicator(.progress)
        .transition(.fade(duration: 0.5))
        .frame(width: width, height: height)
        .clipped()
        .overlay(
            Group {
                if debugMode, let error = lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(4)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        )
    }
    
    // MARK: - Error Handling Core
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        lastError = "Error: \(nsError.localizedDescription)"
        
        switch nsError.domain {
        case NSURLErrorDomain:
            handleURLError(nsError)
            
        case SDWebImageErrorDomain:
            handleSDWebImageError(nsError)
            
        default:
            logToCrashlytics(
                message: "Unhandled error domain: \(nsError.domain)",
                error: nsError,
                metadata: ["domain": nsError.domain]
            )
        }
    }
    
    // MARK: - NSURLErrorDomain (Critical Errors)
    private func handleURLError(_ error: NSError) {
        let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        
        switch error.code {
        // Permanent URL Errors
        case NSURLErrorBadURL: // -1000
            logCriticalError(
                "Malformed URL (invalid syntax)",
                error: error,
                metadata: ["url": url?.absoluteString ?? "nil"]
            )
            
        case NSURLErrorUnsupportedURL: // -1002
            logCriticalError(
                "Unsupported URL scheme",
                error: error,
                metadata: ["scheme": url?.scheme ?? "nil"]
            )
            
        case NSURLErrorCannotFindHost: // -1003
            logCriticalError(
                "Host not found",
                error: error,
                metadata: ["host": url?.host ?? "nil"]
            )
            
        case NSURLErrorCannotConnectToHost: // -1004
            logCriticalError(
                "Failed to connect to host",
                error: error,
                metadata: ["host": url?.host ?? "nil"]
            )
            
        case NSURLErrorDNSLookupFailed: // -1006
            logCriticalError(
                "DNS lookup failed",
                error: error,
                metadata: ["host": url?.host ?? "nil"]
            )
            
        case NSURLErrorHTTPTooManyRedirects: // -1007
            logCriticalError(
                "Redirect loop detected",
                error: error,
                metadata: ["url": url?.absoluteString ?? "nil"]
            )
            
        case NSURLErrorSecureConnectionFailed: // -1200
            logCriticalError(
                "SSL/TLS handshake failed",
                error: error,
                metadata: ["host": url?.host ?? "nil"]
            )
            
        // Temporary Errors (не логируем)
        case NSURLErrorTimedOut, // -1001
             NSURLErrorNetworkConnectionLost, // -1005
             NSURLErrorNotConnectedToInternet: // -1009
            break
            
        default:
            logToCrashlytics(
                message: "Unhandled URL error (NSURLErrorDomain)",
                error: error,
                metadata: ["code": error.code]
            )
        }
    }
    
    // MARK: - SDWebImageErrorDomain (Critical Errors)
    private func handleSDWebImageError(_ error: NSError) {
        guard let code = SDWebImageError.Code(rawValue: error.code) else {
            logToCrashlytics(
                message: "Unknown SDWebImage error code",
                error: error,
                metadata: ["code": error.code]
            )
            return
        }
        
        switch code {
        case .invalidURL:
            logCriticalError(
                "Invalid image URL",
                error: error,
                metadata: ["url": url?.absoluteString ?? "nil"]
            )
            
        case .badImageData:
            logCriticalError(
                "Corrupted image data",
                error: error,
                metadata: ["url": url?.absoluteString ?? "nil"]
            )
            
        case .invalidDownloadStatusCode:
            if let statusCode = error.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
                logCriticalError(
                    "Server responded with error",
                    error: error,
                    metadata: [
                        "status": statusCode,
                        "url": url?.absoluteString ?? "nil"
                    ]
                )
            }
            
        case .blackListed:
            logCriticalError(
                "URL is blacklisted",
                error: error,
                metadata: ["url": url?.absoluteString ?? "nil"]
            )
            
        // Temporary Errors (не логируем)
        case .cancelled,
             .cacheNotModified,
             .invalidDownloadOperation,
             .invalidDownloadResponse,
             .invalidDownloadContentType:
            break
            
        @unknown default:
            logToCrashlytics(
                message: "Unhandled SDWebImage error",
                error: error,
                metadata: ["case": "unknown"]
            )
        }
    }
    
    // MARK: - Logging System
    private func logCriticalError(
        _ message: String,
        error: NSError,
        metadata: [String: Any]
    ) {
        print("🛑 CRITICAL ERROR: \(message)")
        print("Error Code:", error.code)
        print("Error Description:", error.localizedDescription)
        print("Metadata:", metadata)
        
        // Crashlytics Integration
        /*
        let keys: [String: Any] = [
            "error_code": error.code,
            "error_domain": error.domain
        ].merging(metadata) { $1 }
        
        Crashlytics.crashlytics().log("\(message)\n\(keys)")
        Crashlytics.crashlytics().record(error: error)
        */
    }
    
    private func logToCrashlytics(
        message: String,
        error: NSError,
        metadata: [String: Any]
    ) {
        print("⚠️ NON-CRITICAL ERROR: \(message)")
        // Crashlytics.crashlytics().log(message)
    }
}





//struct WebImageView: View {
//    let url: URL?
//    let placeholderColor: Color
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        WebImage(url: url) { image in
//            image
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(width: width, height: height)
//                .clipped()
//        } placeholder: {
//            placeholderColor
//                .frame(width: width, height: height)
//        }
//        .onFailure { error in
//            let nsError = error as NSError
//            handleError(nsError: nsError, originalURL: url)
//        }
//        .indicator(.progress)
//        .transition(.fade(duration: 0.5))
//        .frame(width: width, height: height)
//        .clipped()
//    }
//    
//    private func handleError(nsError: NSError, originalURL: URL?) {
//        switch nsError.domain {
//        case NSURLErrorDomain:
//            handleURLError(nsError: nsError)
//            
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(nsError: nsError, originalURL: originalURL)
//            
//        default:
//            print("Unknown error domain: \(nsError.domain)")
//            logToCrashlytics(
//                message: "Unhandled error domain: \(nsError.domain)",
//                error: nsError,
//                url: originalURL
//            )
//        }
//    }
//    
//    // MARK: - URL Error Handling (NSURLErrorDomain)
//    private func handleURLError(nsError: NSError) {
//        switch nsError.code {
//        case -1003: // NSURLErrorCannotFindHost
//            if let brokenURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL {
//                logCriticalError(
//                    message: "Invalid host in URL",
//                    error: nsError,
//                    url: brokenURL
//                )
//            }
//            
//        case -1001, -1004, -1005, -1009, -1011, -1012, -1013, -1014, -1015, -1016, -1017, -1018:
//            print("Temporary network error: \(nsError.localizedDescription)")
//            
//        default:
//            logToCrashlytics(
//                message: "Unhandled URL error",
//                error: nsError,
//                url: nsError.userInfo["NSErrorFailingURLKey"] as? URL
//            )
//        }
//    }
//    
//    // MARK: - SDWebImage Error Handling (SDWebImageErrorDomain)
//    private func handleSDWebImageError(nsError: NSError, originalURL: URL?) {
//        // Используем raw-коды для совместимости с разными версиями SDWebImage
//        switch nsError.code {
//        case 2000: // SDWebImageError.invalidURL (v5.0+)
//            logCriticalError(
//                message: "Invalid image URL",
//                error: nsError,
//                url: originalURL
//            )
//            
//        case 2001: // SDWebImageError.badImageData (v5.0+)
//            logCriticalError(
//                message: "Invalid image data",
//                error: nsError,
//                url: originalURL
//            )
//            
//        case 2003: // SDWebImageError.badServerResponse (v5.0+)
//            if let statusCode = nsError.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
//                logCriticalError(
//                    message: "Server error: HTTP \(statusCode)",
//                    error: nsError,
//                    url: originalURL
//                )
//            }
//            
//        case 2002: // SDWebImageError.cancelled
//            print("Image loading cancelled")
//            
//        case 2004: // SDWebImageError.blackListed
//            logCriticalError(
//                message: "URL blacklisted",
//                error: nsError,
//                url: originalURL
//            )
//            
//        default:
//            if !isTemporarySDError(nsError) {
//                logToCrashlytics(
//                    message: "Unhandled SDWebImage error",
//                    error: nsError,
//                    url: originalURL
//                )
//            }
//        }
//    }
//    
//    // MARK: - Error Filtering
//    private func isTemporarySDError(_ error: NSError) -> Bool {
//        let temporaryCodes = [
//            2002,  // SDWebImageError.cancelled
//            -1000 // Старые версии: SDWebImageErrorBadOperation
//        ]
//        return temporaryCodes.contains(error.code)
//    }
//    
//    // MARK: - Logging
//    private func logCriticalError(message: String, error: NSError, url: URL?) {
//        print("‼️ Critical Error: \(message)")
//        print("URL: \(url?.absoluteString ?? "nil")")
//        print("Error Details: \(error)")
//        
//        // Crashlytics пример:
//        // let keysAndValues = ["URL": url?.absoluteString ?? "nil"]
//        // Crashlytics.crashlytics().setCustomKeysAndValues(keysAndValues)
//        // Crashlytics.crashlytics().record(error: error)
//    }
//    
//    private func logToCrashlytics(message: String, error: NSError, url: URL?) {
//        print("⚠️ Logging Error: \(message)")
//        // Crashlytics.log("\(message)\nURL: \(url?.absoluteString ?? "nil")")
//    }
//}



//
//struct WebImageView: View {
//    let url: URL?
//    let placeholderColor: Color // Теперь передаём цвет вместо Image
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        WebImage(url: url) { image in
//            image
//                .resizable()
//                .aspectRatio(contentMode: .fill) // Заполняет контейнер изображением, сохраняя пропорции
//                .frame(width: width, height: height)
//                .clipped() // Обрезает изображение, чтобы оно не выходило за пределы контейнера
//        } placeholder: {
//            placeholderColor
//                .frame(width: width, height: height)
//        }
//        .onFailure { error in
//            print("Ошибка загрузки изображения: \(error.localizedDescription)")
//            let nsError = error as NSError
//            print("Error domain: \(nsError.domain)")
//                print("Error code: \(nsError.code)")
//                print("User info: \(nsError.userInfo)")
//            
//            if nsError.domain == NSURLErrorDomain {
//                    switch nsError.code {
//                    case -1003: // NSURLErrorCannotFindHost
//                        let brokenURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL
//                        print("🚨 Server host not found. Check URL:", brokenURL?.absoluteString ?? "nil")
//                        
//                        // Логируем в Crashlytics
////                        Crashlytics.log("Invalid host in URL: \(brokenURL?.absoluteString ?? "nil")")
//                        
//                    case -1001, -1009: // Таймаут или нет интернета
//                        print("⚠️ Network issue (timeout/no internet)")
//                        // Не логируем — временная ошибка
//                        
//                    default:
//                        print("🌐 Other URL error:", nsError.localizedDescription)
//                    }
//                } else if nsError.domain == SDWebImageErrorDomain {
//                    print("ошибок SDWebImage...")
////                    switch SDWebImageError(_nsError: nsError) {
//                        
//                    // Обработка ошибок SDWebImage...
//                }
////            // Проверяем, относится ли ошибка к SDWebImage
////            guard nsError.domain == SDWebImageErrorDomain else {
////                print("Non-SD error: \(error.localizedDescription)")
//////                Crashlytics.log("Non-SD error: \(error.localizedDescription)")
////                return
////            }
////            
////            switch nsError.code {
////            case SDWebImageError.invalidURLError.rawValue:
////                print("Invalid URL: \(error.localizedDescription)")
//////                logToCrashlytics(
//////                    error: error,
//////                    message: "Invalid URL: \(url?.absoluteString ?? "nil")"
//////                )
////                
////            case SDWebImageError.invalidImageData.rawValue:
////                print("Invalid image data: \(error.localizedDescription)")
//////                logToCrashlytics(
//////                    error: error,
//////                    message: "Invalid image data: \(url?.absoluteString ?? "nil")"
//////                )
////                
////            case SDWebImageError.badServerResponse.rawValue:
////                if let httpCode = (nsError.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int) {
////                    print("HTTP \(httpCode): \(error.localizedDescription)")
//////                    logToCrashlytics(
//////                        error: error,
//////                        message: "HTTP \(httpCode) at \(url?.absoluteString ?? "")"
//////                    )
////                }
////                
////            default:
////                print("default error - \(error.localizedDescription)")
////                // Игнорируем временные ошибки
//////                if !isTemporaryError(nsError) {
//////                    logToCrashlytics(
//////                        error: error,
//////                        message: "Unhandled SDWebImage error"
//////                    )
//////                }
////            }
//        }
//        .indicator(.progress(style: .circular))
//        .transition(.fade(duration: 0.5)) // Плавное появление
//        .scaledToFill() // Заполнение контейнера
//        .frame(width: width, height: height)
//        .clipped()
//    }
//    
//    private func validatedURL(_ urlString: String?) -> URL? {
//        guard let urlString = urlString,
//              let url = URL(string: urlString),
//              url.host != nil else {
////            Crashlytics.log("Malformed URL: \(urlString ?? "nil")")
//            return nil
//        }
//        return url
//    }
////    // Проверка на временные ошибки
////    private func isTemporaryError(_ error: NSError) -> Bool {
////        return [
////            SDWebImageError.badNetworkError.rawValue,
////            SDWebImageError.cancelled.rawValue
////        ].contains(error.code)
////    }
//    
//    // Универсальный метод логирования
////    private func logToCrashlytics(error: Error, message: String) {
////        Crashlytics.crashlytics().log("\(message)\nError: \(error.localizedDescription)")
////        if let url = url?.absoluteString {
////            Crashlytics.crashlytics().setCustomValue(url, forKey: "failed_image_url")
////        }
////    }
//}






//import SDWebImage

//.onFailure { error in
//    let nsError = error as NSError
//    
//    // Проверяем, относится ли ошибка к SDWebImage
//    guard nsError.domain == SDWebImageErrorDomain else {
//        Crashlytics.log("Non-SD error: \(error.localizedDescription)")
//        return
//    }
//    
//    switch nsError.code {
//    case SDWebImageError.invalidURLError.rawValue:
//        logToCrashlytics(
//            error: error,
//            message: "Invalid URL: \(url?.absoluteString ?? "nil")"
//        )
//        
//    case SDWebImageError.invalidImageData.rawValue:
//        logToCrashlytics(
//            error: error,
//            message: "Invalid image data: \(url?.absoluteString ?? "nil")"
//        )
//        
//    case SDWebImageError.badServerResponse.rawValue:
//        if let httpCode = (nsError.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int) {
//            logToCrashlytics(
//                error: error,
//                message: "HTTP \(httpCode) at \(url?.absoluteString ?? "")"
//            )
//        }
//        
//    default:
//        // Игнорируем временные ошибки
//        if !isTemporaryError(nsError) {
//            logToCrashlytics(
//                error: error,
//                message: "Unhandled SDWebImage error"
//            )
//        }
//    }
//}



//struct WebImageView: View {
//    let url: URL?
//    let placeholder: Image
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        WebImage(url: url) { image in
//            image
//                .resizable()
//                .aspectRatio(contentMode: .fill) //Заполняет контейнер изображением, сохраняя пропорции.
//                .frame(width: width, height: height)
//                .clipped() //Обрезает изображение, чтобы оно не выходило за пределы контейнера.
//        } placeholder: {
//            //                        Color.black
//            //ProfileView() Ваш кастомный плейсхолдер
//            placeholder
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: width, height: height)
//        }
//        .onFailure { error in
//            print("Ошибка загрузки изображения: \(error.localizedDescription)")
//        }
//        .indicator(.progress(style: .automatic))
//        .transition(.fade(duration: 0.5)) // Плавное появление
//        .scaledToFill() // Заполнение контейнера
//        .frame(width: width, height: height)
//        .clipped()
//    }
//}



// MARK: Типы ошибок, которые могут возникнуть: .onFailure

//Ошибка сети (Network Error):
//Пример: Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline."
//Ошибка URL (URL Error):
//Пример: Error Domain=NSURLErrorDomain Code=-1002 "unsupported URL"
//Ошибка сервера (Server Error):
//Пример: Error Domain=NSURLErrorDomain Code=404 "Not Found"
//Ошибка декодирования (Decoding Error):
//Пример: Error Domain=SDWebImageErrorDomain Code=4 "Image data is corrupted"
//Ошибка кеширования (Caching Error):
//Пример: Error Domain=SDWebImageErrorDomain Code=5 "Cannot write image to cache"

//Ошибка сети: Возникает при проблемах с подключением к интернету.
//Ошибка URL: Возникает при недействительном или неподдерживаемом URL.
//Ошибка сервера: Возникает при получении ошибки от сервера (например, 404 Not Found).
//Ошибка декодирования: Возникает при невозможности декодировать изображение.
//Ошибка кеширования: Возникает при проблемах с сохранением или чтением изображений из кеша.


///Вы правы, не все ошибки, возникающие при загрузке и кешировании изображений с помощью WebImage, необходимо логировать в Crashlytics. Crashlytics предназначен для отслеживания критических ошибок и сбоев, которые влияют на стабильность вашего приложения. Логирование всех ошибок может привести к избыточным данным и затруднить анализ действительно важных проблем.
///Рекомендация: Стоит логировать в Crashlytics. Если ваше приложение генерирует недействительные URL, это может указывать на баг в коде или проблему с данными, получаемыми от сервера. Логирование этих ошибок поможет выявить и исправить проблемы.
///Server Error Стоит логировать в Crashlytics, особенно если эти ошибки происходят часто. Это может указывать на проблемы с вашим сервером или API, и важно их отслеживать для быстрого реагирования.
///Decoding Error Стоит логировать в Crashlytics. Такие ошибки могут указывать на поврежденные данные или проблемы с файлами изображений на сервере. Логирование поможет выявить источники проблемы.
///Caching Error Стоит логировать в Crashlytics. Эти ошибки могут влиять на производительность и пользовательский опыт. Они могут указывать на проблемы с доступным дисковым пространством или доступом к файловой системе.
