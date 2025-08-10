//
//  UserInfoViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//

import SwiftUI

struct UserInfoEditViewInjected: View {
    @StateObject private var viewModel: UserInfoEditViewModel
    
    init(authorizationManager: AuthorizationManager, profile: UserProfile) {
        print("init UserInfoEditViewInjected")
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: UserInfoEditViewModel(
                authorizationManager: authorizationManager, profile: profile
            )
        )
    }
    
    var body: some View {
        UserInfoEditView(viewModel: viewModel)
    }
}
