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
    
    // MARK: - UserInfoEditManager
    case UserInfoEditManager_handlePickedImageError_fromPhotoPicker
    case UserInfoEditManager_uploadAvatarAndTrack
    case UserInfoEditManager_deleteAvatarAndTrack
    case UserInfoEditManager_updateProfile

    
    // MARK: - AuthorizationManager
    case AuthorizationManager_validateUserForProfileLoading_anonymousUser
    case AuthorizationManager_validateUserForProfileLoading_missingUID
    case AuthorizationManager_subscribeToProviders_missingProviders
    case AuthorizationManager_subscribeToPrimaryProvider_missingPrimaryProvider
    case AuthorizationManager_deleteAccount_reauthenticationRequired
    case AuthorizationManager_deleteAccount_underlying
    case AuthorizationManager_signUp
    case AuthorizationManager_signUpWithGoogle
    case AuthorizationManager_signIn
    case AuthorizationManager_googleSignIn
    case AuthorizationManager_forgotPassword
    case AuthorizationManager_confirmIdentity
    case AuthorizationManager_confirmIdentityWithGoogle
    
    // MARK: - Services -
    
    
    // MARK: - FirestoreCollectionObserverService
    case FirestoreCollectionObserverService_decodeDocument

    // MARK: - AnonAccountTrackerService
    case AnonAccountTrackerService_updateLastActive
    
    // MARK: - FirestoreGetService
    case FirestoreGetService_fetchMalls
    case FirestoreGetService_fetchShops
    case FirestoreGetService_fetchPopularProducts
    
    // MARK: - StorageProfileService
    case StorageProfileService_deleteImage
    
    // MARK: - AuthorizationService
    case AuthorizationService_sendVerificationEmail
    case AuthorizationService_googleLinkAnonymous
    case AuthorizationService_googleSignInReplacingSession
    case AuthorizationService_linkPublisher
    case AuthorizationService_createUserPublisher
    case AuthorizationService_signInPublisher
}
