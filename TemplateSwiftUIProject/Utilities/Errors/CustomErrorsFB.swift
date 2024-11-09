//
//  ErrorsFB.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

import Foundation


enum PathFirestoreError: Error, LocalizedError {
    case invalidCollectionPath
    case failedDeployOptionalError
    
    var errorDescription: String {
        switch self {
        case .invalidCollectionPath:
            return "The provided path is invalid. It must be a path to a collection, not a document."
        case .failedDeployOptionalError:
            return "Failed to deploy optional error"
        }
    }
}

