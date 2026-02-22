//
//  ErrorContext.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 3.02.26.
//

import Foundation

enum ErrorContext: String {

    // MARK: - Managers -

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
    
    // MARK: - GalleryManager
    case GalleryManager_fetchData_FirestoreGetService
    
    // MARK: - UserInfoCellManager
    case UserInfoCellManager_loadUserProfile_profileService_fetchProfile
    
    
    
    
    // MARK: - Services -
    
    
    // MARK: - FirestoreCollectionObserverService
    case FirestoreCollectionObserverService_decodeDocument

    // MARK: - AnonAccountTrackerService
    case AnonAccountTrackerService_updateLastActive
    
    // MARK: - FirestoreGetService
    case FirestoreGetService_fetchMalls
    case FirestoreGetService_fetchShops
    case FirestoreGetService_fetchPopularProducts

}
