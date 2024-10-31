//
//  SharedErrorHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.10.24.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

protocol ErrorHandlerProtocol {
    func handle(error:Error) -> String
}

/// Как мы будем работать с log to Crashlytics.
/// в case будут только те ошибки что мы хотим отобразаить на алерт.
/// в returne будем выбрасывть общий текст для алерт а перед этим выбрасывть тот log что нам нужен.

class SharedErrorHandler: ErrorHandlerProtocol {
    
    
    func handle(error: any Error) -> String {
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
        }
        
        if let customError = error as? PathFirestoreError {
            return customError.errorDescription
        }
        // Обработка неопознанных ошибок
        return "SharedErrorHandler Что-то пошло не так. Попробуйте еще раз."
    }
    
    private func handleAuthError(_ code: AuthErrorCode) -> String {
        switch code {
        case .providerAlreadyLinked:
            return "Пользователь уже связан с этим поставщиком учетных данных. Пожалуйста, войдите, используя этого поставщика, или свяжитесь с другим."
        case .credentialAlreadyInUse:
            return "Учетные данные уже используются другим пользователем. Пожалуйста, войдите с помощью этих учетных данных или используйте другие."
        case .tooManyRequests:
            return "Было сделано слишком много запросов к серверу в короткий промежуток времени. Попробуйте повторить попытку позже."
        case .userTokenExpired:
            return "Токен пользователя истек. Необходим повторный вход в систему."
        case .invalidUserToken:
            return "Токен пользователя больше не действителен. Необходим повторный вход в систему."
        case .userMismatch:
            return "Идентификатор пользователя не совпадает. Необходим повторный вход в систему."
        case .requiresRecentLogin:
            return "Вам необходимо войти в систему снова перед этой операцией. Это необходимо для подтверждения вашей личности и защиты вашего аккаунта от несанкционированного доступа. Пожалуйста, выйдите из системы и войдите снова, чтобы продолжить."
        case .emailAlreadyInUse:
            return "Электронная почта уже используется другим пользователем. Пожалуйста, войдите с помощью этой электронной почты или используйте другую."
        case .invalidEmail:
            return "Предоставленный адрес электронной почты недействителен или не соответствует формату стандартного адреса электронной почты. Убедитесь, что вы вводите адрес электронной почты в правильном формате."
        case .weakPassword:
            return "Введенный пароль слишком слабый. Пожалуйста, введите более сложный пароль и попробуйте снова."
        case .networkError:
            return "Произошла сетевая ошибка. Пожалуйста, проверьте свое сетевое подключение и попробуйте снова."
        case .keychainError:
            return "Проблема с доступом к хранилищу учетных данных на устройстве. Пожалуйста, попробуйте снова или перезагрузите устройство."
        case .userNotFound:
            return "Адрес электронной почты не связан с существующим аккаунтом. Убедитесь, что вы вводите адрес электронной почты, который был использован при создании аккаунта."
        case .wrongPassword:
            return "Предоставленный пароль неверен. Убедитесь, что вы вводите правильный пароль для своего аккаунта."
        case .expiredActionCode:
            return "Код действия истек. Пожалуйста, запросите новый код и попробуйте снова."
        case .invalidCredential:
            return "Предоставленные учетные данные недействительны. Пожалуйста, проверьте свои учетные данные и попробуйте снова. Если проблема не решается, вы можете сбросить свой пароль или обратиться в службу поддержки."
        case .invalidRecipientEmail:
            return "Адрес электронной почты получателя недействителен. Пожалуйста, проверьте адрес и попробуйте снова."
        case .missingEmail:
            return "Адрес электронной почты отсутствует. Пожалуйста, предоставьте действующий адрес электронной почты и попробуйте снова."
        case .userDisabled:
            return "Пользователь был отключен. Свяжитесь с администратором вашего системы или службой поддержки."
        case .invalidSender:
            return "Отправитель, указанный в запросе, недействителен. Пожалуйста, проверьте данные отправителя и попробуйте снова."
        case .accountExistsWithDifferentCredential:
            return "Учетные данные уже используются с другим аккаунтом. Пожалуйста, используйте другой метод входа или используйте эти учетные данные для входа в существующий аккаунт."
        case .operationNotAllowed:
            return "Учетные записи с выбранным поставщиком удостоверений не включены. Пожалуйста, обратитесь к администратору для получения помощи."
        default:
            return "Ошибка AuthErrorCode. Попробуйте еще раз."
        }
    }
    
    private func handleFirestoreError(_ nsError: NSError) -> String {
        switch nsError.code {
        case FirestoreErrorCode.cancelled.rawValue:
            return "FirestoreErrorCode. Операция была отменена. Попробуйте еще раз."
        case FirestoreErrorCode.unavailable.rawValue:
            return "FirestoreErrorCode. Сервис временно недоступен. Попробуйте позже."
        case FirestoreErrorCode.invalidArgument.rawValue:
            return "FirestoreErrorCode. Переданы недопустимые аргументы. Пожалуйста, проверьте данные и попробуйте еще раз."
        case FirestoreErrorCode.unknown.rawValue:
                return "Произошла неизвестная ошибка. Пожалуйста, попробуйте снова."
        case FirestoreErrorCode.deadlineExceeded.rawValue:
            return "FirestoreErrorCode. Превышен срок выполнения операции. Пожалуйста, повторите попытку."
        case FirestoreErrorCode.notFound.rawValue:
            return "FirestoreErrorCode. Данные не найдены. Проверьте правильность введенных данных и попробуйте снова."
        case FirestoreErrorCode.alreadyExists.rawValue:
            return "FirestoreErrorCode. Данные уже существуют. Пожалуйста, проверьте данные и попробуйте снова."
        case FirestoreErrorCode.permissionDenied.rawValue:
            return "FirestoreErrorCode. Доступ запрещен. Проверьте разрешения и попробуйте снова."
        case FirestoreErrorCode.resourceExhausted.rawValue:
            return "FirestoreErrorCode. Ресурсы исчерпаны. Попробуйте позже."
        case FirestoreErrorCode.failedPrecondition.rawValue:
            return "FirestoreErrorCode. Не выполнено предварительное условие. Пожалуйста, проверьте данные и повторите попытку."
        case FirestoreErrorCode.aborted.rawValue:
            return "FirestoreErrorCode. Операция была прервана. Пожалуйста, попробуйте еще раз."
        case FirestoreErrorCode.outOfRange.rawValue:
            return "FirestoreErrorCode. Значение выходит за пределы допустимого диапазона. Проверьте данные и попробуйте снова."
        case FirestoreErrorCode.unimplemented.rawValue:
            return "FirestoreErrorCode. Функция не реализована. Пожалуйста, попробуйте позже."
        case FirestoreErrorCode.internal.rawValue:
            return "FirestoreErrorCode. Произошла внутренняя ошибка сервера. Пожалуйста, повторите попытку позже."
        case FirestoreErrorCode.dataLoss.rawValue:
            return "FirestoreErrorCode. Произошла потеря данных. Пожалуйста, попробуйте снова."
        case FirestoreErrorCode.unauthenticated.rawValue:
            return "FirestoreErrorCode. Пользователь не аутентифицирован. Пожалуйста, войдите в систему и попробуйте снова."
        default:
            return "Ошибка FirestoreErrorCode. Попробуйте еще раз."
        }
    }
    
    private func handleStorageError(_ code: StorageErrorCode) -> String {
        switch code {
        case .objectNotFound:
            return "StorageErrorCode. Файл не найден. Проверьте путь и попробуйте снова."
        case .bucketNotFound:
            return "StorageErrorCode. Указанное хранилище не найдено. Проверьте настройки и попробуйте снова."
        case .projectNotFound:
            return "StorageErrorCode. Указанный проект не найден. Проверьте настройки проекта и попробуйте снова."
        case .quotaExceeded:
            return "StorageErrorCode. Превышена квота. Попробуйте позже."
        case .unauthenticated:
            return "StorageErrorCode. Необходимо войти в систему для выполнения этой операции. Пожалуйста, аутентифицируйтесь и попробуйте снова."
        case .unauthorized:
            return "StorageErrorCode. У вас нет разрешения на доступ к этому ресурсу."
        case .retryLimitExceeded:
            return "StorageErrorCode. Превышено количество попыток. Пожалуйста, попробуйте позже."
        case .nonMatchingChecksum:
            return "StorageErrorCode. Контрольная сумма не совпадает. Повторите загрузку файла."
        case .downloadSizeExceeded:
            return "StorageErrorCode. Размер загрузки превышает установленный предел. Попробуйте загрузить файл меньшего размера."
        case .cancelled:
            return "StorageErrorCode. Операция была отменена. Попробуйте еще раз."
        case .invalidArgument:
            return "StorageErrorCode. Переданы недопустимые аргументы. Пожалуйста, проверьте данные и попробуйте снова."
        case .unknown:
            return "StorageErrorCode. Произошла неизвестная ошибка. Пожалуйста, попробуйте снова."
        case .bucketMismatch:
            return "StorageErrorCode. Неправильное хранилище. Проверьте настройки и попробуйте снова."
        case .internalError:
            return "StorageErrorCode. Внутренняя ошибка сервера. Пожалуйста, попробуйте позже."
        case .pathError:
            return "StorageErrorCode. Ошибка пути. Проверьте путь и попробуйте снова."
        @unknown default:
            return "Ошибка StorageErrorCode. Попробуйте еще раз."
        }
    }
}


    



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
