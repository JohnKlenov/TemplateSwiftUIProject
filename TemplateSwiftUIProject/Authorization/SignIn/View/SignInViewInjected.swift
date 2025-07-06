//
//  SignInViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 6.07.25.
//

import SwiftUI

struct SignInViewInjected: View {
    @StateObject private var viewModel: SignInViewModel
    
    init(authorizationManager: AuthorizationManager) {
        print("init SignInViewInjected")
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: SignInViewModel(
                authorizationManager: authorizationManager
            )
        )
    }
    
    var body: some View {
        SignInView(viewModel: viewModel)
    }
}
