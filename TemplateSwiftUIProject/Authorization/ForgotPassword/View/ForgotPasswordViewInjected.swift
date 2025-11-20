//
//  ForgotPasswordViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.11.25.
//

import SwiftUI

struct ForgotPasswordViewInjected: View {
    @StateObject private var viewModel: ForgotPasswordViewModel
    
    init(authorizationManager: AuthorizationManager) {
        print("init ForgotPasswordViewInjected")
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: ForgotPasswordViewModel(
                authorizationManager: authorizationManager
            )
        )
    }
    
    var body: some View {
        ForgotPasswordView(viewModel: viewModel)
    }
}
