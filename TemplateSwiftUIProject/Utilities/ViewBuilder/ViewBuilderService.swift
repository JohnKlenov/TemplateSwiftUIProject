//
//  ViewBuilderService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//



// !!! идея вынести алерт и еррор менеджер из сервисов (storageProfileService и profileService ) и перенести их в (authorizationManager + userInfoEditManager)
import SwiftUI

//@MainActor
class ViewBuilderService: ObservableObject {
    
    private let crudManager: CRUDSManager
    private let authorizationManager: AuthorizationManager
    private let profileService:FirestoreProfileService
    private let storageProfileService: StorageProfileServiceProtocol
    private let userInfoEditManager:UserInfoEditManager
    private let authService: AuthenticationServiceProtocol

    init() {
        let service = AuthorizationService()
        self.authorizationManager = AuthorizationManager(service: service, errorHandler: SharedErrorHandler())
        
        let trackerService = AnonAccountTrackerService()
        self.authService = AuthenticationService(trackerService: trackerService)
        
        self.profileService = FirestoreProfileService()
        self.storageProfileService = StorageProfileService()
        let userProvider: CurrentUserProvider = FirebaseAuthUserProvider()
        self.userInfoEditManager = UserInfoEditManager(firestoreService: profileService, storageService: storageProfileService, errorHandler: SharedErrorHandler(), userProvider: userProvider)
        self.crudManager = CRUDSManager(
            authService: AuthService(),
            errorHandler: SharedErrorHandler(),
            databaseService: FirestoreDatabaseCRUDService()
        )
    }
    
    @ViewBuilder 
    func homeViewBuild(page: HomeFlow) -> some View {
        switch page {
        case .home:
            HomeContentView(managerCRUDS: crudManager, authenticationService: authService)
        case .bookDetails(let book):
            BookDetailsView(managerCRUDS: crudManager, book: book)
        case .someHomeView:
            SomeView()
        }
    }
    
    @ViewBuilder 
    func galleryViewBuild(page: GalleryFlow) -> some View {
        switch page {
        case .gallery:
            GalleryContentView()
        case .someHomeView:
            SomeView()
        }
    }
    
    
    @ViewBuilder
    func accountViewBuild(page: AccountFlow) -> some View {
        switch page {
        case .userInfo:
            SomeView()
        case .language:
            SomeView()
        case .aboutUs:
            SomeView()
        case .createAccount:
            SignUpViewInjected(authorizationManager: authorizationManager)
        case .account:
            ContentAccountViewInjected(authorizationManager: authorizationManager, profileService: profileService)
        case .login:
            SignInViewInjected(authorizationManager: authorizationManager)
        case .reauthenticate:
            ReauthenticateViewInjected(authorizationManager: authorizationManager)
        case .userInfoEdit(let profile):
            UserInfoEditViewInjected(editManager: userInfoEditManager, profile: profile)
        }
    }
    
    
    /// будут ли у нас проблемы если у нас ViewBuilderService работает на двух стеках и на одгом мы дерним buildSheet что произойдет на втором стеке он тоже дернится?
    @ViewBuilder
    func buildSheet(sheet: SheetItem) -> some View {
        sheet.content
    }
    
    @ViewBuilder
    func buildCover(cover: FullScreenItem) -> some View {
        cover.content
    }
}
