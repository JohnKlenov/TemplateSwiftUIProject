//
//  ErrorsFB.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

import Foundation


enum DatabaseEnternalAppError: Error, LocalizedError {
    case invalidCollectionPath
    case failedDeployOptionalError
    case failedDeployOptionalID
    case jsonConversionFailed
    
    var errorDescription: String {
        switch self {
        case .invalidCollectionPath:
            return "The provided path is invalid. It must be a path to a collection, not a document."
        case .failedDeployOptionalError:
            return "Failed to deploy optional error"
        case .failedDeployOptionalID:
            return "Failed to deploy optional ID"
        case .jsonConversionFailed:
            return "Json conversion failed"
        }
    }
}

