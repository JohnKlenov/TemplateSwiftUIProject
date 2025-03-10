//
//  ViewBuilderService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

class ViewBuilderService: ObservableObject {
    var crudManager: CRUDSManager
    
    init() {
        self.crudManager = CRUDSManager(
            authService: AuthService(),
            errorHandler: SharedErrorHandler(),
            databaseService: FirestoreDatabaseCRUDService()
        )
    }
    
    @ViewBuilder func homeViewBuild(page: HomeFlow) -> some View {
        switch page {
        case .home:
            HomeContentView(managerCRUDS: crudManager)
        case .bookDetails(let bookID):
            BookDetailsView(managerCRUDS: crudManager, bookID: bookID)
        case .someHomeView:
            SomeView()
        }
    }
    
    @ViewBuilder func galleryViewBuild(page: GalleryFlow) -> some View {
        switch page {
        case .gallery:
            GalleryContentView()
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
