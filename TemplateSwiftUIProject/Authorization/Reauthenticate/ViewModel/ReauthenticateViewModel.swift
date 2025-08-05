//
//  ReauthenticateViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//

import Combine
import SwiftUI

class ReauthenticateViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    @Published var reauthState: AuthorizationManager.State = .idle
//    @Published var showAnonymousWarning = false
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    // Вычисляемое свойство для проверки валидности данных
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        print("init ReauthenticateViewModel")
        
        authorizationManager.$state
            .handleEvents(receiveOutput: { print("→ ReauthenticateViewModel подписка получила:", $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.reauthState = state
            }
            .store(in: &cancellables)
    }
    
    func updateValidationEmail() {
        if email.isEmpty {
            emailError = Localized.ValidSignUp.emailEmpty
        } else if !email.isValidEmail {
            emailError = Localized.ValidSignUp.emailInvalid
        } else {
            emailError = nil
        }
    }
    
    func updateValidationPassword() {
        if password.isEmpty {
            passwordError = Localized.ValidSignUp.passwordEmpty
        } else {
            passwordError = nil
        }
    }
    
    func reauthenticate() {
        authorizationManager.confirmIdentity(email: email, password: password)
    }
    
    deinit {
        cancellables.removeAll()
        print("deinit ReauthenticateViewModel")
    }
}

