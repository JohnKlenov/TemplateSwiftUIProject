//
//  ErrorsFB.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

import Foundation

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

