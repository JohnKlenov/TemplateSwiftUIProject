//
//  ErrorsFB.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//


import Foundation

/**
 AppInternalError — единый тип внутренних ошибок приложения.

 Этот enum одновременно работает как:
  • обычная Swift‑ошибка (Error)
  • полноценный NSError (через CustomNSError)
  • источник локализованного текста (через LocalizedError)

 Зачем это нужно:

 1. LocalizedError
    Позволяет задать локализованный текст ошибки через `errorDescription`.
    Swift автоматически делает:
        error.localizedDescription → errorDescription
    Поэтому UI всегда получает корректный локализованный текст.

 2. CustomNSError
    Делает Swift‑ошибку полностью совместимой с NSError:
        • задаёт собственный domain
        • задаёт уникальный code
        • помещает localizedDescription в userInfo
    Благодаря этому Crashlytics корректно группирует ошибки
    и показывает domain/code/description.

 3. Почему в ErrorDiagnosticsCenter теперь используется только один путь:
        if nsError.domain == AppInternalError.errorDomain

    Раньше приходилось проверять два варианта:
        • Swift enum (AppInternalError)
        • NSError (после bridging)

    Теперь это не требуется, потому что Swift автоматически преобразует
    любой Error → NSError при прохождении через:
        • Combine
        • async/await
        • Firebase SDK
        • Foundation API
        • замыкания, возвращающие NSError

    Благодаря CustomNSError каждая AppInternalError‑ошибка
    уже содержит корректный domain/code/userInfo.
    Поэтому ErrorDiagnosticsCenter может работать только через NSError,
    не проверяя тип enum напрямую.

 В итоге:
  • UI всегда получает локализованный текст
  • Crashlytics получает domain + code
  • ErrorDiagnosticsCenter работает в едином формате (NSError)
  • архитектура стала проще, чище и надёжнее
 */


enum AppInternalError: Int, Error {
    case invalidCollectionPath
    case failedDeployOptionalError
    case failedDeployOptionalID
    case jsonConversionFailed
    case notSignedIn
    case defaultError
    case emptyResult
    case nilSnapshot
    case imageEncodingFailed
    case delayedConfirmation
    case staleUserSession
    case anonymousAuthFailed
}

extension AppInternalError: CustomNSError {
    static var errorDomain: String { "com.yourapp.internal" }

    var errorCode: Int { self.rawValue }

    var errorUserInfo: [String : Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }
}

extension AppInternalError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidCollectionPath:
            return Localized.AppInternalError.invalidCollectionPath
        case .failedDeployOptionalError:
            return Localized.AppInternalError.failedDeployOptionalError
        case .failedDeployOptionalID:
            return Localized.AppInternalError.failedDeployOptionalID
        case .jsonConversionFailed:
            return Localized.AppInternalError.jsonConversionFailed
        case .notSignedIn:
            return Localized.AppInternalError.notSignedIn
        case .defaultError:
            return Localized.AppInternalError.defaultError
        case .emptyResult:
            return Localized.AppInternalError.emptyResult
        case .nilSnapshot:
            return Localized.AppInternalError.nilSnapshot
        case .imageEncodingFailed:
            return Localized.AppInternalError.imageEncodingFailed
        case .delayedConfirmation:
            return Localized.AppInternalError.delayedConfirmation
        case .staleUserSession:
            return Localized.AppInternalError.staleUserSession
        case .anonymousAuthFailed:
            return Localized.AppInternalError.anonymousAuthError

        }
    }
}





// MARK: - old implemintation


enum FirebaseInternalError: Error, LocalizedError {
    case invalidCollectionPath
    case failedDeployOptionalError
    case failedDeployOptionalID
    case jsonConversionFailed
    case notSignedIn
    case defaultError
    case emptyResult
    case nilSnapshot
    case imageEncodingFailed
    case delayedConfirmation
    case staleUserSession

    var errorDescription: String? {
        switch self {
        case .invalidCollectionPath:
            return Localized.FirebaseInternalError.invalidCollectionPath
        case .failedDeployOptionalError:
            return Localized.FirebaseInternalError.failedDeployOptionalError
        case .failedDeployOptionalID:
            return Localized.FirebaseInternalError.failedDeployOptionalID
        case .jsonConversionFailed:
            return Localized.FirebaseInternalError.jsonConversionFailed
        case .notSignedIn:
            return Localized.FirebaseInternalError.notSignedIn
        case .defaultError:
            return Localized.FirebaseInternalError.defaultError
        case .emptyResult:
            return Localized.FirebaseInternalError.emptyResult
        case .nilSnapshot:
            return Localized.FirebaseInternalError.nilSnapshot
        case .imageEncodingFailed:
            return Localized.FirebaseInternalError.imageEncodingFailed
        case .delayedConfirmation:
            return Localized.FirebaseInternalError.delayedConfirmation
        case .staleUserSession:
            return Localized.FirebaseInternalError.staleUserSession
        }
    }
}


//enum FirebaseEnternalAppError: Error, LocalizedError {
//    case invalidCollectionPath
//    case failedDeployOptionalError
//    case failedDeployOptionalID
//    case jsonConversionFailed
//    case notSignedIn
//    case defaultError
//    
//    var errorDescription: String {
//        switch self {
//        case .invalidCollectionPath:
//            return "The provided path is invalid. It must be a path to a collection, not a document."
//        case .failedDeployOptionalError:
//            return "Failed to deploy optional error"
//        case .failedDeployOptionalID:
//            return "Failed to deploy optional ID"
//        case .jsonConversionFailed:
//            return "Json conversion failed"
//        case .notSignedIn:
//            return "No user is currently signed in."
//        case .defaultError:
//            return "Something went wrong. Please try again."
//        }
//    }
//}

