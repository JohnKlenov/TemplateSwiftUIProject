//
//  ContentAccountViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//


import SwiftUI
//profileService: FirestoreProfileService, errorHandler: ErrorHandlerProtocol
struct ContentAccountViewInjected: View {
    @StateObject private var viewModel: ContentAccountViewModel
    
    init(authorizationManager: AuthorizationManager, userInfoCellManager: UserInfoCellManager ) {
        _viewModel = StateObject(wrappedValue: ContentAccountViewModel(authorizationManager: authorizationManager, userInfoCellManager: userInfoCellManager))
    }
    
    var body: some View {
        let _ = Self._printChanges()
        ContentAccountView(viewModel: viewModel)
    }
}


