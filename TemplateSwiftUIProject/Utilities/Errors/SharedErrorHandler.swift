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
        case .networkError:
            return "AuthErrorCode Проблема с подключением к интернету. Проверьте ваше соединение."
        case .userNotFound:
            return "AuthErrorCode Пользователь не найден. Пожалуйста, зарегистрируйтесь."
        case .wrongPassword:
            return "AuthErrorCode Неправильный пароль. Попробуйте еще раз."
        default:
            return "Ошибка AuthErrorCode. Попробуйте еще раз."
        }
    }
    
    private func handleFirestoreError(_ nsError: NSError) -> String {
        switch nsError.code {
        case FirestoreErrorCode.cancelled.rawValue:
            return "FirestoreErrorCode Операция была отменена. Попробуйте еще раз."
        case FirestoreErrorCode.unavailable.rawValue:
            return "FirestoreErrorCode Сервис временно недоступен. Попробуйте позже."
        default:
            return "Ошибка FirestoreErrorCode. Попробуйте еще раз."
        }
    }
    
    private func handleStorageError(_ code: StorageErrorCode) -> String {
        switch code {
        case .objectNotFound:
            return "StorageErrorCode Файл не найден. Проверьте путь и попробуйте снова."
        case .unauthorized:
            return "StorageErrorCode У вас нет разрешения на доступ к этому ресурсу."
        case .quotaExceeded:
            return "StorageErrorCode Превышена квота. Попробуйте позже."
        default:
            return "Ошибка StorageErrorCode. Попробуйте еще раз."
        }
    }
}


    



// MARK: - Trash




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
