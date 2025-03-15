//
//  ErrorsFB.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

import Foundation

enum FirebaseEnternalError: Error, LocalizedError {
    case invalidCollectionPath
    case failedDeployOptionalError
    case failedDeployOptionalID
    case jsonConversionFailed
    case notSignedIn
    case defaultError
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .invalidCollectionPath:
            return Localized.FirebaseEnternalError.invalidCollectionPath
        case .failedDeployOptionalError:
            return Localized.FirebaseEnternalError.failedDeployOptionalError
        case .failedDeployOptionalID:
            return Localized.FirebaseEnternalError.failedDeployOptionalID
        case .jsonConversionFailed:
            return Localized.FirebaseEnternalError.jsonConversionFailed
        case .notSignedIn:
            return Localized.FirebaseEnternalError.notSignedIn
        case .defaultError:
            return Localized.FirebaseEnternalError.defaultError
        case .emptyResult:
            return Localized.FirebaseEnternalError.emptyResult
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

