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
    
    private let profileService:FirestoreProfileService
    private let storageProfileService: StorageProfileServiceProtocol
    private let authService: AuthenticationServiceProtocol
    
    private let crudManager: CRUDSManager
    private let authorizationManager: AuthorizationManager
    private let userInfoCellManager: UserInfoCellManager
    private let userInfoEditManager:UserInfoEditManager
    private let homeManager: HomeManager
    private let galleryManager: GalleryManager

    init() {
        let userProvider: CurrentUserProvider = FirebaseAuthUserProvider()
        
        let service = AuthorizationService(userProvider: userProvider)
        self.authorizationManager = AuthorizationManager(service: service, errorHandler: SharedErrorHandler())
        
        let trackerService = AnonAccountTrackerService()
        self.authService = AuthenticationService(trackerService: trackerService)
        
        self.profileService = FirestoreProfileService()
        self.storageProfileService = StorageProfileService()
        
        self.userInfoEditManager = UserInfoEditManager(firestoreService: profileService, storageService: storageProfileService, errorHandler: SharedErrorHandler(), userProvider: userProvider)
        
        self.userInfoCellManager = UserInfoCellManager(profileService: profileService, userProvider: userProvider, errorHandler: SharedErrorHandler())
        
        self.crudManager = CRUDSManager(
            authService: AuthService(),
            errorHandler: ErrorDiagnosticsCenter(),
            databaseService: FirestoreDatabaseCRUDService()
        )
        
        self.homeManager = HomeManager(
            authService: authService,
            firestoreService: FirestoreCollectionObserverService(errorHandler: ErrorDiagnosticsCenter()),
            errorHandler: ErrorDiagnosticsCenter(),
            alertManager: AlertManager.shared
        )
        
        self.galleryManager = GalleryManager(
            firestoreService: FirestoreGetService(),
            errorHandler: SharedErrorHandler(),
            alertManager: AlertManager.shared
        )
        
        print("init ViewBuilderService")
    }
    
    deinit {
        print("deinit ViewBuilderService")
    }
    
    
    @ViewBuilder
    func homeViewBuild(page: HomeFlow) -> some View {
        switch page {
        case .home:
            HomeContentViewInjected( managerCRUDS: crudManager, homeManager: homeManager )
        case .bookDetails(let book):
            BookDetailsViewInjected( managerCRUDS: crudManager, book: book )
        case .someHomeView:
            SomeView()
        }
    }
    
    @ViewBuilder 
    func galleryViewBuild(page: GalleryFlow) -> some View {
        switch page {
        case .gallery:
            GalleryContentViewInjected(galleryManager: galleryManager)
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
            ChangeLanguageViewInjected()
        case .aboutUs:
            SomeView()
        case .createAccount:
            SignUpViewInjected(authorizationManager: authorizationManager)
        case .account:
            ContentAccountViewInjected(
                authorizationManager: authorizationManager,
                userInfoCellManager: userInfoCellManager
            )
        case .login:
            SignInViewInjected(authorizationManager: authorizationManager)
        case .reauthenticate:
            ReauthenticateViewInjected(authorizationManager: authorizationManager)
        case .forgotPassword:
            ForgotPasswordViewInjected(authorizationManager: authorizationManager)   
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



// before refactoring View → ViewModel → Manager → Service


//@ViewBuilder
//func homeViewBuild(page: HomeFlow) -> some View {
//    switch page {
//    case .home:
//        HomeContentView(managerCRUDS: crudManager, authenticationService: authService)
//    case .bookDetails(let book):
//        BookDetailsView(managerCRUDS: crudManager, book: book)
//    case .someHomeView:
//        SomeView()
//    }
//}


// before ForgotPasswordView

//@ViewBuilder
//func accountViewBuild(page: AccountFlow) -> some View {
//    switch page {
//    case .userInfo:
//        SomeView()
//    case .language:
//        SomeView()
//    case .aboutUs:
//        SomeView()
//    case .createAccount:
//        SignUpViewInjected(authorizationManager: authorizationManager)
//    case .account:
//        ContentAccountViewInjected(authorizationManager: authorizationManager, userInfoCellManager: userInfoCellManager)
//    case .login:
//        SignInViewInjected(authorizationManager: authorizationManager)
//    case .reauthenticate:
//        ReauthenticateViewInjected(authorizationManager: authorizationManager)
//    case .userInfoEdit(let profile):
//        UserInfoEditViewInjected(editManager: userInfoEditManager, profile: profile)
//    }
//}
