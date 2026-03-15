//
//  SDWebImageErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 11.04.25.
//



import Foundation
import SDWebImage
import SDWebImageSwiftUI

protocol SDWebImageErrorHandlerProtocol {
    func handleError(_ error: NSError, for url: URL?)
}

final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
    
    func handleError(_ error: NSError, for url: URL?) {
        switch error.domain {
        case NSURLErrorDomain:
            handleURLError(error, for: url)
        case SDWebImageErrorDomain:
            handleSDWebImageError(error, for: url)
        default:
            logToCrashlytics(
                message: "Unhandled error domain: \(error.domain)",
                error: error,
                metadata: ["domain": error.domain]
            )
        }
    }
    
    private func handleURLError(_ error: NSError, for url: URL?) {
        let urlValue = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        switch error.code {
        case NSURLErrorBadURL: // -1000
            logCriticalError("Malformed URL", error: error, metadata: ["url": urlValue?.absoluteString ?? "nil"])
        case NSURLErrorUnsupportedURL: // -1002
            logCriticalError("Unsupported URL scheme", error: error, metadata: ["scheme": urlValue?.scheme ?? "nil"])
        case NSURLErrorCannotFindHost: // -1003
            logCriticalError("Host not found", error: error, metadata: ["host": urlValue?.host ?? "nil"])
        case NSURLErrorCannotConnectToHost: // -1004
            logCriticalError("Failed to connect to host", error: error, metadata: ["host": urlValue?.host ?? "nil"])
        case NSURLErrorDNSLookupFailed: // -1006
            logCriticalError("DNS lookup failed", error: error, metadata: ["host": urlValue?.host ?? "nil"])
        case NSURLErrorHTTPTooManyRedirects: // -1007
            logCriticalError("Redirect loop detected", error: error, metadata: ["url": urlValue?.absoluteString ?? "nil"])
        case NSURLErrorSecureConnectionFailed: // -1200
            logCriticalError("SSL/TLS handshake failed", error: error, metadata: ["host": urlValue?.host ?? "nil"])
        case NSURLErrorTimedOut, // -1001
             NSURLErrorNetworkConnectionLost, // -1005
             NSURLErrorNotConnectedToInternet: // -1009
            print("Temporary NSURLError (не логируем)")
        default:
            logToCrashlytics(message: "Unhandled URL error", error: error, metadata: ["code": error.code])
        }
    }
    
    private func handleSDWebImageError(_ error: NSError, for url: URL?) {
        guard let code = SDWebImageError.Code(rawValue: error.code) else {
            logToCrashlytics(message: "Unknown SDWebImage error code", error: error, metadata: ["code": error.code])
            return
        }
        switch code {
        case .invalidURL:
            logCriticalError("Invalid image URL", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
        case .badImageData:
            logCriticalError("Corrupted image data", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
        case .invalidDownloadStatusCode:
            if let statusCode = error.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
                logCriticalError("Server error", error: error, metadata: ["status": statusCode, "url": url?.absoluteString ?? "nil"])
            }
        case .blackListed:
            logCriticalError("URL is blacklisted", error: error, metadata: ["url": url?.absoluteString ?? "nil"])
        case .cancelled, .cacheNotModified, .invalidDownloadOperation, .invalidDownloadResponse, .invalidDownloadContentType:
            print("Temporary SDWebImageError (не логируем)")
        @unknown default:
            logToCrashlytics(message: "Unhandled SDWebImage error", error: error, metadata: ["case": "unknown"])
        }
    }
    
    // Простые функции логирования (пример)
    private func logCriticalError(_ message: String, error: NSError, metadata: [String: Any]) {
        print("🛑 CRITICAL ERROR: \(message)")
        print("Error Code:", error.code)
        print("Error Description:", error.localizedDescription)
        print("Metadata:", metadata)
        // Crashlytics Integration
        //        let keys: [String: Any] = [
        //            "error_code": error.code,
        //            "error_domain": error.domain
        //        ].merging(metadata) { $1 }
        //
        //        Crashlytics.crashlytics().log("\(message)\n\(keys)")
        //        Crashlytics.crashlytics().record(error: error)
    }
    
    private func logToCrashlytics(message: String, error: NSError, metadata: [String: Any]) {
        print("⚠️ NON-CRITICAL ERROR: \(message)")
        // Crashlytics.crashlytics().log(message)
    }
}








// MARK: - new
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
//        case SDWebImageErrorDomain:
//            handleSDWebImageError(error, for: url)
//        default:
//            logNonCritical(
//                error: error,
//                context: "SDWebImage: Unhandled error domain",
//                params: ["domain": error.domain]
//            )
//        }
//    }
//
//    private func handleURLError(_ error: NSError, for url: URL?) {
//        let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
//
//        switch error.code {
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
//        case NSURLErrorTimedOut,
//             NSURLErrorNetworkConnectionLost,
//             NSURLErrorNotConnectedToInternet:
//            break
//
//        default:
//            logNonCritical(
//                error: error,
//                context: "SDWebImage: Unhandled URL error",
//                params: ["code": error.code]
//            )
//        }
//    }
//
//    private func handleSDWebImageError(_ error: NSError, for url: URL?) {
//        guard let code = SDWebImageError.Code(rawValue: error.code) else {
//            logNonCritical(
//                error: error,
//                context: "SDWebImage: Unknown SDWebImage error code",
//                params: ["code": error.code]
//            )
//            return
//        }
//
//        switch code {
//        case .invalidURL, .badImageData, .invalidDownloadStatusCode, .blackListed:
//            logCritical(
//                error: error,
//                context: "SDWebImage: Critical image error",
//                params: ["url": url?.absoluteString ?? "nil"]
//            )
//
//        case .cancelled, .cacheNotModified, .invalidDownloadOperation, .invalidDownloadResponse, .invalidDownloadContentType:
//            break
//
//        @unknown default:
//            logNonCritical(
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
//        #if DEBUG
//        print("🛑 [DEBUG] Critical error: \(context)")
//        print("🛑 Error:", error.localizedDescription)
//        if let params = params { print("🛑 Params:", params) }
//        #else
//        let nsError = error as NSError
//        var merged = ["context": context, "is_critical": true]
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
//
//    private func logNonCritical(
//        error: Error,
//        context: String,
//        params: [String: Any]? = nil
//    ) {
//        #if DEBUG
//        print("⚠️ [DEBUG] Non-critical error: \(context)")
//        print("⚠️ Error:", error.localizedDescription)
//        if let params = params { print("⚠️ Params:", params) }
//        #else
//        let nsError = error as NSError
//        var merged = ["context": context, "is_critical": false]
//        if let params = params { merged.merge(params) { $1 } }
//
//        logger.logError(
//            error,
//            domain: nsError.domain,
//            source: context,
//            message: nil,
//            params: merged,
//            severity: .warning
//        )
//        #endif
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
