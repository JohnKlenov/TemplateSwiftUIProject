//
//  SDWebImageErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 11.04.25.
//


 
// MARK: - Какие ошибки могут прийти в WebImage.onFailure

// В .onFailure SDWebImage передаёт только два типа ошибок:
//
// ---------------------------------------------------------
// 1) NSURLErrorDomain — сетевые ошибки URLSession
// ---------------------------------------------------------
// Эти ошибки приходят напрямую из URLSession и означают,
// что проблема возникла на уровне сети, DNS, SSL или URL.
//
// • NSURLErrorBadURL (-1000)
//   → URL некорректный, пустой, содержит пробелы или запрещённые символы.
//
// • NSURLErrorUnsupportedURL (-1002)
//   → Используется неподдерживаемая схема (например, ftp:// или file://).
//
// • NSURLErrorCannotFindHost (-1003)
//   → Домен не существует или не может быть разрешён.
//
// • NSURLErrorCannotConnectToHost (-1004)
//   → Сервер существует, но не принимает соединение (порт закрыт, сервер упал).
//
// • NSURLErrorDNSLookupFailed (-1006)
//   → DNS не смог разрешить доменное имя.
//
// • NSURLErrorHTTPTooManyRedirects (-1007)
//   → Сервер зациклился на редиректах (бесконечный redirect loop).
//
// • NSURLErrorSecureConnectionFailed (-1200)
//   → Ошибка SSL/TLS (неверный сертификат, устаревший протокол, MITM).
//
// • NSURLErrorTimedOut (-1001)
//   → Сервер слишком долго не отвечает (временная ошибка).
//
// • NSURLErrorNetworkConnectionLost (-1005)
//   → Соединение оборвалось во время загрузки (временная ошибка).
//
// • NSURLErrorNotConnectedToInternet (-1009)
//   → Устройство офлайн (временная ошибка).
//
// ---------------------------------------------------------
// 2) SDWebImageErrorDomain — ошибки SDWebImage
// ---------------------------------------------------------
// Эти ошибки генерируются самим SDWebImage, когда проблема
// не в сети, а в данных, MIME‑типе или статус‑коде.
//
// • .invalidURL
//   → URL nil, пустой или не может быть интерпретирован как корректный URL.
//
// • .badImageData
//   → Данные загружены, но не являются изображением (битые данные, неверный формат).
//
// • .invalidDownloadStatusCode
//   → Сервер вернул ошибку HTTP (например, 404, 500, 403).
//
// • .invalidDownloadResponse
//   → Некорректный HTTP‑ответ (нет заголовков, нет Content-Length и т.п.).
//
// • .invalidDownloadContentType
//   → MIME‑тип не image/* (например, text/html вместо картинки).
//
// • .invalidDownloadOperation
//   → SDWebImage не смог создать операцию загрузки (внутренняя ошибка).
//
// • .cacheNotModified
//   → Сервер вернул 304 Not Modified (не ошибка, просто пропускаем).
//
// • .cancelled
//   → Загрузка отменена (обычно при скролле коллекции).
//
// • .blackListed
//   → URL попал в blacklist SDWebImage (например, слишком много ошибок подряд).
//
// ---------------------------------------------------------
// 3) Любой другой домен (редко)
// ---------------------------------------------------------
// Если приходит ошибка из неизвестного домена:
// • это всегда ERROR (не warning)
// • это означает непредусмотренный сценарий
// • такие ошибки обязательно логируются
//
// Пример:
// • CocoaErrorDomain
// • NSPOSIXErrorDomain
// • kCFErrorDomainCFNetwork
// (SDWebImage обычно их оборачивает, но если не обернул — это важно)
// 
// ---------------------------------------------------------
// Итог:
// • Логируем только реальные ошибки (critical + unexpected)
// • Временные сетевые ошибки НЕ логируем
// • Неизвестные ошибки ВСЕГДА логируем как .error





/*
 MARK: - Почему некоторые ошибки НЕ критические и могут исправиться сами

 В SDWebImage и URLSession есть группа ошибок, которые НЕ считаются критическими,
 потому что они возникают из-за временных условий сети или поведения загрузчика.
 После таких ошибок загрузка изображения может успешно повториться автоматически.

 ---------------------------------------------------------
 1) Временные сетевые ошибки (NSURLErrorDomain)
 ---------------------------------------------------------

 • NSURLErrorTimedOut
   → Сервер долго не отвечал. Это временная перегрузка или слабый интернет.
     Повторный запрос часто проходит успешно.

 • NSURLErrorNetworkConnectionLost
   → Соединение оборвалось (обычно при переключении Wi‑Fi/LTE или слабом сигнале).
     При следующем запросе сеть может быть стабильной.

 • NSURLErrorNotConnectedToInternet
   → Устройство временно офлайн. Пользователь может включить интернет,
     выйти из метро, восстановить Wi‑Fi — и загрузка продолжится.

 Эти ошибки НЕ говорят о проблеме в приложении — это состояние сети пользователя.
 SDWebImage автоматически повторит загрузку при следующем появлении view.

 ---------------------------------------------------------
 2) Некритические ошибки SDWebImage (SDWebImageErrorDomain)
 ---------------------------------------------------------

 • .cancelled
   → Загрузка отменена, потому что view ушёл с экрана (обычно при скролле).
     Это нормальное поведение. При повторном появлении view загрузка возобновится.

 • .cacheNotModified
   → Сервер вернул 304 Not Modified. Это НЕ ошибка — картинка уже есть в кеше.

 • .invalidDownloadOperation
   → SDWebImage не смог создать операцию из-за отмены или гонки запросов.
     Следующая операция создастся успешно.

 • .invalidDownloadResponse
   → Сервер прислал неполный или временно некорректный ответ.
     CDN или сервер могут вернуть корректный ответ при следующем запросе.

 • .invalidDownloadContentType
   → Сервер временно вернул неправильный MIME‑тип (например, text/html).
     При повторном запросе CDN может вернуть правильный image/jpeg.

 ---------------------------------------------------------
 Итог:
 ---------------------------------------------------------
 • Эти ошибки НЕ являются багами приложения.
 • Они возникают естественно при работе сети и скролле.
 • Они могут исчезнуть сами при повторной загрузке.
 • Поэтому их НЕ нужно логировать как критические.
 */






import Foundation
import SDWebImage
import SDWebImageSwiftUI

protocol SDWebImageErrorHandlerProtocol {
    func handleError(_ error: NSError, for url: URL?, context: String)
}

final class SDWebImageErrorHandler: SDWebImageErrorHandlerProtocol {

    // MARK: - Singleton (боевой, не тестовый)
    static let shared = SDWebImageErrorHandler()

    // MARK: - Dependencies
    private let logger: ErrorLoggingServiceProtocol

    // MARK: - Init
    /// Основной боевой инициализатор
    private init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
        self.logger = logger
    }

    // MARK: - Public API

    func handleError(_ error: NSError, for url: URL?, context: String) {
        switch error.domain {

        case NSURLErrorDomain:
            handleURLError(error, for: url, context: context)

        case SDWebImageErrorDomain:
            handleSDWebImageError(error, for: url, context: context)

        default:
            logError(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleError_unhandledDomain.rawValue)",
                params: ["domain": error.domain]
            )
        }
    }

    // MARK: - URL Errors

    private func handleURLError(_ error: NSError, for url: URL?, context: String) {
        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL

        switch error.code {

        // Критические URL-ошибки
        case NSURLErrorBadURL,
             NSURLErrorUnsupportedURL,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorHTTPTooManyRedirects,
             NSURLErrorSecureConnectionFailed:

            logCritical(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_critical.rawValue)",
                params: ["url": failingURL?.absoluteString ?? "nil"]
            )

        // Временные — не логируем
        case NSURLErrorTimedOut,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet:
            break

        // Остальные — unexpected
        default:
            logError(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_unexpected.rawValue)",
                params: ["code": error.code]
            )
        }
    }

    // MARK: - SDWebImage Errors

    private func handleSDWebImageError(_ error: NSError, for url: URL?, context: String) {
        guard let code = SDWebImageError.Code(rawValue: error.code) else {
            logError(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCode.rawValue)",
                params: ["code": error.code]
            )
            return
        }

        switch code {

        // Критические ошибки SDWebImage
        case .invalidURL, .badImageData, .invalidDownloadStatusCode, .blackListed:
            logCritical(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_critical.rawValue)",
                params: ["url": url?.absoluteString ?? "nil"]
            )

        // Временные — пропускаем
        case .cancelled,
             .cacheNotModified,
             .invalidDownloadOperation,
             .invalidDownloadResponse,
             .invalidDownloadContentType:
            break

        // Неизвестные — это ошибка → логируем
        @unknown default:
            logError(
                error: error,
                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCase.rawValue)",
                params: ["case": "unknown"]
            )
        }
    }

    // MARK: - Logging

    private func logCritical(
        error: Error,
        context: String,
        params: [String: Any]? = nil
    ) {
        logError(error: error, context: context, params: params)
    }

    private func logError(
        error: Error,
        context: String,
        params: [String: Any]? = nil
    ) {
        #if DEBUG
        print("❗️ [DEBUG] Error: \(context)")
        print("❗️ Error:", error.localizedDescription)
        print("❗️ Error code:", error)
        if let params = params { print("❗️ Params:", params) }
        #else
        let nsError = error as NSError

        var merged = ["context": context]
        if let params = params { merged.merge(params) { $1 } }

        logger.logError(
            error,
            domain: nsError.domain,
            source: context,
            message: nil,
            params: merged,
            severity: .error
        )
        #endif
    }
}



// MARK: - before   SDWebImageErrorHandler.shared.handleError(error as NSError, for: url, context: context)

//import Foundation
//import SDWebImage
//import SDWebImageSwiftUI
//
//protocol SDWebImageErrorHandlerProtocol {
//    func handleError(_ error: NSError, for url: URL?, context: String)
//}
//
//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//
//    private let logger: ErrorLoggingServiceProtocol
//
//    init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.logger = logger
//    }
//
//    func handleError(_ error: NSError, for url: URL?, context: String) {
//        switch error.domain {
//
//        case NSURLErrorDomain:
//            handleURLError(error, for: url, context: context)
//
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(error, for: url, context: context)
//
//        default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleError_unhandledDomain.rawValue)",
//                params: ["domain": error.domain]
//            )
//        }
//    }
//
//    // MARK: - URL Errors
//
//    private func handleURLError(_ error: NSError, for url: URL?, context: String) {
//        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//
//        switch error.code {
//
//        // Критические URL-ошибки
//        case NSURLErrorBadURL,
//             NSURLErrorUnsupportedURL,
//             NSURLErrorCannotFindHost,
//             NSURLErrorCannotConnectToHost,
//             NSURLErrorDNSLookupFailed,
//             NSURLErrorHTTPTooManyRedirects,
//             NSURLErrorSecureConnectionFailed:
//
//            logCritical(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_critical.rawValue)",
//                params: ["url": failingURL?.absoluteString ?? "nil"]
//            )
//
//        // Временные — не логируем
//        case NSURLErrorTimedOut,
//             NSURLErrorNetworkConnectionLost,
//             NSURLErrorNotConnectedToInternet:
//            break
//
//        // Остальные — unexpected
//        default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_unexpected.rawValue)",
//                params: ["code": error.code]
//            )
//        }
//    }
//
//    // MARK: - SDWebImage Errors
//
//    private func handleSDWebImageError(_ error: NSError, for url: URL?, context: String) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCode.rawValue)",
//                params: ["code": error.code]
//            )
//            return
//        }
//
//        switch code {
//
//        // Критические ошибки SDWebImage
//        case .invalidURL, .badImageData, .invalidDownloadStatusCode, .blackListed:
//            logCritical(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_critical.rawValue)",
//                params: ["url": url?.absoluteString ?? "nil"]
//            )
//
//        // Временные — пропускаем
//        case .cancelled,
//             .cacheNotModified,
//             .invalidDownloadOperation,
//             .invalidDownloadResponse,
//             .invalidDownloadContentType:
//            break
//
//        // Неизвестные — это ошибка → логируем
//        @unknown default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCase.rawValue)",
//                params: ["case": "unknown"]
//            )
//        }
//    }
//
//    // MARK: - Logging
//
//    private func logCritical(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        logError(error: error, context: context, params: params)
//    }
//
//    private func logError(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        #if DEBUG
//        print("❗️ [DEBUG] Error: \(context)")
//        print("❗️ Error:", error.localizedDescription)
//        if let params = params { print("❗️ Params:", params) }
//        #else
//        let nsError = error as NSError
//
//        var merged = ["context": context]
//        if let params = params { merged.merge(params) { $1 } }
//
//        logger.logError(
//            error,
//            domain: nsError.domain,
//            source: context,
//            message: nil,
//            params: merged,
//            severity: .error
//        )
//        #endif
//    }
//}


// MARK: - before let context: String

//import Foundation
//import SDWebImage
//import SDWebImageSwiftUI
//
//protocol SDWebImageErrorHandlerProtocol {
//    func handleError(_ error: NSError, for url: URL?)
//}
//
//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//
//    private let logger: ErrorLoggingServiceProtocol
//
//    init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.logger = logger
//    }
//
//    func handleError(_ error: NSError, for url: URL?) {
//        switch error.domain {
//        case NSURLErrorDomain:
//            handleURLError(error, for: url)
//
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(error, for: url)
//
//        default:
//            logError(
//                error: error,
//                context: "SDWebImage: Unhandled error domain",
//                params: ["domain": error.domain]
//            )
//        }
//    }
//
//    // MARK: - URL Errors
//
//    private func handleURLError(_ error: NSError, for url: URL?) {
//        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//
//        switch error.code {
//
//        // Критические URL-ошибки
//        case NSURLErrorBadURL,
//             NSURLErrorUnsupportedURL,
//             NSURLErrorCannotFindHost,
//             NSURLErrorCannotConnectToHost,
//             NSURLErrorDNSLookupFailed,
//             NSURLErrorHTTPTooManyRedirects,
//             NSURLErrorSecureConnectionFailed:
//
//            logCritical(
//                error: error,
//                context: "SDWebImage: Critical URL error",
//                params: ["url": failingURL?.absoluteString ?? "nil"]
//            )
//
//        // Временные — не логируем
//        case NSURLErrorTimedOut,
//             NSURLErrorNetworkConnectionLost,
//             NSURLErrorNotConnectedToInternet:
//            break
//
//        // Остальные — это ошибки, которые мы не ожидали → логируем как error
//        default:
//            logError(
//                error: error,
//                context: "SDWebImage: Unhandled URL error",
//                params: ["code": error.code]
//            )
//        }
//    }
//
//    // MARK: - SDWebImage Errors
//
//    private func handleSDWebImageError(_ error: NSError, for url: URL?) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logError(
//                error: error,
//                context: "SDWebImage: Unknown SDWebImage error code",
//                params: ["code": error.code]
//            )
//            return
//        }
//
//        switch code {
//
//        // Критические ошибки SDWebImage
//        case .invalidURL, .badImageData, .invalidDownloadStatusCode, .blackListed:
//            logCritical(
//                error: error,
//                context: "SDWebImage: Critical image error",
//                params: ["url": url?.absoluteString ?? "nil"]
//            )
//
//        // Временные — пропускаем
//        case .cancelled,
//             .cacheNotModified,
//             .invalidDownloadOperation,
//             .invalidDownloadResponse,
//             .invalidDownloadContentType:
//            break
//
//        // Неизвестные — это ошибка → логируем
//        @unknown default:
//            logError(
//                error: error,
//                context: "SDWebImage: Unknown error case",
//                params: ["case": "unknown"]
//            )
//        }
//    }
//
//    // MARK: - Logging
//
//    private func logCritical(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        logError(error: error, context: context, params: params)
//    }
//
//    private func logError(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        #if DEBUG
//        print("❗️ [DEBUG] Error: \(context)")
//        print("❗️ Error:", error.localizedDescription)
//        if let params = params { print("❗️ Params:", params) }
//        #else
//        let nsError = error as NSError
//
//        var merged = ["context": context]
//        if let params = params { merged.merge(params) { $1 } }
//
//        logger.logError(
//            error,
//            domain: nsError.domain,
//            source: context,
//            message: nil,
//            params: merged,
//            severity: .error
//        )
//        #endif
//    }
//}



//import Foundation
//import SDWebImage
//
//protocol SDWebImageErrorHandlerProtocol {
//    func handleError(_ error: NSError, for url: URL?, context: String)
//}
//
//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//
//    private let logger: ErrorLoggingServiceProtocol
//
//    init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.logger = logger
//    }
//
//    func handleError(_ error: NSError, for url: URL?, context: String) {
//        switch error.domain {
//
//        case NSURLErrorDomain:
//            handleURLError(error, for: url, context: context)
//
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(error, for: url, context: context)
//
//        default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleError_unhandledDomain.rawValue)",
//                params: ["domain": error.domain]
//            )
//        }
//    }
//
//    // MARK: - URL Errors
//
//    private func handleURLError(_ error: NSError, for url: URL?, context: String) {
//        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//
//        switch error.code {
//
//        // Критические URL-ошибки
//        case NSURLErrorBadURL,
//             NSURLErrorUnsupportedURL,
//             NSURLErrorCannotFindHost,
//             NSURLErrorCannotConnectToHost,
//             NSURLErrorDNSLookupFailed,
//             NSURLErrorHTTPTooManyRedirects,
//             NSURLErrorSecureConnectionFailed:
//
//            logCritical(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_critical.rawValue)",
//                params: ["url": failingURL?.absoluteString ?? "nil"]
//            )
//
//        // Временные — не логируем
//        case NSURLErrorTimedOut,
//             NSURLErrorNetworkConnectionLost,
//             NSURLErrorNotConnectedToInternet:
//            break
//
//        // Остальные — unexpected
//        default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleURLError_unexpected.rawValue)",
//                params: ["code": error.code]
//            )
//        }
//    }
//
//    // MARK: - SDWebImage Errors
//
//    private func handleSDWebImageError(_ error: NSError, for url: URL?, context: String) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCode.rawValue)",
//                params: ["code": error.code]
//            )
//            return
//        }
//
//        switch code {
//
//        // Критические ошибки SDWebImage
//        case .invalidURL, .badImageData, .invalidDownloadStatusCode, .blackListed:
//            logCritical(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_critical.rawValue)",
//                params: ["url": url?.absoluteString ?? "nil"]
//            )
//
//        // Временные — пропускаем
//        case .cancelled,
//             .cacheNotModified,
//             .invalidDownloadOperation,
//             .invalidDownloadResponse,
//             .invalidDownloadContentType:
//            break
//
//        // Неизвестные — это ошибка → логируем
//        @unknown default:
//            logError(
//                error: error,
//                context: "\(context) → \(ErrorContext.SDWebImageErrorHandler_handleSDWebImageError_unknownCase.rawValue)",
//                params: ["case": "unknown"]
//            )
//        }
//    }
//
//    // MARK: - Logging
//
//    private func logCritical(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        logError(error: error, context: context, params: params)
//    }
//
//    private func logError(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        #if DEBUG
//        print("❗️ [DEBUG] Error: \(context)")
//        print("❗️ Error:", error.localizedDescription)
//        if let params = params { print("❗️ Params:", params) }
//        #else
//        let nsError = error as NSError
//
//        var merged = ["context": context]
//        if let params = params { merged.merge(params) { $1 } }
//
//        logger.logError(
//            error,
//            domain: nsError.domain,
//            source: context,
//            message: nil,
//            params: merged,
//            severity: .error
//        )
//        #endif
//    }
//}








// MARK: - before injecting CrashlyticsLoggingService


//import Foundation
//import SDWebImage
//import SDWebImageSwiftUI
//
//protocol SDWebImageErrorHandlerProtocol {
//    func handleError(_ error: NSError, for url: URL?)
//}
//
//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//    
//    func handleError(_ error: NSError, for url: URL?) {
//        switch error.domain {
//        case NSURLErrorDomain:
//            handleURLError(error, for: url)
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(error, for: url)
//        default:
//            logToCrashlytics(
//                message: "Unhandled error domain: \(error.domain)",
//                error: error,
//                metadata: ["domain": error.domain]
//            )
//        }
//    }
//    
//    private func handleURLError(_ error: NSError, for url: URL?) {
//        let urlValue = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//        switch error.code {
//        case NSURLErrorBadURL: // -1000
//            logCriticalError("Malformed URL", error: error, metadata: ["url": urlValue?.absoluteString ?? "nil"])
//        case NSURLErrorUnsupportedURL: // -1002
//            logCriticalError("Unsupported URL scheme", error: error, metadata: ["scheme": urlValue?.scheme ?? "nil"])
//        case NSURLErrorCannotFindHost: // -1003
//            logCriticalError("Host not found", error: error, metadata: ["host": urlValue?.host ?? "nil"])
//        case NSURLErrorCannotConnectToHost: // -1004
//            logCriticalError("Failed to connect to host", error: error, metadata: ["host": urlValue?.host ?? "nil"])
//        case NSURLErrorDNSLookupFailed: // -1006
//            logCriticalError("DNS lookup failed", error: error, metadata: ["host": urlValue?.host ?? "nil"])
//        case NSURLErrorHTTPTooManyRedirects: // -1007
//            logCriticalError("Redirect loop detected", error: error, metadata: ["url": urlValue?.absoluteString ?? "nil"])
//        case NSURLErrorSecureConnectionFailed: // -1200
//            logCriticalError("SSL/TLS handshake failed", error: error, metadata: ["host": urlValue?.host ?? "nil"])
//        case NSURLErrorTimedOut, // -1001
//             NSURLErrorNetworkConnectionLost, // -1005
//             NSURLErrorNotConnectedToInternet: // -1009
//            print("Temporary NSURLError (не логируем)")
//        default:
//            logToCrashlytics(message: "Unhandled URL error", error: error, metadata: ["code": error.code])
//        }
//    }
//    
//    private func handleSDWebImageError(_ error: NSError, for url: URL?) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logToCrashlytics(message: "Unknown SDWebImage error code", error: error, metadata: ["code": error.code])
//            return
//        }
//        switch code {
//        case .invalidURL:
//            logCriticalError("Invalid image URL", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
//        case .badImageData:
//            logCriticalError("Corrupted image data", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
//        case .invalidDownloadStatusCode:
//            if let statusCode = error.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
//                logCriticalError("Server error", error: error, metadata: ["status": statusCode, "url": url?.absoluteString ?? "nil"])
//            }
//        case .blackListed:
//            logCriticalError("URL is blacklisted", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
//        case .cancelled, .cacheNotModified, .invalidDownloadOperation, .invalidDownloadResponse, .invalidDownloadContentType:
//            print("Temporary SDWebImageError (не логируем)")
//        @unknown default:
//            logToCrashlytics(message: "Unhandled SDWebImage error", error: error, metadata: ["case": "unknown"])
//        }
//    }
//    
//    // Простые функции логирования (пример)
//    private func logCriticalError(_ message: String, error: NSError, metadata: [String: Any]) {
//        print("🛑 CRITICAL ERROR: \(message)")
//        print("Error Code:", error.code)
//        print("Error Description:", error.localizedDescription)
//        print("Metadata:", metadata)
//        // Crashlytics Integration
//        //        let keys: [String: Any] = [
//        //            "error_code": error.code,
//        //            "error_domain": error.domain
//        //        ].merging(metadata) { $1 }
//        //
//        //        Crashlytics.crashlytics().log("\(message)\n\(keys)")
//        //        Crashlytics.crashlytics().record(error: error)
//    }
//    
//    private func logToCrashlytics(message: String, error: NSError, metadata: [String: Any]) {
//        print("⚠️ NON-CRITICAL ERROR: \(message)")
//        // Crashlytics.crashlytics().log(message)
//    }
//}



// MARK: - first code

//    // MARK: - Error Handling Core
//    private func handleError(_ error: Error) {
//        let nsError = error as NSError
//        // Обновление состояния нужно выполнить асинхронно
//        DispatchQueue.main.async {
//            self.lastError = "Error: \(nsError.localizedDescription)"
//        }
//
//        switch nsError.domain {
//        case NSURLErrorDomain:
//            handleURLError(nsError)
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(nsError)
//        default:
//            logToCrashlytics(
//                message: "Unhandled error domain: \(nsError.domain)",
//                error: nsError,
//                metadata: ["domain": nsError.domain]
//            )
//        }
//    }
//
//    private func handleURLError(_ error: NSError) {
//        let urlValue = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//        switch error.code {
//        case NSURLErrorBadURL: // -1000
//            logCriticalError(
//                "Malformed URL (invalid syntax)",
//                error: error,
//                metadata: ["url": urlValue?.absoluteString ?? "nil"]
//            )
//        case NSURLErrorUnsupportedURL: // -1002
//            logCriticalError(
//                "Unsupported URL scheme",
//                error: error,
//                metadata: ["scheme": urlValue?.scheme ?? "nil"]
//            )
//        case NSURLErrorCannotFindHost: // -1003
//            logCriticalError(
//                "Host not found",
//                error: error,
//                metadata: ["host": urlValue?.host ?? "nil"]
//            )
//        case NSURLErrorCannotConnectToHost: // -1004
//            logCriticalError(
//                "Failed to connect to host",
//                error: error,
//                metadata: ["host": urlValue?.host ?? "nil"]
//            )
//        case NSURLErrorDNSLookupFailed: // -1006
//            logCriticalError(
//                "DNS lookup failed",
//                error: error,
//                metadata: ["host": urlValue?.host ?? "nil"]
//            )
//        case NSURLErrorHTTPTooManyRedirects: // -1007
//            logCriticalError(
//                "Redirect loop detected",
//                error: error,
//                metadata: ["url": urlValue?.absoluteString ?? "nil"]
//            )
//        case NSURLErrorSecureConnectionFailed: // -1200
//            logCriticalError(
//                "SSL/TLS handshake failed",
//                error: error,
//                metadata: ["host": urlValue?.host ?? "nil"]
//            )
//        case NSURLErrorTimedOut, // -1001
//             NSURLErrorNetworkConnectionLost, // -1005
//             NSURLErrorNotConnectedToInternet: // -1009
//            print("Temporary NSURLError (не логируем)")
//        default:
//            logToCrashlytics(
//                message: "Unhandled URL error (NSURLErrorDomain)",
//                error: error,
//                metadata: ["code": error.code]
//            )
//        }
//    }
//
//    private func handleSDWebImageError(_ error: NSError) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logToCrashlytics(
//                message: "Unknown SDWebImage error code",
//                error: error,
//                metadata: ["code": error.code]
//            )
//            return
//        }
//
//        switch code {
//        case .invalidURL:
//            logCriticalError(
//                "Invalid image URL",
//                error: error,
//                metadata: ["url": url?.absoluteString ?? "nil"]
//            )
//        case .badImageData:
//            logCriticalError(
//                "Corrupted image data",
//                error: error,
//                metadata: ["url": url?.absoluteString ?? "nil"]
//            )
//        case .invalidDownloadStatusCode:
//            if let statusCode = error.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
//                logCriticalError(
//                    "Server responded with error",
//                    error: error,
//                    metadata: [
//                        "status": statusCode,
//                        "url": url?.absoluteString ?? "nil"
//                    ]
//                )
//            }
//        case .blackListed:
//            logCriticalError(
//                "URL is blacklisted",
//                error: error,
//                metadata: ["url": url?.absoluteString ?? "nil"]
//            )
//        case .cancelled,
//             .cacheNotModified,
//             .invalidDownloadOperation,
//             .invalidDownloadResponse,
//             .invalidDownloadContentType:
//            print("Temporary SDWebImageError (не логируем)")
//        @unknown default:
//            logToCrashlytics(
//                message: "Unhandled SDWebImage error",
//                error: error,
//                metadata: ["case": "unknown"]
//            )
//        }
//    }
//
//    // MARK: - Logging System
//    private func logCriticalError(
//        _ message: String,
//        error: NSError,
//        metadata: [String: Any]
//    ) {
//        print("🛑 CRITICAL ERROR: \(message)")
//        print("Error Code:", error.code)
//        print("Error Description:", error.localizedDescription)
//        print("Metadata:", metadata)
//        // Crashlytics Integration
//        //        let keys: [String: Any] = [
//        //            "error_code": error.code,
//        //            "error_domain": error.domain
//        //        ].merging(metadata) { $1 }
//        //
//        //        Crashlytics.crashlytics().log("\(message)\n\(keys)")
//        //        Crashlytics.crashlytics().record(error: error)
//
//    }
//
//    private func logToCrashlytics(
//        message: String,
//        error: NSError,
//        metadata: [String: Any]
//    ) {
//        print("⚠️ NON-CRITICAL ERROR: \(message)")
//        // Crashlytics.crashlytics().log(message)
//    }
