//
//  ViewBuilderService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

//@MainActor
class ViewBuilderService: ObservableObject {
    let crudManager: CRUDSManager
    let authorizationManager: AuthorizationManager

    init() {
        let service = AuthorizationService()
        self.authorizationManager = AuthorizationManager(service: service, errorHandler: SharedErrorHandler())
        
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
            HomeContentView(managerCRUDS: crudManager)
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
            ContentAccountViewInjected(authorizationManager: authorizationManager)
        case .login:
            SignInViewInjected(authorizationManager: authorizationManager)
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
