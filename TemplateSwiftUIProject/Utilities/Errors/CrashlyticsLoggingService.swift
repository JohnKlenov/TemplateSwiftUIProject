//
//  CrashlyticsLoggingService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.04.25.
//


// CrashlyticsLoggingService.swift

///Я хочу создать сервис для логирования ошибок в Crashlytics Firebase ! В моем приложении у меня есть различные сущности(ErrorHandlers) которые принимают ошибку, определяют ее домен и возвращают локализированный текст этой ошибки для алерта или же просто в нутри своей логики проводят онализ и при необходимости логируют сообщения для команды разработчиков на Crashlytics Firebase. Дак вот для таких сущностей как ErrorHandlers я хочу создать сервис для логирования ошибок в Crashlytics Firebase и использовать ее в ErrorHandlers как зависимость для передачи logToCrashlytics. Но я хочу что бы в  logToCrashlytics я передавал не только саму ошибку но и все необходимые данные что бы упростить мониторинг ошибки в консоли Crashlytics Firebase для разработчиков а так же чтьо важно передать данные о том откуда пришла эта ошибка от какого ErrorHandlers и от какого домена! вобщем я хочу что бы сделал мне грамотный  сервис для логирования ошибок в Crashlytics Firebase и подошеол к этому ответственно как старший ios developer.   - вот пример моих ErrorHandlers
///логировать мы будем только те ошибки которые являются критичными и нуждаются во вмешательстве команды разработчиков! ну и для пользователя в итоговой реализации SharedErrorHandler мы будем возвращать только те локализованные текста для алертов которые в действительности могут быть полезны и понятны для пользователя а те что не понятны и бесполезны мы будем заменять локализованным текстом типо что то пошло не так попробуй еще! Так же сервис для логирования ошибок в Crashlytics Firebase мы будем использовать и во ViewModel и даже может быть в View так как там тоже могут быть отловлены ошибки которые требуют вмешательства команды разработчиков
///Так же сервис для логирования ошибок в Crashlytics Firebase мы будем использовать и во ViewModel и даже может быть в View так как там тоже могут быть отловлены ошибки которые требуют вмешательства команды разработчиков.

///Пользователь хочет передавать не только саму ошибку, но и дополнительную информацию: домен ошибки, источник (например, конкретный ErrorHandler), и другие метаданные, которые помогут разработчикам быстрее диагностировать проблему. Также важно различать критические и некритические ошибки, чтобы не засорять логи ненужной информацией.

//Рекомендации по улучшению:
///Добавьте обработку ошибок сети с проверкой интернет-соединения
///Реализуйте фильтрацию дубликатов ошибок
///Добавьте трекинг пользовательских сценариев
///Настройте автоматическую отправку логов при старте приложения
///Реализуйте механизм маскирования конфиденциальных данных в логах



//import Foundation
//import FirebaseCrashlytics
//
//protocol ErrorLoggingServiceProtocol {
//    func log(
//        error: Error,
//        domain: String,
//        source: String,
//        message: String?,
//        additionalParams: [String: Any]?,
//        severity: ErrorSeverityLevel
//    )
//    
//    func log(
//        message: String,
//        domain: String,
//        source: String,
//        additionalParams: [String: Any]?,
//        severity: ErrorSeverityLevel
//    )
//}
//
//enum ErrorSeverityLevel: String {
//    case fatal
//    case error
//    case warning
//    case info
//}
//
//final class CrashlyticsLoggingService: ErrorLoggingServiceProtocol {
//    static let shared = CrashlyticsLoggingService()
//    private let crashlytics = Crashlytics.crashlytics()
//    
//    private init() {}
//    
//    func log(
//        error: Error,
//        domain: String,
//        source: String,
//        message: String? = nil,
//        additionalParams: [String: Any]? = nil,
//        severity: ErrorSeverityLevel = .error
//    ) {
//        var userInfo: [String: Any] = [
//            "error_domain": domain,
//            "error_source": source,
//            "severity": severity.rawValue,
//            "underlying_error": error.localizedDescription,
//            "error_code": (error as NSError).code
//        ]
//        
//        if let message = message {
//            userInfo["custom_message"] = message
//        }
//        
//        if let additionalParams = additionalParams {
//            userInfo.merge(additionalParams) { (current, _) in current }
//        }
//        
//        let nsError = NSError(
//            domain: domain,
//            code: (error as NSError).code,
//            userInfo: userInfo
//        )
//        
//        crashlytics.record(error: nsError)
//        logAdditionalInfo(userInfo: userInfo)
//    }
//    
//    func log(
//        message: String,
//        domain: String,
//        source: String,
//        additionalParams: [String: Any]? = nil,
//        severity: ErrorSeverityLevel = .info
//    ) {
//        var logData: [String: Any] = [
//            "log_domain": domain,
//            "log_source": source,
//            "severity": severity.rawValue,
//            "message": message
//        ]
//        
//        if let additionalParams = additionalParams {
//            logData.merge(additionalParams) { (current, _) in current }
//        }
//        
//        logAdditionalInfo(userInfo: logData)
//    }
//    
//    private func logAdditionalInfo(userInfo: [String: Any]) {
//        userInfo.forEach { key, value in
//            crashlytics.setCustomValue(value, forKey: "log_\(key)")
//        }
//        
//        if let message = userInfo["message"] as? String {
//            crashlytics.log(format: "[%@] %@: %@",
//                             userInfo["severity"] as? String ?? "unknown",
//                             userInfo["log_source"] as? String ?? "unknown_source",
//                             message)
//        }
//    }
//}



// MARK: - example integration in view + viewModel



// MARK:  SharedErrorHandler

//class SharedErrorHandler: ErrorHandlerProtocol {
//    private let loggingService: ErrorLoggingServiceProtocol
//    private let RealtimeDatabaseErrorDomain = "com.firebase.database"
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    func handle(error: Error?) -> String {
//        guard let error = error else {
//            return Localized.FirebaseEnternalError.defaultError
//        }
//        
//        let nsError = error as NSError
//        let errorMessage: String
//        
//        if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
//            errorMessage = handleAuthError(authErrorCode)
//            logAuthError(authErrorCode, nsError: nsError)
//        } else if nsError.domain == FirestoreErrorDomain {
//            errorMessage = handleFirestoreError(nsError)
//            logFirestoreError(nsError)
//        } else if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
//            errorMessage = handleStorageError(storageErrorCode)
//            logStorageError(storageErrorCode, nsError: nsError)
//        } else if nsError.domain == RealtimeDatabaseErrorDomain {
//            errorMessage = handleRealtimeDatabaseError(nsError)
//            logRealtimeDatabaseError(nsError)
//        } else if let customError = error as? FirebaseEnternalError {
//            errorMessage = customError.errorDescription ?? Localized.FirebaseEnternalError.defaultError
//            logCustomError(customError)
//        } else {
//            errorMessage = Localized.FirebaseEnternalError.defaultError
//            logUnknownError(nsError)
//        }
//        
//        return errorMessage
//    }
//    
//    private func logAuthError(_ code: AuthErrorCode, nsError: NSError) {
//        let shouldLog = isCriticalAuthError(code)
//        guard shouldLog else { return }
//        
//        loggingService.log(
//            error: nsError,
//            domain: "FirebaseAuth",
//            source: "SharedErrorHandler",
//            message: "Critical Auth Error",
//            additionalParams: ["auth_error_code": code.rawValue],
//            severity: .error
//        )
//    }
//    
//    private func isCriticalAuthError(_ code: AuthErrorCode) -> Bool {
//        switch code {
//        case .invalidCredential,
//             .invalidSender,
//             .invalidRecipientEmail,
//             .keychainError,
//             .internalError,
//             .malformedJWT:
//            return true
//        default:
//            return false
//        }
//    }
//    
//    // Аналогичные методы logFirestoreError, logStorageError и т.д.
//}


// MARK: SDWebImageErrorHandler

//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//    private let loggingService: ErrorLoggingServiceProtocol
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    private func logCriticalError(_ message: String, error: NSError, metadata: [String: Any], url: URL?) {
//        var params: [String: Any] = [
//            "error_code": error.code,
//            "error_domain": error.domain,
//            "url": url?.absoluteString ?? "nil"
//        ]
//        params.merge(metadata) { (current, _) in current }
//        
//        loggingService.log(
//            error: error,
//            domain: "SDWebImage",
//            source: "SDWebImageErrorHandler",
//            message: message,
//            additionalParams: params,
//            severity: .error
//        )
//    }
//}


// MARK: FirestoreGetService

//final class FirestoreGetService {
//    private let db = Firestore.firestore()
//    private let loggingService: ErrorLoggingServiceProtocol
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    func fetchMalls() async throws -> [MallItem] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("MallCenters").getDocuments { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let error = error as NSError? {
//                    self.handleFetchError(error)
//                    continuation.resume(throwing: error)
//                } else {
//                    // Обработка успешного результата
//                }
//            }
//        }
//    }
//    
//    private func handleFetchError(_ error: NSError) {
//        let criticalCodes: [Int] = [
//            FirestoreErrorCode.invalidArgument.rawValue,
//            FirestoreErrorCode.permissionDenied.rawValue,
//            FirestoreErrorCode.resourceExhausted.rawValue,
//            FirestoreErrorCode.failedPrecondition.rawValue,
//            FirestoreErrorCode.unimplemented.rawValue,
//            FirestoreErrorCode.internal.rawValue,
//            FirestoreErrorCode.dataLoss.rawValue,
//            FirestoreErrorCode.unauthenticated.rawValue
//        ]
//        
//        guard criticalCodes.contains(error.code) else { return }
//        
//        loggingService.log(
//            error: error,
//            domain: "Firestore",
//            source: "FirestoreGetService",
//            message: "Critical Firestore Error",
//            additionalParams: [
//                "collection": "MallCenters",
//                "operation": "fetchMalls"
//            ],
//            severity: .error
//        )
//    }
//}
