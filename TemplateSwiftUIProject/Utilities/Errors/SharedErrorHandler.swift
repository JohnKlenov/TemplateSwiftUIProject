//
//  SharedErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.10.24.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

protocol ErrorHandlerProtocol {
    func handle(error:Error?) -> String
}

class SharedErrorHandler: ErrorHandlerProtocol {
    
    private let RealtimeDatabaseErrorDomain = "com.firebase.database"

    func handle(error: (any Error)?) -> String {
        print("error - \(String(describing: error?.localizedDescription))")
        guard let error = error else {
            return Localized.FirebaseEnternalError.defaultError
        }
        
        // Преобразуем ошибку в NSError для работы с кодами ошибок
        if let nsError = error as NSError? {
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
        }
        
        if let customError = error as? FirebaseEnternalError {
            return customError.errorDescription ?? Localized.FirebaseEnternalError.defaultError
        }
        
        // Обработка неопознанных ошибок
        return Localized.FirebaseEnternalError.defaultError
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
