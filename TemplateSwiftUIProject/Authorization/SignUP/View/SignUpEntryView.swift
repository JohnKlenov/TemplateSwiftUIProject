//
//  SignUpEntryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.06.25.
//

// SignUpEntryView.swift
import SwiftUI

struct SignUpEntryView: View {
    @EnvironmentObject private var authManager: AuthorizationManager
    
    var body: some View {
        SignUpView(
            viewModel: SignUpViewModel(authorizationManager: authManager)
        )
    }
}

