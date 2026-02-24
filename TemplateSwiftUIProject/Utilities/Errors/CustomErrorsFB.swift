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



enum AppInternalError: Int, Error {
    case invalidCollectionPath
    case failedDeployOptionalError
    case failedDeployOptionalID
    case jsonConversionFailed
    case invalidJSONStructure
    case notSignedIn
    case defaultError
    case emptyResult
    case nilSnapshot
    case imageEncodingFailed
    case delayedConfirmation
    case staleUserSession
    case anonymousAuthFailed
    case entityDeallocated
    case profileLoadAnonymousUser
    case profileLoadMissingUID
    case missingAuthProvidersForPermanentUser
    case missingPrimaryProviderForPermanentUser


}

extension AppInternalError: CustomNSError {
    static var errorDomain: String { "com.yourapp.internal" }

    var errorCode: Int { self.rawValue }

    var errorUserInfo: [String : Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }
}

extension AppInternalError: LocalizedError {
    /// Локализованный текст для UI
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
        case .entityDeallocated:
            return Localized.AppInternalError.entityDeallocated
        case .invalidJSONStructure:
            return Localized.AppInternalError.invalidJSONStructure
        case .profileLoadAnonymousUser:
            return Localized.AppInternalError.profileLoadAnonymousUser
        case .profileLoadMissingUID:
            return Localized.AppInternalError.profileLoadMissingUID
        case .missingAuthProvidersForPermanentUser:
            return Localized.AppInternalError.missingAuthProvidersForPermanentUser
        case .missingPrimaryProviderForPermanentUser:
            return Localized.AppInternalError.missingPrimaryProviderForPermanentUser

        }
    }
}

extension AppInternalError {
    /// Англоязычное техническое описание для Crashlytics
    var technicalDescription: String {
        switch self {
        case .invalidCollectionPath:
            return "Invalid Firestore collection path"
        case .failedDeployOptionalError:
            return "Failed to unwrap optional error"
        case .failedDeployOptionalID:
            return "Failed to unwrap optional ID"
        case .jsonConversionFailed:
            return "JSON conversion failed"
        case .notSignedIn:
            return "User is not signed in"
        case .defaultError:
            return "Default internal error"
        case .emptyResult:
            return "Empty result"
        case .nilSnapshot:
            return "Snapshot is nil"
        case .imageEncodingFailed:
            return "Image encoding failed"
        case .delayedConfirmation:
            return "Avatar update delayed"
        case .staleUserSession:
            return "Stale user session"
        case .anonymousAuthFailed:
            return "Anonymous authentication failed"
        case .entityDeallocated:
            return "Object was deallocated before handling the event"
        case .invalidJSONStructure:
            return "JSON structure does not match the expected dictionary format"
        case .profileLoadAnonymousUser:
            return "Attempted to load profile for anonymous user"
        case .profileLoadMissingUID:
            return "Attempted to load profile but UID is missing"
        case .missingAuthProvidersForPermanentUser:
            return "Permanent user has no auth providers"
        case .missingPrimaryProviderForPermanentUser:
            return "Permanent user has no primary auth provider"


        }
    }
}





//enum AppInternalError: Int, Error {
//    case invalidCollectionPath
//    case failedDeployOptionalError
//    case failedDeployOptionalID
//    case jsonConversionFailed
//    case notSignedIn
//    case defaultError
//    case emptyResult
//    case nilSnapshot
//    case imageEncodingFailed
//    case delayedConfirmation
//    case staleUserSession
//    case anonymousAuthFailed
//}
//
//extension AppInternalError: CustomNSError {
//    static var errorDomain: String { "com.yourapp.internal" }
//
//    var errorCode: Int { self.rawValue }
//
//    var errorUserInfo: [String : Any] {
//        [NSLocalizedDescriptionKey: self.localizedDescription]
//    }
//}
//
//extension AppInternalError: LocalizedError {
//    var errorDescription: String? {
//        switch self {
//        case .invalidCollectionPath:
//            return Localized.AppInternalError.invalidCollectionPath
//        case .failedDeployOptionalError:
//            return Localized.AppInternalError.failedDeployOptionalError
//        case .failedDeployOptionalID:
//            return Localized.AppInternalError.failedDeployOptionalID
//        case .jsonConversionFailed:
//            return Localized.AppInternalError.jsonConversionFailed
//        case .notSignedIn:
//            return Localized.AppInternalError.notSignedIn
//        case .defaultError:
//            return Localized.AppInternalError.defaultError
//        case .emptyResult:
//            return Localized.AppInternalError.emptyResult
//        case .nilSnapshot:
//            return Localized.AppInternalError.nilSnapshot
//        case .imageEncodingFailed:
//            return Localized.AppInternalError.imageEncodingFailed
//        case .delayedConfirmation:
//            return Localized.AppInternalError.delayedConfirmation
//        case .staleUserSession:
//            return Localized.AppInternalError.staleUserSession
//        case .anonymousAuthFailed:
//            return Localized.AppInternalError.anonymousAuthError
//
//        }
//    }
//}





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

