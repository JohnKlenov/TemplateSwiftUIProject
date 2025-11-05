//
//  ReauthenticateViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//


import SwiftUI

struct ReauthenticateViewInjected: View {
    @StateObject private var viewModel: ReauthenticateViewModel
    
    init(authorizationManager: AuthorizationManager) {
        print("init ReauthenticateViewInjected")
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: ReauthenticateViewModel(
                authorizationManager: authorizationManager
            )
        )
    }
    
    var body: some View {
        ReauthenticateView(viewModel: viewModel)
    }
}
