//
//  ErrorContext.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 3.02.26.
//

import Foundation

enum ErrorContext: String {

    // MARK: - CRUDSManager

    case CRUDSManager_updateOrAddBook_authService_getCurrentUserID
    case CRUDSManager_updateOrAddBook_databaseService_addBook
    case CRUDSManager_updateOrAddBook_databaseService_updateBook

    case CRUDSManager_removeBook_authService_getCurrentUserID
    case CRUDSManager_removeBook_databaseService_removeBook

    case CRUDSManager_addBook_databaseService_addBook
    case CRUDSManager_updateBook_databaseService_updateBook
    case CRUDSManager_removeBookInternal_databaseService_removeBook
    
    
    // MARK: - HomeManager
    case HomeManager_observeBooks_authService_authenticate
    case HomeManager_observeBooks_firestoreService_observeCollection
}
