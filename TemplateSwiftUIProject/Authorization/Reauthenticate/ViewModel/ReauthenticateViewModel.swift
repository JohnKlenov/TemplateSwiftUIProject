//
//  ReauthenticateViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//

import Combine

class ReauthenticateViewModel: ObservableObject {

    private let authorizationManager: AuthorizationManager
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        print("init ReauthenticateViewModel")
    }
    
//    func reauthenticate() {
//        authorizationManager.reauthenticate(email: email, password: password)
//    }
}

