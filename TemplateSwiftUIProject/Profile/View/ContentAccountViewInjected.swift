//
//  ContentAccountViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//

import SwiftUI

struct ContentAccountViewInjected: View {
    @StateObject private var viewModel: ContentAccountViewModel
    
    init(authorizationManager: AuthorizationManager, profileService: FirestoreProfileService, errorHandler: ErrorHandlerProtocol) {
        _viewModel = StateObject(wrappedValue: ContentAccountViewModel(authorizationManager: authorizationManager, profileService: profileService, errorHandler: errorHandler))
    }
    
    var body: some View {
        let _ = Self._printChanges()
        ContentAccountView(viewModel: viewModel)
    }
}

