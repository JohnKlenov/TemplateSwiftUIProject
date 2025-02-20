//
//  Localized.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.02.25.
//

import Foundation

enum Localized {
    // MARK: - Tab Bar
    enum TabBar {
        static let home = localized("tab.home")
        static let gallery = localized("tab.gallery")
        static let profile = localized("tab.profile")
    }
    
    // MARK: - Home View Navigation Stack
    
    //Home view
    enum Home {
        static let title = localized("home.title")
        static let addButton = localized("home.add_button")
        static let loading = localized("home.loading")
        enum BookRowView {
            static let swipeActionsDelete = localized("home.bookRowView.swipeActions_delete")
        }
        enum ContentErrorView {
            static let title = localized("home.contentErrorView.title")
            static let description = localized("home.contentErrorView.description")
            static let refreshButton = localized("home.contentErrorView.refresh_button")
        }
    }
    
    //BookDetailsView
    enum BookDetailsView {
            static let title = localized("book_details.title")
            static let description = localized("book_details.description")
            static let author = localized("book_details.author")
            static let goToSomeViewButton = localized("book_details.go_to_some_view_button")
            static let navigationTitle = localized("book_details.navigation_title")
            static let editButton = localized("book_details.edit_button")
        }
    
    //BookEditView
    enum BookEditView {
        static let cancel = localized("book_edit.cancel")
        static let done = localized("book_edit.done")
        static let save = localized("book_edit.save")
        static let newBook = localized("book_edit.new_book")
        static let bookSection = localized("book_edit.book_section")
        static let title = localized("book_edit.title")
        static let description = localized("book_edit.description")
        static let pathImage = localized("book_edit.path_image")
        static let authorSection = localized("book_edit.author_section")
        static let author = localized("book_edit.author")
        static let deleteBook = localized("book_edit.delete_book")
        static let confirmationDialog = localized("book_edit.confirmation_dialog")
    }
    
    // MARK: - Profile Navigation Stack
    // (Добавьте локализованные строки для Profile, если они будут)
    
    // MARK: - Gallery Navigation Stack
    // (Добавьте локализованные строки для Gallery, если они будут)
    
    // MARK: - Alerts - Global
    enum Alerts {
        static let title = localized("alert.title")
        static let defaultMessage = localized("alert.default_message")
    }
    
    
    // MARK: - Firebase Errors -
    
    enum DescriptionOfOperationError {
        static let addingOrChangingBook = localized("error.adding_or_changing_book")
        static let deletingBook = localized("error.deleting_book")
        static let authentication = localized("error.authentication")
        static let database = localized("error.database")
    }
    
    // MARK: - Custom Firebase Error -
    
    enum FirebaseEnternalError {
            static var defaultError = localized("error.custom_firebase.default_error")
            static var invalidCollectionPath = localized("error.custom_firebase.invalid_collection_path")
            static var failedDeployOptionalError = localized("error.custom_firebase.failed_deploy_optional_error")
            static var failedDeployOptionalID = localized("error.custom_firebase.failed_deploy_optional_id")
            static var jsonConversionFailed = localized("error.custom_firebase.json_conversion_failed")
            static var notSignedIn = localized("error.custom_firebase.not_signed_in")
        }
    
    // MARK: - Auth Errors
    enum Auth {
        static let providerAlreadyLinked = localized("error.auth.provider_already_linked")
        static let credentialAlreadyInUse = localized("error.auth.credential_already_in_use")
        static let tooManyRequests = localized("error.auth.too_many_requests")
        static let userTokenExpired = localized("error.auth.user_token_expired")
        static let invalidUserToken = localized("error.auth.invalid_user_token")
        static let userMismatch = localized("error.auth.user_mismatch")
        static let requiresRecentLogin = localized("error.auth.requires_recent_login")
        static let emailAlreadyInUse = localized("error.auth.email_already_in_use")
        static let invalidEmail = localized("error.auth.invalid_email")
        static let weakPassword = localized("error.auth.weak_password")
        static let networkError = localized("error.auth.network_error")
        static let keychainError = localized("error.auth.keychain_error")
        static let userNotFound = localized("error.auth.user_not_found")
        static let wrongPassword = localized("error.auth.wrong_password")
        static let expiredActionCode = localized("error.auth.expired_action_code")
        static let invalidCredential = localized("error.auth.invalid_credential")
        static let invalidRecipientEmail = localized("error.auth.invalid_recipient_email")
        static let missingEmail = localized("error.auth.missing_email")
        static let userDisabled = localized("error.auth.user_disabled")
        static let invalidSender = localized("error.auth.invalid_sender")
        static let accountExistsWithDifferentCredential = localized("error.auth.account_exists_with_different_credential")
        static let operationNotAllowed = localized("error.auth.operation_not_allowed")
        static let generic = localized("error.auth.generic")
    }
    
    // MARK: - Firestore Errors
    enum Firestore {
        static let cancelled = localized("error.firestore.cancelled")
        static let unavailable = localized("error.firestore.unavailable")
        static let invalidArgument = localized("error.firestore.invalid_argument")
        static let unknown = localized("error.firestore.unknown")
        static let deadlineExceeded = localized("error.firestore.deadline_exceeded")
        static let notFound = localized("error.firestore.not_found")
        static let alreadyExists = localized("error.firestore.already_exists")
        static let permissionDenied = localized("error.firestore.permission_denied")
        static let resourceExhausted = localized("error.firestore.resource_exhausted")
        static let failedPrecondition = localized("error.firestore.failed_precondition")
        static let aborted = localized("error.firestore.aborted")
        static let outOfRange = localized("error.firestore.out_of_range")
        static let unimplemented = localized("error.firestore.unimplemented")
        static let internalError = localized("error.firestore.internal")
        static let dataLoss = localized("error.firestore.data_loss")
        static let unauthenticated = localized("error.firestore.unauthenticated")
        static let generic = localized("error.firestore.generic")
    }
    
    // MARK: - Storage Errors
    enum Storage {
        static let objectNotFound = localized("error.storage.object_not_found")
        static let bucketNotFound = localized("error.storage.bucket_not_found")
        static let projectNotFound = localized("error.storage.project_not_found")
        static let quotaExceeded = localized("error.storage.quota_exceeded")
        static let unauthenticated = localized("error.storage.unauthenticated")
        static let unauthorized = localized("error.storage.unauthorized")
        static let retryLimitExceeded = localized("error.storage.retry_limit_exceeded")
        static let nonMatchingChecksum = localized("error.storage.non_matching_checksum")
        static let downloadSizeExceeded = localized("error.storage.download_size_exceeded")
        static let cancelled = localized("error.storage.cancelled")
        static let invalidArgument = localized("error.storage.invalid_argument")
        static let unknown = localized("error.storage.unknown")
        static let bucketMismatch = localized("error.storage.bucket_mismatch")
        static let internalError = localized("error.storage.internal_error")
        static let pathError = localized("error.storage.path_error")
        static let generic = localized("error.storage.generic")
    }
    
    // MARK: - Realtime Database Errors
    enum RealtimeDatabase {
        static let networkError = localized("error.realtime_database.network_error")
        static let timeout = localized("error.realtime_database.timeout")
        static let operationCancelled = localized("error.realtime_database.operation_cancelled")
        static let hostNotFound = localized("error.realtime_database.host_not_found")
        static let cannotConnectToHost = localized("error.realtime_database.cannot_connect_to_host")
        static let networkConnectionLost = localized("error.realtime_database.network_connection_lost")
        static let resourceUnavailable = localized("error.realtime_database.resource_unavailable")
        static let authenticationCancelled = localized("error.realtime_database.authentication_cancelled")
        static let authenticationRequired = localized("error.realtime_database.authentication_required")
        static let generic = localized("error.realtime_database.generic")
    }
    
    private static func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
