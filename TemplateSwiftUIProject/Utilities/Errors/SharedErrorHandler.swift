//
//  SharedErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.10.24.
//



//
//  ErrorDiagnosticsCenter.swift
//
//  Централизованный обработчик ошибок приложения.
//  Выполняет:
//  • классификацию ошибок,
//  • логирование,
//  • отправку критичных ошибок в Crashlytics,
//  • вывод подробной информации в Debug,
//  • возврат локализованных сообщений пользователю.
//
//  ----------------------------------------------------------------------
//  ВАЖНО: Привязка ошибок к конкретному пользователю
//
//  Если нужно видеть в Crashlytics, какой пользователь получил ошибку,
//  вызываем:
//
//      Crashlytics.crashlytics().setUserID(uid)
//
//  Делать это нужно сразу после успешной авторизации.
//  Тогда все ошибки и краши будут привязаны к конкретному пользователю.
//
//  ----------------------------------------------------------------------
//


/**
 Почему мы НЕ используем:
     if let appError = error as? AppInternalError

 И почему ВСЕГДА восстанавливаем enum через:
     let nsError = error as NSError
     if nsError.domain == AppInternalError.errorDomain,
        let appError = AppInternalError(rawValue: nsError.code)

 ---------------------------------------------------------------
 1. После прохождения через Combine ошибка перестаёт быть enum
 ---------------------------------------------------------------

 Внутри Future ошибка может быть AppInternalError, но при попадании
 в .sink Combine автоматически выполняет bridging:
     Error → NSError

 Поэтому:
     (error as? AppInternalError) == nil

 Это поведение встроено в Combine и не может быть отключено.

 ---------------------------------------------------------------
 2. Firebase, async/await и Foundation тоже делают bridging
 ---------------------------------------------------------------

 Любая ошибка, прошедшая через Firebase SDK, async/await или
 Foundation API, превращается в NSError. Enum теряется.

 ---------------------------------------------------------------
 3. CustomNSError гарантирует domain + code, но НЕ enum
 ---------------------------------------------------------------

 Благодаря CustomNSError каждая AppInternalError‑ошибка превращается в:
     NSError(domain: "com.yourapp.internal", code: rawValue)

 Поэтому enum можно восстановить только так:
     AppInternalError(rawValue: nsError.code)

 ---------------------------------------------------------------
 4. Это единственный надёжный способ получить technicalDescription
 ---------------------------------------------------------------

 В CrashlyticsLoggingService мы должны использовать именно
 восстановление через domain + code, иначе мы потеряем enum
 и не сможем отправить корректное technicalDescription.

 ---------------------------------------------------------------
 5. Итог
 ---------------------------------------------------------------

 • error as? AppInternalError — ненадёжно (enum теряется после bridging)
 • nsError.domain + nsError.code — 100% надёжно
 • AppInternalError(rawValue: code) — всегда восстанавливает enum
 • Crashlytics получает стабильный английский technicalDescription
 • UI получает локализованный текст через LocalizedError
 */



import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage



/// Google Sign-In error codes (iOS SDK)
enum GoogleSignInErrorCode: Int {
    case unknown              = -1   // Неизвестная ошибка
    case keychain             = -2   // Ошибка доступа к Keychain
    case noCurrentUser        = -3   // Нет текущего пользователя
    case hasNoAuthInKeychain  = -4   // Нет сохранённых токенов
    case canceled             = -5   // Пользователь отменил вход
    case emmError             = -6   // Ошибка Enterprise Mobility Management
    case scopesAlreadyGranted = -7   // Запрошенные scope уже предоставлены
    case mismatchWithCurrentUser = -8 // Несоответствие текущему пользователю
}



// MARK: - ErrorDiagnosticsCenter


protocol ErrorDiagnosticsProtocol {
    func handle(error: (any Error)?, context: String?) -> String
}

final class ErrorDiagnosticsCenter: ErrorDiagnosticsProtocol {
    
    private let realtimeDomain = "com.firebase.database"
    private let googleSignInDomain = "com.google.GIDSignIn"
    private let logger: ErrorLoggingServiceProtocol
    
    init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
        self.logger = logger
    }
    
    // MARK: - Основной метод обработки ошибок
    
    func handle(error: (any Error)?, context: String? = nil) -> String {
        print("ErrorDiagnosticsCenter received error: \(String(describing: error?.localizedDescription))")
        
        guard let error = error else {
            return Localized.AppInternalError.defaultError
        }
        
        // 1. Специальные типы до NSError
        
        // Обработка ошибок декодирования (DecodingError)
        // Эти ошибки возникают, когда JSONDecoder или FirestoreDecoder не могут
        // преобразовать входные данные в модель. Основные причины:
        // 1) Несоответствие типов (например, строка вместо числа).
        // 2) Отсутствие обязательных полей в JSON/Firestore документе.
        // 3) Неверные ключи CodingKeys или несовпадение структуры модели и данных.
        // 4) Некорректный формат вложенных объектов.
        // 5) Повреждённые или вручную изменённые данные в Firestore.
        // DecodingError относится только к операциям ДЕКОДИРОВАНИЯ, а не кодирования.
        if let decodingError = error as? DecodingError {
            logCritical(error: error, context: context ?? "DecodingError: \(decodingError)")
            return Localized.AppInternalError.defaultError
        }

        // 1. Обработка ошибок кодирования (EncodingError)
        // Эти ошибки возникают, когда JSONEncoder не может преобразовать модель в Data.
        // Примеры причин:
        // - несериализуемые типы (например, URL без стратегии кодирования)
        // - неверные ключи CodingKeys
        // - попытка закодировать nil в non-optional поле
        if let encodingError = error as? EncodingError {
            logCritical(error: error, context: context ?? "EncodingError: \(encodingError)")
            return Localized.AppInternalError.defaultError
        }
        
        if let pickerError = error as? PhotoPickerError {
            return handlePhotoPickerError(pickerError, context: context)
        }
        
        // 2. Преобразуем в NSError
        
        let nsError = error as NSError
        
#if DEBUG
        print("NSError domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")
#else
        logger.logError(
            error,
            domain: nsError.domain,
            source: context ?? "NSError",
            message: nsError.localizedDescription,
            params: ["nsError_code": nsError.code],
            severity: .warning
        )
#endif
        
        // 3. AppInternalError (Swift enum → NSError или уже NSError)
        
        if nsError.domain == AppInternalError.errorDomain {
            return handleAppInternalError(nsError, context: context)
        }
        
        // 4. Auth
        
        if let authCode = AuthErrorCode(rawValue: nsError.code) {
            return handleAuthError(authCode, error: error, context: context)
        }
        
        // 5. Firestore
        
        if nsError.domain == FirestoreErrorDomain {
            return handleFirestoreError(nsError, error: error, context: context)
        }
        
        // 6. Storage
        
        if let storageCode = StorageErrorCode(rawValue: nsError.code) {
            return handleStorageError(storageCode, error: error, context: context)
        }
        
        // 7. Realtime Database
        
        if nsError.domain == realtimeDomain {
            return handleRealtimeDatabaseError(nsError, error: error, context: context)
        }
        
        // 8. Google Sign-In
        
        if nsError.domain == googleSignInDomain {
            return handleGoogleSignInError(nsError, error: error, context: context)
        }
        
        // 9. Обработка ошибок JSONSerialization (NSCocoaErrorDomain)
        // Эти ошибки возникают при преобразовании Data → JSON через JSONSerialization.
        // Примеры причин:
        // - некорректный JSON (код 3840: invalid JSON)
        // - несоответствие типов
        // - попытка сериализовать невалидную структуру
        if nsError.domain == NSCocoaErrorDomain {
            logCritical(error: error, context: context ?? "NSCocoaErrorDomain: \(nsError.code)")
            return Localized.AppInternalError.defaultError
        }
        // 10. Всё остальное — неизвестное → логируем
        
        logCritical(error: error, context: context ?? "UnknownError")
        return Localized.AppInternalError.defaultError
    }
    
    
    
    // MARK: - AppInternalError Handler
    
    private func handleAppInternalError(_ error: NSError, context: String?) -> String {
        /// не каждая ошибка тут требует logCritical !!!
        logCritical(error: error, context: context ?? "AppInternalError.\(error.code)")
        
        switch error.code {
                
        case AppInternalError.invalidCollectionPath.rawValue:          // Указанный путь недействителен (ожидалась коллекция, а не документ)
            return Localized.AppInternalError.invalidCollectionPath
                
        case AppInternalError.failedDeployOptionalError.rawValue:      // Не удалось обработать необязательную ошибку
            return Localized.AppInternalError.failedDeployOptionalError
                
        case AppInternalError.failedDeployOptionalID.rawValue:         // Не удалось обработать необязательный идентификатор
            return Localized.AppInternalError.failedDeployOptionalID
                
        case AppInternalError.jsonConversionFailed.rawValue:           // Сбой преобразования JSON
            return Localized.AppInternalError.jsonConversionFailed
                
        case AppInternalError.notSignedIn.rawValue:                    // В настоящий момент ни один пользователь не вошёл в систему
            return Localized.AppInternalError.notSignedIn
                
        case AppInternalError.emptyResult.rawValue:                    // Данные не найдены
            return Localized.AppInternalError.emptyResult
                
        case AppInternalError.nilSnapshot.rawValue:                    // Снимок данных отсутствует
            return Localized.AppInternalError.nilSnapshot
                
        case AppInternalError.imageEncodingFailed.rawValue:            // Не удалось обработать изображение
            return Localized.AppInternalError.imageEncodingFailed
                
        case AppInternalError.delayedConfirmation.rawValue:            // Обновление аватара занимает больше времени, чем обычно
            return Localized.AppInternalError.delayedConfirmation
                
        case AppInternalError.staleUserSession.rawValue:               // Текущий пользователь изменился (устаревшая сессия)
            return Localized.AppInternalError.staleUserSession
                
        case AppInternalError.anonymousAuthFailed.rawValue:            // Неизвестная ошибка при анонимной аутентификации
            return Localized.AppInternalError.anonymousAuthError
                
        case AppInternalError.defaultError.rawValue:                   // Общая ошибка Firebase (fallback)
            return Localized.AppInternalError.defaultError
        
        case AppInternalError.entityDeallocated.rawValue:
            return Localized.AppInternalError.entityDeallocated        // Объект был деинициализирован до обработки события. (guard let self)
                
        default:                                                       // Неизвестная внутренняя ошибка приложения
            return Localized.AppInternalError.defaultError
        }
    }


    // MARK: - Критичное логирование (Debug vs Release)
    
    /// В Debug печатаем всё в консоль.
    /// В Release отправляем в Crashlytics через CrashlyticsLoggingService.
    private func logCritical(
        error: Error,
        context: String,
        params: [String: Any]? = nil
    ) {
        #if DEBUG
            print("⚠️ [DEBUG] Critical error context: \(context)")
            print("⚠️ [DEBUG] Error: \(error.localizedDescription)")
            if let params = params {
                print("⚠️ [DEBUG] Params: \(params)")
            }
            print("⚠️ [DEBUG] Stack trace:")
            Thread.callStackSymbols.forEach { print($0) }
        #else
            let nsError = error as NSError

            var mergedParams: [String: Any] = [
                "context": context,
                "is_critical": true
            ]

            // Добавляем дополнительные параметры, если они есть
            if let params = params {
                mergedParams.merge(params) { current, _ in current }
            }

            logger.logError(
                error,
                domain: nsError.domain,
                source: context,
                message: nil,
                params: mergedParams,
                severity: .error
            )
        #endif
    }

    // MARK: - Photo Picker
    
    private func handlePhotoPickerError(_ pickerError: PhotoPickerError, context: String?) -> String {
        switch pickerError {
                
        case .noItemAvailable:
            return Localized.PhotoPickerError.noItemAvailable
            
        case .unsupportedType:
            return Localized.PhotoPickerError.unsupportedType
            
        case .iCloudRequired:
            return Localized.PhotoPickerError.iCloudRequired
            
        case .itemUnavailable:
            logCritical(
                error: pickerError,
                context: context ?? "PhotoPickerError.itemUnavailable"
            )
            return Localized.PhotoPickerError.itemUnavailable
            
        case .loadFailed(let underlyingError):
            logCritical(
                error: pickerError,
                context: context ?? "PhotoPickerError.loadFailed",
                // ⬇️ Зачем нужен params?
                // Мы логируем PhotoPickerError как основную ошибку (чтобы Crashlytics видел domain/code/technicalDescription),
                // но при этом НЕ теряем реальную системную ошибку, которая стала причиной.
                // underlyingError добавляется в params как дополнительная информация,
                // чтобы разработчик видел точную первопричину (например, Cocoa error -1),
                // но группировка ошибок оставалась по PhotoPickerError.
                params: ["underlying_error": underlyingError.localizedDescription]
            )
            return Localized.PhotoPickerError.generalFailure
            
        case .unknown(let underlyingError):
            logCritical(
                error: pickerError,
                context: context ?? "PhotoPickerError.unknown",
                // ⬇️ То же самое: сохраняем underlyingError как контекст,
                // но основной ошибкой остаётся PhotoPickerError.
                params: ["underlying_error": underlyingError.localizedDescription]
            )
            return Localized.PhotoPickerError.generalFailure
        }
    }


    // MARK: - Auth
    
    private func handleAuthError(_ code: AuthErrorCode, error: Error, context: String?) -> String {
        switch code {
            
        case .providerAlreadyLinked:                 // Провайдер (Google/Apple) уже привязан к аккаунту
            return Localized.Auth.providerAlreadyLinked
            
        case .credentialAlreadyInUse:                // Эти credentials уже используются другим аккаунтом
            return Localized.Auth.credentialAlreadyInUse
            
        case .userMismatch:                          // Credentials принадлежат другому пользователю (ошибка reauth)
            return Localized.Auth.userMismatch
            
        case .requiresRecentLogin:                   // Операция требует недавнего входа (смена email/пароля)
            return Localized.Auth.requiresRecentLogin
            
        case .userNotFound:                          // Пользователь с таким email не существует
            return Localized.Auth.userNotFound
            
        case .invalidRecipientEmail:                 // Email получателя недействителен
            return Localized.Auth.invalidRecipientEmail
            
        case .missingEmail:                          // Email отсутствует (например, при регистрации)
            return Localized.Auth.missingEmail
            
        case .accountExistsWithDifferentCredential:  // Аккаунт существует, но с другим провайдером (email vs Google)
            return Localized.Auth.accountExistsWithDifferentCredential
            
            // --- Остальные пользовательские ошибки (не критичные) ---
            
        case .invalidEmail:                          // Неверный формат email
            return Localized.Auth.invalidEmail
            
        case .weakPassword:                          // Пароль слишком слабый
            return Localized.Auth.weakPassword
            
        case .wrongPassword:                         // Неверный пароль
            return Localized.Auth.wrongPassword
            
        case .emailAlreadyInUse:                     // Email уже зарегистрирован
            return Localized.Auth.emailAlreadyInUse
            
        case .tooManyRequests:                       // Слишком много попыток — временная блокировка Firebase
            return Localized.Auth.tooManyRequests
            
        case .networkError:                          // Проблема с интернет‑соединением
            return Localized.Auth.networkError
            
            // --- Всё остальное считаем критичным и логируем ---
            
        default:                                     // Неизвестная/новая ошибка Firebase Auth → критично
            logCritical(error: error, context: context ?? "AuthErrorCode.\(code.rawValue)")
            return Localized.Auth.generic
        }
    }
    
    // MARK: - Firestore
    
    private func handleFirestoreError(_ nsError: NSError, error: Error, context: String?) -> String {
        switch nsError.code {
            
        case FirestoreErrorCode.cancelled.rawValue:          // Операция отменена (клиентом или сервером), не критично
            return Localized.Firestore.cancelled
            
        case FirestoreErrorCode.unavailable.rawValue:        // Firestore временно недоступен (сервер перегружен / проблемы сети)
            return Localized.Firestore.unavailable
            
        case FirestoreErrorCode.deadlineExceeded.rawValue:   // Сервер не успел выполнить операцию (таймаут)
            return Localized.Firestore.deadlineExceeded
            
            // --- Критичные ошибки Firestore (логируем через одну ветку) ---
            
        case FirestoreErrorCode.invalidArgument.rawValue,    // Клиент передал некорректные аргументы
            FirestoreErrorCode.notFound.rawValue,           // Документ/ресурс не найден → ошибка данных
            FirestoreErrorCode.alreadyExists.rawValue,      // Попытка создать ресурс, который уже существует
            FirestoreErrorCode.permissionDenied.rawValue,   // Правила безопасности Firestore запретили операцию
            FirestoreErrorCode.resourceExhausted.rawValue,  // Превышены квоты/лимиты Firestore
            FirestoreErrorCode.failedPrecondition.rawValue, // Нарушено предусловие (неверное состояние документа)
            FirestoreErrorCode.aborted.rawValue,            // Операция прервана (конфликт транзакций)
            FirestoreErrorCode.outOfRange.rawValue,         // Запрошены данные вне допустимого диапазона
            FirestoreErrorCode.unimplemented.rawValue,      // Операция не поддерживается сервером или SDK
            FirestoreErrorCode.internal.rawValue,           // Внутренняя ошибка Firestore (сбой сервера/SDK)
            FirestoreErrorCode.dataLoss.rawValue,           // Потеря или повреждение данных
            FirestoreErrorCode.unauthenticated.rawValue:    // Клиент не аутентифицирован или токен недействителен
            
            logCritical(error: error, context: context ?? "Firestore.\(nsError.code)")
            return Localized.Firestore.generic
            
            // --- Неизвестная ошибка Firestore ---
            
        default:                                             // Новый/неизвестный код Firestore → считаем критичным
            logCritical(error: error, context: context ?? "Firestore.unknown(\(nsError.code))")
            return Localized.Firestore.generic
        }
    }
    
    // MARK: - Storage
    
    private func handleStorageError(_ code: StorageErrorCode, error: Error, context: String?) -> String {
        switch code {
            
        case .cancelled:                     // Операция отменена пользователем или системой (не критично)
            return Localized.Storage.cancelled
            
            // --- Остальные критичные ошибки Storage (логируем через одну ветку) ---
            
        case .unauthenticated,              // Пользователь не авторизован → в нашем приложении быть не может → критично
                .unauthorized,                 // Правила безопасности запретили доступ → ошибка конфигурации/логики
                .downloadSizeExceeded,         // Запрошенный файл превышает лимит → ошибка логики загрузки
                .objectNotFound,               // Файл не найден по указанному пути
                .bucketNotFound,               // Bucket отсутствует (ошибка конфигурации Firebase)
                .projectNotFound,              // Firebase-проект не найден
                .quotaExceeded,                // Превышена квота Storage
                .nonMatchingChecksum,          // Контрольная сумма не совпала → файл повреждён
                .invalidArgument,              // Клиент передал некорректные аргументы
                .unknown,                      // Неизвестная ошибка Storage
                .bucketMismatch,               // Файл в другом bucket, чем указано в конфигурации
                .internalError,                // Внутренняя ошибка Firebase Storage
                .pathError,                    // Неверный путь к файлу
                .retryLimitExceeded:           // Firebase исчерпал количество попыток повторить операцию
            
            logCritical(error: error, context: context ?? "Storage.\(code.rawValue)")
            return Localized.Storage.generic
            
        @unknown default:                   // Новый/неизвестный код Storage → критично
            logCritical(error: error, context: context ?? "Storage.unknown")
            return Localized.Storage.generic
        }
    }
    
    // MARK: - Realtime Database
    
    private func handleRealtimeDatabaseError(_ nsError: NSError, error: Error, context: String?) -> String {
        switch nsError.code {
            
        case NSURLErrorNotConnectedToInternet:          // Нет интернет‑соединения (не критично)
            return Localized.RealtimeDatabase.networkError
            
        case NSURLErrorTimedOut:                        // Сервер не ответил вовремя (таймаут)
            return Localized.RealtimeDatabase.timeout
            
        case NSURLErrorCancelled:                       // Операция отменена пользователем или системой
            return Localized.RealtimeDatabase.operationCancelled
            
            // --- Критичные ошибки Realtime Database (логируем через одну ветку) ---
            
        case NSURLErrorCannotFindHost,                  // Хост Firebase не найден (DNS/конфигурация)
            NSURLErrorCannotConnectToHost,             // Невозможно установить соединение с хостом
            NSURLErrorNetworkConnectionLost,           // Соединение потеряно во время операции
            NSURLErrorResourceUnavailable,             // Ресурс временно недоступен
            NSURLErrorUserCancelledAuthentication,     // Пользователь отменил системную аутентификацию
            NSURLErrorUserAuthenticationRequired:      // Требуется аутентификация (токен недействителен)
            
            logCritical(error: error, context: context ?? "RealtimeDatabase.\(nsError.code)")
            return Localized.RealtimeDatabase.generic
            
            // --- Неизвестная ошибка Realtime Database ---
            
        default:                                        // Новый/неизвестный код → считаем критичным
            logCritical(error: error, context: context ?? "RealtimeDatabase.unknown(\(nsError.code))")
            return Localized.RealtimeDatabase.generic
        }
    }
    
    // MARK: - Google Sign-In
    
    private func handleGoogleSignInError(_ nsError: NSError, error: Error, context: String?) -> String {
        guard let code = GoogleSignInErrorCode(rawValue: nsError.code) else {
            logCritical(error: error, context: context ?? "GoogleSignIn.unknown(\(nsError.code))")
            return Localized.GoogleSignInError.defaultError
        }
        
        switch code {
            
        case .canceled:                                  // Пользователь отменил вход (закрыл окно Google)
            return Localized.GoogleSignInError.cancelled
            
            // --- Критичные ошибки Google Sign‑In (логируем через одну ветку) ---
            
        case .scopesAlreadyGranted,                      // Scopes уже выданы → ошибка логики приложения
                .noCurrentUser,                             // Нет текущего пользователя → сбой состояния SDK
                .unknown,                                   // Неизвестная ошибка Google Sign‑In
                .keychain,                                  // Ошибка Keychain при сохранении/чтении токена
                .hasNoAuthInKeychain,                       // Нет сохранённой авторизации в Keychain
                .emmError,                                  // Корпоративная политика запрещает вход
                .mismatchWithCurrentUser:                   // Пользователь Google не совпадает с ожидаемым
            
            logCritical(error: error, context: context ?? "GoogleSignIn.\(code.rawValue)")
            return Localized.GoogleSignInError.defaultError
        }
    }
}
    






//    private func logCritical(error: Error, context: String) {
//    #if DEBUG
//        print("⚠️ [DEBUG] Critical error context: \(context)")
//        print("⚠️ [DEBUG] Error: \(error.localizedDescription)")
//        print("⚠️ [DEBUG] Stack trace:")
//        Thread.callStackSymbols.forEach { print($0) }
//    #else
//        let nsError = error as NSError
//
//        let params: [String: Any] = [
//            "context": context,
//            "is_critical": true
//        ]
//
//        logger.logError(
//            error,
//            domain: nsError.domain,     // ← сохраняем реальный домен ошибки
//            source: context,
//            message: nil,
//            params: params,
//            severity: .error
//        )
//    #endif
//    }
    


//    private func handlePhotoPickerError(_ pickerError: PhotoPickerError, context: String?) -> String {
//        switch pickerError {
//
//        case .noItemAvailable:
//            return Localized.PhotoPickerError.noItemAvailable
//
//        case .unsupportedType:
//            return Localized.PhotoPickerError.unsupportedType
//
//        case .iCloudRequired:
//            return Localized.PhotoPickerError.iCloudRequired
//
//        case .itemUnavailable:
//            logCritical(
//                error: pickerError,
//                context: (context ?? "PhotoPickerError.itemUnavailable")
//            )
//            return Localized.PhotoPickerError.itemUnavailable
//
//        case .loadFailed(let underlyingError):
//            logCritical(
//                error: underlyingError,
//                context: (context ?? "PhotoPickerError.loadFailed")
//            )
//            return Localized.PhotoPickerError.generalFailure
//
//        case .unknown(let underlyingError):
//            logCritical(
//                error: underlyingError,
//                context: (context ?? "PhotoPickerError.unknown")
//            )
//            return Localized.PhotoPickerError.generalFailure
//        }
//    }

//    private func handlePhotoPickerError(_ pickerError: PhotoPickerError) -> String {
//        switch pickerError {
//        case .noItemAvailable:
//            return Localized.PhotoPickerError.noItemAvailable
//        case .itemUnavailable:
//            return Localized.PhotoPickerError.itemUnavailable
//        case .unsupportedType:
//            return Localized.PhotoPickerError.unsupportedType
//        case .iCloudRequired:
//            return Localized.PhotoPickerError.iCloudRequired
//        case .loadFailed(let underlyingError),
//                .unknown(let underlyingError):
//            return (underlyingError as NSError).localizedDescription
//        }
//    }
    









// MARK: - old implemintation


protocol ErrorHandlerProtocol {
    func handle(error:Error?) -> String
}



class SharedErrorHandler: ErrorHandlerProtocol {
    
    private let RealtimeDatabaseErrorDomain = "com.firebase.database"
    private let GoogleSignInErrorDomain = "com.google.GIDSignIn"
    
    func handle(error: (any Error)?) -> String {
        print("SharedErrorHandler shared error - \(String(describing: error?.localizedDescription))")
        
        guard let error = error else {
            return Localized.FirebaseInternalError.defaultError
        }
        
        // 🔍 Обработка ошибок декодирования до преобразования в NSError
        if let decodingError = error as? DecodingError {
            return handleDecodingError(decodingError)
        }
        
        if let pickerError = error as? PhotoPickerError {
            return handlePhotoPickerError(pickerError)
        }
        
        
        // Преобразуем ошибку в NSError для работы с кодами и доменами
        if let nsError = error as NSError? {
            print("📥 [SharedErrorHandler] Получен NSError: domain=\(nsError.domain), code=\(nsError.code), description=\(nsError.localizedDescription)")
            if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
                return handleAuthError(authErrorCode)
            }
            if nsError.domain == FirestoreErrorDomain {
                return handleFirestoreError(nsError)
            }
            if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
                return handleStorageError(storageErrorCode)
            }
            if nsError.domain == RealtimeDatabaseErrorDomain {
                return handleRealtimeDatabaseError(nsError)
            }
            if nsError.domain == "Anonymous Auth" {
                return Localized.FirebaseInternalError.anonymousAuthError
            }
            if nsError.domain == GoogleSignInErrorDomain {
                return handleGoogleSignInError(nsError)
            }
        }
        
        if let customError = error as? FirebaseInternalError {
            return customError.errorDescription ?? Localized.FirebaseInternalError.defaultError
        }
        
        return Localized.FirebaseInternalError.defaultError
    }
    
    private func handleDecodingError(_ error: DecodingError) -> String {
        var logMessage: String
        
        switch error {
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            logMessage = "DecodingError.typeMismatch: expected type \(type), path: \(path)"
            
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            logMessage = "DecodingError.valueNotFound: type \(type) not found at path: \(path)"
            
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            logMessage = "DecodingError.keyNotFound: missing key '\(key.stringValue)', path: \(path)"
            
        case .dataCorrupted(let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            logMessage = "DecodingError.dataCorrupted: \(context.debugDescription), path: \(path)"
            
        @unknown default:
            logMessage = "DecodingError.unknown"
        }
        
        // Логируем в Crashlytics (или консоль, если не используешь Crashlytics)
        print("SharedErrorHandler ⚠️ Decoding error: \(logMessage)")
        // Crashlytics.crashlytics().log(logMessage)
        
        // Возвращаем пользователю нейтральное сообщение
        return Localized.FirebaseInternalError.defaultError
    }
    
    // Вынесенная реализация для GIDSignIn.sharedInstance.signIn
    private func handleGoogleSignInError(_ nsError: NSError) -> String {
        print("🔍 [GoogleSignInError] domain=\(nsError.domain), code=\(nsError.code), description=\(nsError.localizedDescription)")

        guard nsError.domain == "com.google.GIDSignIn" else {
            return Localized.GoogleSignInError.defaultError
        }

        if let code = GoogleSignInErrorCode(rawValue: nsError.code) {
            switch code {
            case .unknown:
                return Localized.GoogleSignInError.defaultError
            case .keychain:
                return Localized.GoogleSignInError.keychainError
            case .noCurrentUser:
                return Localized.GoogleSignInError.noHandlers
            case .hasNoAuthInKeychain:
                return Localized.GoogleSignInError.noAuthInKeychain
            case .canceled:
                return Localized.GoogleSignInError.cancelled
            case .emmError:
                return Localized.GoogleSignInError.emmError
            case .scopesAlreadyGranted:
                return Localized.GoogleSignInError.scopesAlreadyGranted
            case .mismatchWithCurrentUser:
                return Localized.GoogleSignInError.userMismatch
            }
        }

        return Localized.GoogleSignInError.defaultError
    }


    
    private func handlePhotoPickerError(_ pickerError: PhotoPickerError) -> String {
        switch pickerError {
        case .noItemAvailable:
            return Localized.PhotoPickerError.noItemAvailable
        case .itemUnavailable:
            return Localized.PhotoPickerError.itemUnavailable
        case .unsupportedType:
            return Localized.PhotoPickerError.unsupportedType
        case .iCloudRequired:
            return Localized.PhotoPickerError.iCloudRequired
        case .loadFailed(let underlyingError),
             .unknown(let underlyingError):
            // Возвращаем системное сообщение ошибки «как есть» — оно уже может быть локализовано системой
            return (underlyingError as NSError).localizedDescription
        }
    }


    private func handleAuthError(_ code: AuthErrorCode) -> String {
        switch code {
        case .providerAlreadyLinked:
            return Localized.Auth.providerAlreadyLinked
        case .credentialAlreadyInUse:
            return Localized.Auth.credentialAlreadyInUse
        case .tooManyRequests:
            return Localized.Auth.tooManyRequests
        case .userTokenExpired:
            return Localized.Auth.userTokenExpired
        case .invalidUserToken:
            return Localized.Auth.invalidUserToken
        case .userMismatch:
            return Localized.Auth.userMismatch
        case .requiresRecentLogin:
            return Localized.Auth.requiresRecentLogin
        case .emailAlreadyInUse:
            return Localized.Auth.emailAlreadyInUse
        case .invalidEmail:
            return Localized.Auth.invalidEmail
        case .weakPassword:
            return Localized.Auth.weakPassword
        case .networkError:
            return Localized.Auth.networkError
        case .keychainError:
            return Localized.Auth.keychainError
        case .userNotFound:
            return Localized.Auth.userNotFound
        case .wrongPassword:
            return Localized.Auth.wrongPassword
        case .expiredActionCode:
            return Localized.Auth.expiredActionCode
        case .invalidCredential:
            return Localized.Auth.invalidCredential
        case .invalidRecipientEmail:
            return Localized.Auth.invalidRecipientEmail
        case .missingEmail:
            return Localized.Auth.missingEmail
        case .userDisabled:
            return Localized.Auth.userDisabled
        case .invalidSender:
            return Localized.Auth.invalidSender
        case .accountExistsWithDifferentCredential:
            return Localized.Auth.accountExistsWithDifferentCredential
        case .operationNotAllowed:
            return Localized.Auth.operationNotAllowed
        default:
            return Localized.Auth.generic
        }
    }
    
    private func handleFirestoreError(_ nsError: NSError) -> String {
        switch nsError.code {
        case FirestoreErrorCode.cancelled.rawValue:
            return Localized.Firestore.cancelled
        case FirestoreErrorCode.unavailable.rawValue:
            return Localized.Firestore.unavailable
        case FirestoreErrorCode.invalidArgument.rawValue:
            return Localized.Firestore.invalidArgument
        case FirestoreErrorCode.unknown.rawValue:
            return Localized.Firestore.unknown
        case FirestoreErrorCode.deadlineExceeded.rawValue:
            return Localized.Firestore.deadlineExceeded
        case FirestoreErrorCode.notFound.rawValue:
            return Localized.Firestore.notFound
        case FirestoreErrorCode.alreadyExists.rawValue:
            return Localized.Firestore.alreadyExists
        case FirestoreErrorCode.permissionDenied.rawValue:
            return Localized.Firestore.permissionDenied
        case FirestoreErrorCode.resourceExhausted.rawValue:
            return Localized.Firestore.resourceExhausted
        case FirestoreErrorCode.failedPrecondition.rawValue:
            return Localized.Firestore.failedPrecondition
        case FirestoreErrorCode.aborted.rawValue:
            return Localized.Firestore.aborted
        case FirestoreErrorCode.outOfRange.rawValue:
            return Localized.Firestore.outOfRange
        case FirestoreErrorCode.unimplemented.rawValue:
            return Localized.Firestore.unimplemented
        case FirestoreErrorCode.internal.rawValue:
            return Localized.Firestore.internalError
        case FirestoreErrorCode.dataLoss.rawValue:
            return Localized.Firestore.dataLoss
        case FirestoreErrorCode.unauthenticated.rawValue:
            return Localized.Firestore.unauthenticated
        default:
            return Localized.Firestore.generic
        }
    }
    
    private func handleStorageError(_ code: StorageErrorCode) -> String {
        switch code {
        case .objectNotFound:
            return Localized.Storage.objectNotFound
        case .bucketNotFound:
            return Localized.Storage.bucketNotFound
        case .projectNotFound:
            return Localized.Storage.projectNotFound
        case .quotaExceeded:
            return Localized.Storage.quotaExceeded
        case .unauthenticated:
            return Localized.Storage.unauthenticated
        case .unauthorized:
            return Localized.Storage.unauthorized
        case .retryLimitExceeded:
            return Localized.Storage.retryLimitExceeded
        case .nonMatchingChecksum:
            return Localized.Storage.nonMatchingChecksum
        case .downloadSizeExceeded:
            return Localized.Storage.downloadSizeExceeded
        case .cancelled:
            return Localized.Storage.cancelled
        case .invalidArgument:
            return Localized.Storage.invalidArgument
        case .unknown:
            return Localized.Storage.unknown
        case .bucketMismatch:
            return Localized.Storage.bucketMismatch
        case .internalError:
            return Localized.Storage.internalError
        case .pathError:
            return Localized.Storage.pathError
        @unknown default:
            return Localized.Storage.generic
        }
    }
    
    private func handleRealtimeDatabaseError(_ nsError: NSError) -> String {
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            return Localized.RealtimeDatabase.networkError
        case NSURLErrorTimedOut:
            return Localized.RealtimeDatabase.timeout
        case NSURLErrorCancelled:
            return Localized.RealtimeDatabase.operationCancelled
        case NSURLErrorCannotFindHost:
            return Localized.RealtimeDatabase.hostNotFound
        case NSURLErrorCannotConnectToHost:
            return Localized.RealtimeDatabase.cannotConnectToHost
        case NSURLErrorNetworkConnectionLost:
            return Localized.RealtimeDatabase.networkConnectionLost
        case NSURLErrorResourceUnavailable:
            return Localized.RealtimeDatabase.resourceUnavailable
        case NSURLErrorUserCancelledAuthentication:
            return Localized.RealtimeDatabase.authenticationCancelled
        case NSURLErrorUserAuthenticationRequired:
            return Localized.RealtimeDatabase.authenticationRequired
        default:
            return Localized.RealtimeDatabase.generic
        }
    }
}










// MARK: - before if nsError.domain == AppInternalError.errorDomain


//final class CrashlyticsLoggingService: ErrorLoggingServiceProtocol {
//
//    static let shared = CrashlyticsLoggingService()
//    private let crashlytics = Crashlytics.crashlytics()
//
//    private init() {}
//
//    func logError(
//        _ error: Error,
//        domain: String,
//        source: String,
//        message: String?,
//        params: [String: Any]?,
//        severity: ErrorSeverityLevel
//    ) {
//        var userInfo: [String: Any] = [
//            "domain": domain,
//            "source": source,
//            "severity": severity.rawValue,
//            "localized_description": error.localizedDescription,
//            "error_code": (error as NSError).code
//        ]
//
//        if let message = message {
//            userInfo["message"] = message
//        }
//
        // params — дополнительные параметры, которые разработчик может передать вручную
        // merge(params) — объединяет словари, НЕ перезаписывая существующие ключи userInfo
//        if let params = params {
//            userInfo.merge(params) { current, _ in current }
//        }
//
//        // Добавляем stacktrace
//        let stack = Thread.callStackSymbols.joined(separator: "\n")
//        userInfo["stacktrace"] = stack
//
//        // Превращаем в NSError, чтобы Crashlytics корректно отобразил domain/code/userInfo
//        let nsError = NSError(
//            domain: domain,
//            code: (error as NSError).code,
//            userInfo: userInfo
//        )
//
//        // Отправляем ошибку
//        crashlytics.record(error: nsError)
//
//        // Custom Keys для фильтрации и аналитики
//        userInfo.forEach { key, value in
//            crashlytics.setCustomValue(value, forKey: "log_\(key)")
//        }
//
//        // Текстовый лог
//        crashlytics.log("[\(severity.rawValue.uppercased())] \(source): \(message ?? error.localizedDescription)")
//    }
//}



//protocol ErrorDiagnosticsProtocol {
//    func handle(error: (any Error)?, context: String?) -> String
//}
//
//final class ErrorDiagnosticsCenter: ErrorDiagnosticsProtocol {
//
//    private let realtimeDomain = "com.firebase.database"
//    private let googleSignInDomain = "com.google.GIDSignIn"
//    private let logger: ErrorLoggingServiceProtocol
//
//    init(logger: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.logger = logger
//    }
//
//    // MARK: - Основной метод обработки ошибок
//
//    func handle(error: (any Error)?, context: String? = nil) -> String {
//        print("ErrorDiagnosticsCenter received error: \(String(describing: error?.localizedDescription))")
//
//        guard let error = error else {
//            return Localized.FirebaseInternalError.defaultError
//        }
//
//        // 1. Специальные типы до NSError
//
//        if let decodingError = error as? DecodingError {
//            logCritical(error: error, context: context ?? "DecodingError: \(decodingError)")
//            return Localized.FirebaseInternalError.defaultError
//        }
//
//        if let pickerError = error as? PhotoPickerError {
//            return handlePhotoPickerError(pickerError)
//        }
//
//        // 2. NSError‑ветки
//
//        if let nsError = error as NSError? {
//#if DEBUG
//            print("NSError domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")
//#else
//            logger.logError(
//                error,
//                domain: nsError.domain,
//                source: context ?? "NSError",
//                message: nsError.localizedDescription,
//                params: ["nsError_code": nsError.code],
//                severity: .warning
//            )
//#endif
//
//            // Auth
//            if let authCode = AuthErrorCode(rawValue: nsError.code) {
//                return handleAuthError(authCode, error: error, context: context)
//            }
//
//            // Firestore
//            if nsError.domain == FirestoreErrorDomain {
//                return handleFirestoreError(nsError, error: error, context: context)
//            }
//
//            // Storage
//            if let storageCode = StorageErrorCode(rawValue: nsError.code) {
//                return handleStorageError(storageCode, error: error, context: context)
//            }
//
//            // Realtime Database
//            if nsError.domain == realtimeDomain {
//                return handleRealtimeDatabaseError(nsError, error: error, context: context)
//            }
//
//            // Anonymous Auth
//            if nsError.domain == "Anonymous Auth" {
//                logCritical(error: error, context: context ?? "AnonymousAuth")
//                return Localized.FirebaseInternalError.anonymousAuthError
//            }
//
//            // Google Sign-In
//            if nsError.domain == googleSignInDomain {
//                return handleGoogleSignInError(nsError, error: error, context: context)
//            }
//        }
//
//        // 3. Пользовательские FirebaseInternalError
//
//        if let custom = error as? FirebaseInternalError {
//            logCritical(error: error, context: context ?? "FirebaseInternalError")
//            return custom.errorDescription ?? Localized.FirebaseInternalError.defaultError
//        }
//
//        // 4. Всё остальное — неизвестное → логируем
//
//        logCritical(error: error, context: context ?? "UnknownError")
//        return Localized.FirebaseInternalError.defaultError
//    }
//
//    // MARK: - Критичное логирование (Debug vs Release)
//
//    /// В Debug печатаем всё в консоль.
//    /// В Release отправляем в Crashlytics через CrashlyticsLoggingService.
//    private func logCritical(error: Error, context: String) {
//#if DEBUG
//        print("⚠️ [DEBUG] Critical error context: \(context)")
//        print("⚠️ [DEBUG] Error: \(error.localizedDescription)")
//        print("⚠️ [DEBUG] Stack trace:")
//        Thread.callStackSymbols.forEach { print($0) }
//#else
//        let params: [String: Any] = [
//            "context": context
//        ]
//
//        logger.logError(
//            error,
//            domain: "Critical",
//            source: context,
//            message: error.localizedDescription,
//            params: params,
//            severity: .error
//        )
//#endif
//    }
//
//    // MARK: - Photo Picker
//
//    private func handlePhotoPickerError(_ pickerError: PhotoPickerError) -> String {
//        switch pickerError {
//        case .noItemAvailable:
//            return Localized.PhotoPickerError.noItemAvailable
//        case .itemUnavailable:
//            return Localized.PhotoPickerError.itemUnavailable
//        case .unsupportedType:
//            return Localized.PhotoPickerError.unsupportedType
//        case .iCloudRequired:
//            return Localized.PhotoPickerError.iCloudRequired
//        case .loadFailed(let underlyingError),
//                .unknown(let underlyingError):
//            return (underlyingError as NSError).localizedDescription
//        }
//    }
//
//    // MARK: - Auth
//
//
//    private func handleAuthError(_ code: AuthErrorCode, error: Error, context: String?) -> String {
//        switch code {
//
//        case .providerAlreadyLinked:                 // Провайдер (Google/Apple) уже привязан к аккаунту
//            return Localized.Auth.providerAlreadyLinked
//
//        case .credentialAlreadyInUse:                // Эти credentials уже используются другим аккаунтом
//            return Localized.Auth.credentialAlreadyInUse
//
//        case .userMismatch:                          // Credentials принадлежат другому пользователю (ошибка reauth)
//            return Localized.Auth.userMismatch
//
//        case .requiresRecentLogin:                   // Операция требует недавнего входа (смена email/пароля)
//            return Localized.Auth.requiresRecentLogin
//
//        case .userNotFound:                          // Пользователь с таким email не существует
//            return Localized.Auth.userNotFound
//
//        case .invalidRecipientEmail:                 // Email получателя недействителен
//            return Localized.Auth.invalidRecipientEmail
//
//        case .missingEmail:                          // Email отсутствует (например, при регистрации)
//            return Localized.Auth.missingEmail
//
//        case .accountExistsWithDifferentCredential:  // Аккаунт существует, но с другим провайдером (email vs Google)
//            return Localized.Auth.accountExistsWithDifferentCredential
//
//            // --- Остальные пользовательские ошибки (не критичные) ---
//
//        case .invalidEmail:                          // Неверный формат email
//            return Localized.Auth.invalidEmail
//
//        case .weakPassword:                          // Пароль слишком слабый
//            return Localized.Auth.weakPassword
//
//        case .wrongPassword:                         // Неверный пароль
//            return Localized.Auth.wrongPassword
//
//        case .emailAlreadyInUse:                     // Email уже зарегистрирован
//            return Localized.Auth.emailAlreadyInUse
//
//        case .tooManyRequests:                       // Слишком много попыток — временная блокировка Firebase
//            return Localized.Auth.tooManyRequests
//
//        case .networkError:                          // Проблема с интернет‑соединением
//            return Localized.Auth.networkError
//
//            // --- Всё остальное считаем критичным и логируем ---
//
//        default:                                     // Неизвестная/новая ошибка Firebase Auth → критично
//            logCritical(error: error, context: context ?? "AuthErrorCode.\(code.rawValue)")
//            return Localized.Auth.generic
//        }
//    }
//
//
//    // MARK: - Firestore
//
//    private func handleFirestoreError(_ nsError: NSError, error: Error, context: String?) -> String {
//        switch nsError.code {
//
//        case FirestoreErrorCode.cancelled.rawValue:          // Операция отменена (клиентом или сервером), не критично
//            return Localized.Firestore.cancelled
//
//        case FirestoreErrorCode.unavailable.rawValue:        // Firestore временно недоступен (сервер перегружен / проблемы сети)
//            return Localized.Firestore.unavailable
//
//        case FirestoreErrorCode.deadlineExceeded.rawValue:   // Сервер не успел выполнить операцию (таймаут)
//            return Localized.Firestore.deadlineExceeded
//
//            // --- Критичные ошибки Firestore (логируем через одну ветку) ---
//
//        case FirestoreErrorCode.invalidArgument.rawValue,    // Клиент передал некорректные аргументы
//            FirestoreErrorCode.notFound.rawValue,           // Документ/ресурс не найден → ошибка данных
//            FirestoreErrorCode.alreadyExists.rawValue,      // Попытка создать ресурс, который уже существует
//            FirestoreErrorCode.permissionDenied.rawValue,   // Правила безопасности Firestore запретили операцию
//            FirestoreErrorCode.resourceExhausted.rawValue,  // Превышены квоты/лимиты Firestore
//            FirestoreErrorCode.failedPrecondition.rawValue, // Нарушено предусловие (неверное состояние документа)
//            FirestoreErrorCode.aborted.rawValue,            // Операция прервана (конфликт транзакций)
//            FirestoreErrorCode.outOfRange.rawValue,         // Запрошены данные вне допустимого диапазона
//            FirestoreErrorCode.unimplemented.rawValue,      // Операция не поддерживается сервером или SDK
//            FirestoreErrorCode.internal.rawValue,           // Внутренняя ошибка Firestore (сбой сервера/SDK)
//            FirestoreErrorCode.dataLoss.rawValue,           // Потеря или повреждение данных
//            FirestoreErrorCode.unauthenticated.rawValue:    // Клиент не аутентифицирован или токен недействителен
//
//            logCritical(error: error, context: context ?? "Firestore.\(nsError.code)")
//            return Localized.Firestore.generic
//
//            // --- Неизвестная ошибка Firestore ---
//
//        default:                                             // Новый/неизвестный код Firestore → считаем критичным
//            logCritical(error: error, context: context ?? "Firestore.unknown(\(nsError.code))")
//            return Localized.Firestore.generic
//        }
//    }
//
//
//
//    // MARK: - Storage
//
//    private func handleStorageError(_ code: StorageErrorCode, error: Error, context: String?) -> String {
//        switch code {
//
//        case .cancelled:                     // Операция отменена пользователем или системой (не критично)
//            return Localized.Storage.cancelled
//
//            // --- Остальные критичные ошибки Storage (логируем через одну ветку) ---
//
//        case .unauthenticated,              // Пользователь не авторизован → в нашем приложении быть не может → критично
//                .unauthorized,                 // Правила безопасности запретили доступ → ошибка конфигурации/логики
//                .downloadSizeExceeded,         // Запрошенный файл превышает лимит → ошибка логики загрузки
//                .objectNotFound,               // Файл не найден по указанному пути
//                .bucketNotFound,               // Bucket отсутствует (ошибка конфигурации Firebase)
//                .projectNotFound,              // Firebase-проект не найден
//                .quotaExceeded,                // Превышена квота Storage
//                .nonMatchingChecksum,          // Контрольная сумма не совпала → файл повреждён
//                .invalidArgument,              // Клиент передал некорректные аргументы
//                .unknown,                      // Неизвестная ошибка Storage
//                .bucketMismatch,               // Файл в другом bucket, чем указано в конфигурации
//                .internalError,                // Внутренняя ошибка Firebase Storage
//                .pathError,                    // Неверный путь к файлу
//                .retryLimitExceeded:           // Firebase исчерпал количество попыток повторить операцию
//
//            logCritical(error: error, context: context ?? "Storage.\(code.rawValue)")
//            return Localized.Storage.generic
//
//        @unknown default:                   // Новый/неизвестный код Storage → критично
//            logCritical(error: error, context: context ?? "Storage.unknown")
//            return Localized.Storage.generic
//        }
//    }
//
//
//
//    // MARK: - Realtime Database
//
//    private func handleRealtimeDatabaseError(_ nsError: NSError, error: Error, context: String?) -> String {
//        switch nsError.code {
//
//        case NSURLErrorNotConnectedToInternet:          // Нет интернет‑соединения (не критично)
//            return Localized.RealtimeDatabase.networkError
//
//        case NSURLErrorTimedOut:                        // Сервер не ответил вовремя (таймаут)
//            return Localized.RealtimeDatabase.timeout
//
//        case NSURLErrorCancelled:                       // Операция отменена пользователем или системой
//            return Localized.RealtimeDatabase.operationCancelled
//
//            // --- Критичные ошибки Realtime Database (логируем через одну ветку) ---
//
//        case NSURLErrorCannotFindHost,                  // Хост Firebase не найден (DNS/конфигурация)
//            NSURLErrorCannotConnectToHost,             // Невозможно установить соединение с хостом
//            NSURLErrorNetworkConnectionLost,           // Соединение потеряно во время операции
//            NSURLErrorResourceUnavailable,             // Ресурс временно недоступен
//            NSURLErrorUserCancelledAuthentication,     // Пользователь отменил системную аутентификацию
//        NSURLErrorUserAuthenticationRequired:      // Требуется аутентификация (токен недействителен)
//
//            logCritical(error: error, context: context ?? "RealtimeDatabase.\(nsError.code)")
//            return Localized.RealtimeDatabase.generic
//
//            // --- Неизвестная ошибка Realtime Database ---
//
//        default:                                        // Новый/неизвестный код → считаем критичным
//            logCritical(error: error, context: context ?? "RealtimeDatabase.unknown(\(nsError.code))")
//            return Localized.RealtimeDatabase.generic
//        }
//    }
//
//
//    // MARK: - Google Sign-In
//
//    private func handleGoogleSignInError(_ nsError: NSError, error: Error, context: String?) -> String {
//        guard let code = GoogleSignInErrorCode(rawValue: nsError.code) else {
//            logCritical(error: error, context: context ?? "GoogleSignIn.unknown(\(nsError.code))")
//            return Localized.GoogleSignInError.defaultError
//        }
//
//        switch code {
//
//        case .canceled:                                  // Пользователь отменил вход (закрыл окно Google)
//            return Localized.GoogleSignInError.cancelled
//
//            // --- Критичные ошибки Google Sign‑In (логируем через одну ветку) ---
//
//        case .scopesAlreadyGranted,                      // Scopes уже выданы → ошибка логики приложения
//                .noCurrentUser,                             // Нет текущего пользователя → сбой состояния SDK
//                .unknown,                                   // Неизвестная ошибка Google Sign‑In
//                .keychain,                                  // Ошибка Keychain при сохранении/чтении токена
//                .hasNoAuthInKeychain,                       // Нет сохранённой авторизации в Keychain
//                .emmError,                                  // Корпоративная политика запрещает вход
//                .mismatchWithCurrentUser:                   // Пользователь Google не совпадает с ожидаемым
//
//            logCritical(error: error, context: context ?? "GoogleSignIn.\(code.rawValue)")
//            return Localized.GoogleSignInError.defaultError
//        }
//    }
//}
//
//
//




//        private func handleGoogleSignInError(_ nsError: NSError) -> String {
//            // ✅ Логируем входящие данные
//            print("🔍 [GoogleSignInError] domain=\(nsError.domain), code=\(nsError.code), description=\(nsError.localizedDescription)")
//
//            switch nsError.code {
//            case -1:
//                // unknown — неизвестная ошибка
//                return Localized.FirebaseInternalError.defaultError
//
//            case -2:
//                // keychain — ошибка доступа к Keychain
//                return Localized.GoogleSignInError.keychainError
//
//            case -3:
//                // noCurrentUser — нет текущего пользователя (например, вызов API без авторизации)
//                return Localized.GoogleSignInError.noHandlers
//
//            case -4:
//                // hasNoAuthInKeychain — нет сохранённых токенов в Keychain
//                return Localized.GoogleSignInError.noValidTokens
//
//            case -5:
//                // canceled — пользователь отменил вход
//                return Localized.GoogleSignInError.cancelled
//
//            case -6:
//                // EMM — ошибка Enterprise Mobility Management (ограничения корпоративной политики)
//                return Localized.GoogleSignInError.networkError // ⚠️ можно завести отдельный ключ, если нужно различать
//
//            case -7:
//                // scopesAlreadyGranted — запрошенные scope уже были предоставлены
//                return Localized.GoogleSignInError.serverError // ⚠️ лучше завести отдельный ключ, например .scopesAlreadyGranted
//
//            case -8:
//                // mismatchWithCurrentUser — несоответствие текущему пользователю
//                return Localized.GoogleSignInError.tokenExchangeFailed // ⚠️ лучше завести отдельный ключ, например .userMismatch
//
//            default:
//                // неизвестная ошибка → логируем
//                return Localized.FirebaseInternalError.defaultError
//            }
//
    //        switch nsError.code {
    //        case -1:
    //            return Localized.GoogleSignInError.cancelled
    //        case -2:
    ////            Crashlytics.crashlytics().record(error: nsError) // ❗ обязательно логировать
    //            return Localized.GoogleSignInError.keychainError
    //        case -3:
    ////            Crashlytics.crashlytics().record(error: nsError) // ❗ обязательно логировать
    //            return Localized.GoogleSignInError.noHandlers
    //        case -4:
    //            return Localized.GoogleSignInError.noValidTokens
    //        case -5:
    ////            Crashlytics.crashlytics().record(error: nsError) // ❗ обязательно логировать
    //            return Localized.GoogleSignInError.invalidClientID
    //        case -6:
    //            return Localized.GoogleSignInError.networkError
    //        case -7:
    //            return Localized.GoogleSignInError.serverError
    //        case -8:
    ////            Crashlytics.crashlytics().record(error: nsError) // ❗ обязательно логировать
    //            return Localized.GoogleSignInError.tokenExchangeFailed
    //        case -9:
    //            return Localized.GoogleSignInError.scopeError
    //        default:
    ////            Crashlytics.crashlytics().record(error: nsError) // ❗ неизвестная ошибка → логируем
    //            return Localized.FirebaseInternalError.defaultError
    //        }
//}

//    func handle(error: (any Error)?) -> String {
//        print("error - \(String(describing: error?.localizedDescription))")
//        guard let error = error else {
//            return Localized.FirebaseEnternalError.defaultError
//        }
//
//        // Преобразуем ошибку в NSError для работы с кодами ошибок
//        if let nsError = error as NSError? {
//            if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
//                return handleAuthError(authErrorCode)
//            }
//            if nsError.domain == FirestoreErrorDomain {
//                return handleFirestoreError(nsError)
//            }
//            if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
//                return handleStorageError(storageErrorCode)
//            }
//            if nsError.domain == RealtimeDatabaseErrorDomain {
//                return handleRealtimeDatabaseError(nsError)
//            }
//            if nsError.domain == "Anonymous Auth" {
//                return Localized.FirebaseEnternalError.anonymousAuthError
//            }
//        }
//
//        if let customError = error as? FirebaseEnternalError {
//            return customError.errorDescription ?? Localized.FirebaseEnternalError.defaultError
//        }
//
//        // Обработка неопознанных ошибок
//        return Localized.FirebaseEnternalError.defaultError
//    }


// MARK: - before Localization -


//protocol ErrorHandlerProtocol {
//    func handle(error:Error?) -> String
//}
//
///// Как мы будем работать с log to Crashlytics.
///// в case будут только те ошибки что мы хотим отобразаить на алерт.
///// в returne будем выбрасывть общий текст для алерт а перед этим выбрасывть тот log что нам нужен.
//
//class SharedErrorHandler: ErrorHandlerProtocol {
//    
//    
//    private let RealtimeDatabaseErrorDomain = "com.firebase.database"
//
//    //    any Error
//    func handle(error: (any Error)?) -> String {
//        
//        print("error - \(String(describing: error?.localizedDescription))")
//        guard let error = error else {
//            return FirebaseEnternalAppError.defaultError.errorDescription
//        }
//        // Преобразуем ошибку в NSError для работы с кодами ошибок
//        if let nsError = error as NSError? {
//            if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
//                return handleAuthError(authErrorCode)
//            }
//            if nsError.domain == FirestoreErrorDomain {
//                return handleFirestoreError(nsError)
//            }
//            if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
//                return handleStorageError(storageErrorCode)
//            }
//            if nsError.domain == RealtimeDatabaseErrorDomain {
//                return handleRealtimeDatabaseError(nsError)
//            }
//        }
//        
//        if let customError = error as? FirebaseEnternalAppError {
//            return customError.errorDescription
//        }
//        // Обработка неопознанных ошибок
//        return FirebaseEnternalAppError.defaultError.errorDescription
//    }
//
//
//    private func handleAuthError(_ code: AuthErrorCode) -> String {
//        switch code {
//        case .providerAlreadyLinked:
//            return "Пользователь уже связан с этим поставщиком учетных данных. Пожалуйста, войдите, используя этого поставщика, или свяжитесь с другим."
//        case .credentialAlreadyInUse:
//            return "Учетные данные уже используются другим пользователем. Пожалуйста, войдите с помощью этих учетных данных или используйте другие."
//        case .tooManyRequests:
//            return "Было сделано слишком много запросов к серверу в короткий промежуток времени. Попробуйте повторить попытку позже."
//        case .userTokenExpired:
//            return "Токен пользователя истек. Необходим повторный вход в систему."
//        case .invalidUserToken:
//            return "Токен пользователя больше не действителен. Необходим повторный вход в систему."
//        case .userMismatch:
//            return "Идентификатор пользователя не совпадает. Необходим повторный вход в систему."
//        case .requiresRecentLogin:
//            return "Вам необходимо войти в систему снова перед этой операцией. Это необходимо для подтверждения вашей личности и защиты вашего аккаунта от несанкционированного доступа. Пожалуйста, выйдите из системы и войдите снова, чтобы продолжить."
//        case .emailAlreadyInUse:
//            return "Электронная почта уже используется другим пользователем. Пожалуйста, войдите с помощью этой электронной почты или используйте другую."
//        case .invalidEmail:
//            return "Предоставленный адрес электронной почты недействителен или не соответствует формату стандартного адреса электронной почты. Убедитесь, что вы вводите адрес электронной почты в правильном формате."
//        case .weakPassword:
//            return "Введенный пароль слишком слабый. Пожалуйста, введите более сложный пароль и попробуйте снова."
//        case .networkError:
//            return "Произошла сетевая ошибка. Пожалуйста, проверьте свое сетевое подключение и попробуйте снова."
//        case .keychainError:
//            return "Проблема с доступом к хранилищу учетных данных на устройстве. Пожалуйста, попробуйте снова или перезагрузите устройство."
//        case .userNotFound:
//            return "Адрес электронной почты не связан с существующим аккаунтом. Убедитесь, что вы вводите адрес электронной почты, который был использован при создании аккаунта."
//        case .wrongPassword:
//            return "Предоставленный пароль неверен. Убедитесь, что вы вводите правильный пароль для своего аккаунта."
//        case .expiredActionCode:
//            return "Код действия истек. Пожалуйста, запросите новый код и попробуйте снова."
//        case .invalidCredential:
//            return "Предоставленные учетные данные недействительны. Пожалуйста, проверьте свои учетные данные и попробуйте снова. Если проблема не решается, вы можете сбросить свой пароль или обратиться в службу поддержки."
//        case .invalidRecipientEmail:
//            return "Адрес электронной почты получателя недействителен. Пожалуйста, проверьте адрес и попробуйте снова."
//        case .missingEmail:
//            return "Адрес электронной почты отсутствует. Пожалуйста, предоставьте действующий адрес электронной почты и попробуйте снова."
//        case .userDisabled:
//            return "Пользователь был отключен. Свяжитесь с администратором вашего системы или службой поддержки."
//        case .invalidSender:
//            return "Отправитель, указанный в запросе, недействителен. Пожалуйста, проверьте данные отправителя и попробуйте снова."
//        case .accountExistsWithDifferentCredential:
//            return "Учетные данные уже используются с другим аккаунтом. Пожалуйста, используйте другой метод входа или используйте эти учетные данные для входа в существующий аккаунт."
//        case .operationNotAllowed:
//            return "Учетные записи с выбранным поставщиком удостоверений не включены. Пожалуйста, обратитесь к администратору для получения помощи."
//        default:
//            return "Ошибка AuthErrorCode. Попробуйте еще раз."
//        }
//    }
//    
//    private func handleFirestoreError(_ nsError: NSError) -> String {
//        switch nsError.code {
//        case FirestoreErrorCode.cancelled.rawValue:
//            return "FirestoreErrorCode. Операция была отменена. Попробуйте еще раз."
//        case FirestoreErrorCode.unavailable.rawValue:
//            return "FirestoreErrorCode. Сервис временно недоступен. Попробуйте позже."
//        case FirestoreErrorCode.invalidArgument.rawValue:
//            return "FirestoreErrorCode. Переданы недопустимые аргументы. Пожалуйста, проверьте данные и попробуйте еще раз."
//        case FirestoreErrorCode.unknown.rawValue:
//                return "Произошла неизвестная ошибка. Пожалуйста, попробуйте снова."
//        case FirestoreErrorCode.deadlineExceeded.rawValue:
//            return "FirestoreErrorCode. Превышен срок выполнения операции. Пожалуйста, повторите попытку."
//        case FirestoreErrorCode.notFound.rawValue:
//            return "FirestoreErrorCode. Данные не найдены. Проверьте правильность введенных данных и попробуйте снова."
//        case FirestoreErrorCode.alreadyExists.rawValue:
//            return "FirestoreErrorCode. Данные уже существуют. Пожалуйста, проверьте данные и попробуйте снова."
//        case FirestoreErrorCode.permissionDenied.rawValue:
//            return "FirestoreErrorCode. Доступ запрещен. Проверьте разрешения и попробуйте снова."
//        case FirestoreErrorCode.resourceExhausted.rawValue:
//            return "FirestoreErrorCode. Ресурсы исчерпаны. Попробуйте позже."
//        case FirestoreErrorCode.failedPrecondition.rawValue:
//            return "FirestoreErrorCode. Не выполнено предварительное условие. Пожалуйста, проверьте данные и повторите попытку."
//        case FirestoreErrorCode.aborted.rawValue:
//            return "FirestoreErrorCode. Операция была прервана. Пожалуйста, попробуйте еще раз."
//        case FirestoreErrorCode.outOfRange.rawValue:
//            return "FirestoreErrorCode. Значение выходит за пределы допустимого диапазона. Проверьте данные и попробуйте снова."
//        case FirestoreErrorCode.unimplemented.rawValue:
//            return "FirestoreErrorCode. Функция не реализована. Пожалуйста, попробуйте позже."
//        case FirestoreErrorCode.internal.rawValue:
//            return "FirestoreErrorCode. Произошла внутренняя ошибка сервера. Пожалуйста, повторите попытку позже."
//        case FirestoreErrorCode.dataLoss.rawValue:
//            return "FirestoreErrorCode. Произошла потеря данных. Пожалуйста, попробуйте снова."
//        case FirestoreErrorCode.unauthenticated.rawValue:
//            return "FirestoreErrorCode. Пользователь не аутентифицирован. Пожалуйста, войдите в систему и попробуйте снова."
//        default:
//            return "Ошибка FirestoreErrorCode. Попробуйте еще раз."
//        }
//    }
//    
//    private func handleStorageError(_ code: StorageErrorCode) -> String {
//        switch code {
//        case .objectNotFound:
//            return "StorageErrorCode. Файл не найден. Проверьте путь и попробуйте снова."
//        case .bucketNotFound:
//            return "StorageErrorCode. Указанное хранилище не найдено. Проверьте настройки и попробуйте снова."
//        case .projectNotFound:
//            return "StorageErrorCode. Указанный проект не найден. Проверьте настройки проекта и попробуйте снова."
//        case .quotaExceeded:
//            return "StorageErrorCode. Превышена квота. Попробуйте позже."
//        case .unauthenticated:
//            return "StorageErrorCode. Необходимо войти в систему для выполнения этой операции. Пожалуйста, аутентифицируйтесь и попробуйте снова."
//        case .unauthorized:
//            return "StorageErrorCode. У вас нет разрешения на доступ к этому ресурсу."
//        case .retryLimitExceeded:
//            return "StorageErrorCode. Превышено количество попыток. Пожалуйста, попробуйте позже."
//        case .nonMatchingChecksum:
//            return "StorageErrorCode. Контрольная сумма не совпадает. Повторите загрузку файла."
//        case .downloadSizeExceeded:
//            return "StorageErrorCode. Размер загрузки превышает установленный предел. Попробуйте загрузить файл меньшего размера."
//        case .cancelled:
//            return "StorageErrorCode. Операция была отменена. Попробуйте еще раз."
//        case .invalidArgument:
//            return "StorageErrorCode. Переданы недопустимые аргументы. Пожалуйста, проверьте данные и попробуйте снова."
//        case .unknown:
//            return "StorageErrorCode. Произошла неизвестная ошибка. Пожалуйста, попробуйте снова."
//        case .bucketMismatch:
//            return "StorageErrorCode. Неправильное хранилище. Проверьте настройки и попробуйте снова."
//        case .internalError:
//            return "StorageErrorCode. Внутренняя ошибка сервера. Пожалуйста, попробуйте позже."
//        case .pathError:
//            return "StorageErrorCode. Ошибка пути. Проверьте путь и попробуйте снова."
//        @unknown default:
//            return "Ошибка StorageErrorCode. Попробуйте еще раз."
//        }
//    }
//    
//    // Метод для обработки ошибок Realtime Database
//    private func handleRealtimeDatabaseError(_ nsError: NSError) -> String {
//        switch nsError.code {
//        case NSURLErrorNotConnectedToInternet:
//            return "RealtimeDatabase. NetworkError. Произошла ошибка сети. Пожалуйста, проверьте подключение и попробуйте снова."
//        case NSURLErrorTimedOut:
//            return "RealtimeDatabase. NetworkError. Время ожидания истекло. Пожалуйста, попробуйте снова."
//        case NSURLErrorCancelled:
//            return "RealtimeDatabase. OperationCancelled. Операция была отменена. Попробуйте еще раз."
//        case NSURLErrorCannotFindHost:
//            return "RealtimeDatabase. NetworkError. Невозможно найти хост. Проверьте настройки сети и попробуйте снова."
//        case NSURLErrorCannotConnectToHost:
//            return "RealtimeDatabase. NetworkError. Невозможно подключиться к хосту. Проверьте подключение и попробуйте снова."
//        case NSURLErrorNetworkConnectionLost:
//            return "RealtimeDatabase. NetworkError. Потеряно сетевое подключение. Пожалуйста, переподключитесь и попробуйте снова."
//        case NSURLErrorResourceUnavailable:
//            return "RealtimeDatabase. ServiceUnavailable. Ресурс временно недоступен. Попробуйте позже."
//        case NSURLErrorUserCancelledAuthentication:
//            return "RealtimeDatabase. AuthenticationError. Пользователь отменил аутентификацию. Попробуйте снова."
//        case NSURLErrorUserAuthenticationRequired:
//            return "RealtimeDatabase. AuthenticationError. Необходима аутентификация пользователя. Пожалуйста, войдите в систему и попробуйте снова."
//        default:
//            return "Ошибка RealtimeDatabase. Попробуйте еще раз."
//        }
//    }
//
//}


    



// MARK: - Trash

// log to Crashlytics

//// Обработка ошибок Firebase Storage
//           if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
//               let message = handleStorageError(storageErrorCode)
//               if shouldLogToCrashlytics(error: error) {
//                   logToCrashlytics(error: error)
//               }
//               return message
//           }

//// Определяем, нужно ли отправлять ошибку в Crashlytics
//    private func shouldLogToCrashlytics(error: Error) -> Bool {
//        if let nsError = error as NSError? {
//            // Пример: Логируем только внутренние ошибки сервера
//            if nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.internal.rawValue {
//                return true
//            }
//        }
//        return false
//    }
//
//    // Логируем ошибку в Crashlytics
//    private func logToCrashlytics(error: Error) {
//        Crashlytics.crashlytics().record(error: error)
//    }







//private func handleFirestoreError(_ error:Error) -> String {
//    if let error = error as? FirestoreErrorCode {
//        switch error.code {
//            
//        case .OK:
//            <#code#>
//        case .cancelled:
//            <#code#>
//        case .unknown:
//            <#code#>
//        case .invalidArgument:
//            <#code#>
//        case .deadlineExceeded:
//            <#code#>
//        case .notFound:
//            <#code#>
//        case .alreadyExists:
//            <#code#>
//        case .permissionDenied:
//            <#code#>
//        case .resourceExhausted:
//            <#code#>
//        case .failedPrecondition:
//            <#code#>
//        case .aborted:
//            <#code#>
//        case .outOfRange:
//            <#code#>
//        case .unimplemented:
//            <#code#>
//        case .internal:
//            <#code#>
//        case .unavailable:
//            <#code#>
//        case .dataLoss:
//            <#code#>
//        case .unauthenticated:
//            <#code#>
//        @unknown default:
//            <#code#>
//        }
//    }
//}
