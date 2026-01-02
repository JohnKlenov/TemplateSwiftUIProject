//
//  SharedErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.10.24.
//


// мы можем отлавить эту ошибку в блоке catch двумя способами:

//if nsError.domain == NSCocoaErrorDomain {
//    return handleDecodingError(nsError)
//}

//private func handleDecodingError(_ error: NSError) -> String {
//    switch error.code {
//    case 4864: // типичная ошибка расшифровки JSON
//        return Localized.FirebaseEnternalError.decodingTypeMismatch
//    case 4860:
//        return Localized.FirebaseEnternalError.missingRequiredKey
//    default:
//        return Localized.FirebaseEnternalError.decodingError // fallback
//    }
//}

//или:

//if let decodingError = error as? DecodingError {
//    return handleDecodingError(decodingError)
//}

//private func handleDecodingError(_ error: DecodingError) -> String {
//    switch error {
//    case .typeMismatch(let type, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Тип данных не совпадает: ожидали \(type), путь: \(path)"
//
//    case .valueNotFound(let type, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Значение типа \(type) не найдено, путь: \(path)"
//
//    case .keyNotFound(let key, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Отсутствует ключ '\(key.stringValue)', путь: \(path)"
//
//    case .dataCorrupted(let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Данные повреждены: \(context.debugDescription), путь: \(path)"
//
//    @unknown default:
//        return "Неизвестная ошибка расшифровки данных"
//    }
//}

//as NSError + domain - Упрощённую классификацию через NSCocoaErrorDomain, но без деталей
//as? DecodingError  - Доступ к case, codingPath, debugDescription и конкретному типу

// MARK: - тут мы еще не работали с ошибками которые нужно отображть через алерт а какие логировать
// можно так же передавать в func handle(error: (any Error)?) description то есть откуда она пришла для краш листикса



// MARK: - default error or description error ?

// сейчас мы возвращаем описание ошибки даже те которые пользователю не понять !
// может есть смысл разобрать ошибки на те которые стоит заменить на текст типа default error ?

// MARK: - Crashlytics


// MARK: - из errorHandler.handle(error: error) 
// должен возвращаться локализованный текст ошибки для алерта пользователя
// а в SharedErrorHandler всегда поступать реальная ошибка из сервиса и контекст это для Crashlytics

/// 📌 Подробный комментарий: централизованный Crashlytics через SharedErrorHandler
///
/// Идея:
/// - Держать Crashlytics как зависимость внутри `SharedErrorHandler`, а из разных мест приложения
///   передавать только ошибку и контекст. Это делает обработку ошибок единой и управляемой.
///
/// Почему это best practice:
/// - Единая точка входа: все ошибки проходят через один сервис (меньше дублирования и рассеивания логики).
/// - Чистота кода: UI/бизнес-логика используют `handle(error:context:)` без прямых вызовов Crashlytics.
/// - Гибкость: можно заменить Crashlytics на другой провайдер, изменив реализацию в одном месте.
/// - Богатый контекст: можно добавлять метаданные (operation, intent, uid, isAnonymous), чтобы отчёты были полезными.
///
/// Как использовать:
/// - В местах, где происходит ошибка (например, при авторизации), передаём:
///   `errorHandler.handle(error: err, context: "GoogleAuth: signInWithGoogle intent=signIn")`
/// - Пользователь получит локализованный текст.
/// - Crashlytics получит подробный отчёт с контекстом и самой ошибкой.
///
/// Рекомендации по контексту:
/// - Передавать краткую, но точную строку: где и почему произошло (модуль, операция, ключевые флаги).
/// - Добавлять пользовательские атрибуты при необходимости (uid, платформа, версия).
///
/// Мини-реализация:
/// protocol ErrorHandlerProtocol {
///     func handle(error: Error?, context: String?) -> String
/// }
///
/// class SharedErrorHandler: ErrorHandlerProtocol {
///     func handle(error: Error?, context: String? = nil) -> String {
///         guard let error else { return Localized.FirebaseInternalError.defaultError }
///
///         // 📡 Логируем для разработчиков
///         if let context { Crashlytics.crashlytics().log("Context: \(context)") }
///         Crashlytics.crashlytics().record(error: error)
///
///         // 👤 Текст для пользователя (локализованный, без технических деталей)
///         if let custom = error as? FirebaseInternalError {
///             return custom.errorDescription ?? Localized.FirebaseInternalError.defaultError
///         }
///         return Localized.FirebaseInternalError.defaultError
///     }
/// }
///
/// Итог:
/// - Централизованный `SharedErrorHandler` с Crashlytics — зрелый производственный подход.
/// - UI получает понятное сообщение, разработчики — структурированный отчёт.
/// - Масштабируется и остаётся заменяемым без касания всей кодовой базы.


/// 📌 Подробный комментарий: как видеть полный стек ошибки в Crashlytics
///
/// Проблема:
/// - Вызов `Crashlytics.crashlytics().record(error:)` для обработанных ошибок (не крашей)
///   по умолчанию НЕ прикрепляет полный стек вызовов. Crashlytics автоматически собирает стек
///   только для необработанных исключений (настоящих крашей).
///
/// Цель:
/// - Получать полноценный стек для "ручных" ошибок, чтобы разработчики могли видеть,
///   где именно в коде произошёл сбой, без необходимости передавать подробный `context: String?`.
///
/// Рабочие решения:
/// 1) Прикрепить стек вручную через `Thread.callStackSymbols`
///    - Собираем текущий стек, кладём его в `userInfo` у `NSError`, и отправляем в Crashlytics.
///    Пример:
///    ```swift
///    let stack = Thread.callStackSymbols.joined(separator: "\n")
///    let nsError = NSError(
///        domain: "HandledError",
///        code: 999,
///        userInfo: [NSLocalizedDescriptionKey: error.localizedDescription,
///                   "stackTrace": stack]
///    )
///    Crashlytics.crashlytics().record(error: nsError)
///    ```
///    → В отчёте будет и описание, и ваш кастомный стек.
///
/// 2) Использовать `record(exceptionModel:)`
///    - Создаём `ExceptionModel` и явно задаём `stackTrace`, имитируя отчёт как у краша,
///      но без падения приложения.
///    Пример (идея, может отличаться в зависимости от версии SDK):
///    ```swift
///    let exception = ExceptionModel(name: "GoogleAuthError",
///                                   reason: error.localizedDescription)
///    exception.stackTrace = Thread.callStackSymbols.map { StackFrame(symbol: $0) }
///    Crashlytics.crashlytics().record(exceptionModel: exception)
///    ```
///    → Crashlytics отобразит полноценный стек и метаданные исключения.
///
/// 3) Логировать стек отдельно рядом с ошибкой
///    - Добавляем стек как обычный лог, затем пишем `record(error:)`.
///    Пример:
///    ```swift
///    Crashlytics.crashlytics().log("Stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
///    Crashlytics.crashlytics().record(error: error)
///    ```
///    → В консоли Crashlytics будет виден лог со стеком рядом с записью об ошибке.
///
/// Итог:
/// - `record(error:)` сам по себе не даёт полный стек для обработанных ошибок.
/// - Чтобы стек был виден, используйте один из вариантов выше:
///   • вручную приложить `Thread.callStackSymbols`,
///   • или `ExceptionModel` со `stackTrace`,
///   • или отдельный лог стека.
/// - Это индустриальная практика: пользователю показываем простой алерт,
///   а в Crashlytics отправляем детальный отчёт со стеком для диагностики.

/// 📌 Подробный комментарий к реализации блока в SharedErrorHandler:
///
/// if let error = error {
///     if let context = context {
///         Crashlytics.crashlytics().log("Context: \(context)")
///     }
///     let stack = Thread.callStackSymbols.joined(separator: "\n")
///     Crashlytics.crashlytics().log("Stack:\n\(stack)")
///     Crashlytics.crashlytics().record(error: error)
/// }
///
/// 🔎 Что здесь происходит:
/// 1. Проверяем, что ошибка действительно есть (`if let error = error`).
///
/// 2. Если передан дополнительный контекст (`context`), логируем его в Crashlytics:
///    - Это строка, которую мы можем задать из вызывающего кода (например, "GoogleAuth: signInWithGoogle").
///    - В отчёте Crashlytics будет видно, в каком месте приложения произошла ошибка.
///
/// 3. Получаем текущий стек вызовов через `Thread.callStackSymbols`:
///    - Это массив строк, описывающих последовательность вызовов функций до текущего места.
///    - Склеиваем его в одну строку с разделителем `\n`, чтобы стек был читаемым.
///
/// 4. Логируем стек в Crashlytics (`Crashlytics.crashlytics().log("Stack:\n\(stack)")`):
///    - В отчёте разработчики увидят полный стек вызовов на момент обработки ошибки.
///    - Это помогает понять, из какого экрана/менеджера/операции ошибка пришла.
///
/// 5. Записываем саму ошибку (`Crashlytics.crashlytics().record(error: error)`):
///    - В Crashlytics фиксируется тип ошибки, её описание и связанный контекст.
///    - Таким образом, отчёт содержит и саму ошибку, и дополнительную информацию (context + stack).
///
/// 📌 Итог:
/// - Пользователь получает локализованное сообщение об ошибке (через return из handle).
/// - Разработчики в Crashlytics видят:
///   • контекст (например, "GoogleAuth: signInWithGoogle"),
///   • полный стек вызовов,
///   • сам объект ошибки.
/// - Такой подход даёт централизованную и максимально информативную диагностику ошибок в продакшене.

/// 📌 Контекст: централизованная обработка ошибок через SharedErrorHandler в связке SwiftUI → ViewBuilderService → HomeViewModel → AuthorizationManager
///
/// Что делает `Thread.callStackSymbols`:
/// - Собирает текущий стек вызовов в момент, когда мы попали в `SharedErrorHandler.handle(error:context:)`.
/// - Это список «откуда пришли» до точки обработки, включая ваши методы, Combine/SwiftUI слои и системные фреймы.
///
/// Зачем логировать стек в Crashlytics:
/// - Для команды разработки стек показывает полный путь ошибки: из какого экрана, какого менеджера,
///   какой операции она пришла, и где была обработана.
/// - Пользователь получает лаконичное сообщение, а Crashlytics — подробный технический след.
///
/// Как это выглядит в вашем кейсе (примерная структура стека):
/// Stack:
/// 0   MyApp      SharedErrorHandler.handle(error:context:)                   // централизованная точка обработки
/// 1   MyApp      AuthorizationManager.signInWithGoogle(intent:)              // источник: операция авторизации
/// 2   MyApp      HomeViewModel.googleSignIn()                                // инициатор из ViewModel
/// 3   MyApp      HomeContentView.body.getter                                 // экран Home, где вызвано действие
/// 4   MyApp      ViewBuilderService.homeViewBuild(page:)                     // сборка UI через ваш билдер
/// 5   SwiftUI    ViewGraph.update(...) / CombinePublisher.sink(...)          // системные слои SwiftUI/Combine
/// 6   UIKitCore  UIApplicationMain                                           // вход в цикл событий приложения
///
/// Важно:
/// - Стек формируется на момент вызова `handle(error:context:)`. Поэтому он отражает «путь» до централизованного обработчика,
///   что достаточно для диагностики «где в продуктовой цепочке возникла ошибка».
///
/// Как логировать:
/// let stack = Thread.callStackSymbols.joined(separator: "\n")
/// Crashlytics.crashlytics().log("Stack:\n\(stack)")
/// Crashlytics.crashlytics().record(error: error)
///
/// Результат:
/// - В отчёте Crashlytics вы увидите и саму ошибку, и полный стек вызовов, который ведёт к `SharedErrorHandler`.
/// - Это позволяет быстро сопоставить ошибку с конкретным экраном (Home), менеджером (AuthorizationManager),
///   и местом её обработки (SharedErrorHandler) в вашей архитектуре.



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



import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

protocol ErrorHandlerProtocol {
    func handle(error:Error?) -> String
}


// MARK: - в проде из func handle(error: (any Error)?) -> String
// должна выходить локализованный тект ошибки для алерта (понятный пользователю)
// а под капотом всегда поступать реальная ошибка из сервиса и контекст это для Crashlytics
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
