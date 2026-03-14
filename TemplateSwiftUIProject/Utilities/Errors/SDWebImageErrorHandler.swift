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
