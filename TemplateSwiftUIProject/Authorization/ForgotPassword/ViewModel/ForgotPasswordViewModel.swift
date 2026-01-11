//
//  ForgotPasswordViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.11.25.
//
import Combine
import SwiftUI


final class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var emailError: String?
    @Published var forgotPasswordState: AuthorizationManager.State = .idle
    @Published var isAuthOperationInProgress: Bool = false
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        
        authorizationManager.$forgotPasswordState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.forgotPasswordState = state
            }
            .store(in: &cancellables)
        
        authorizationManager.$isAuthOperationInProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inProgress in
                self?.isAuthOperationInProgress = inProgress
            }
            .store(in: &cancellables)
    }
    
    func updateValidationEmail() {
        if email.isEmpty {
            emailError = Localized.ForgotPasswordViewModel.emptyEmailError
        } else if !email.isValidEmail {
            emailError = Localized.ForgotPasswordViewModel.invalidEmailError
        } else {
            emailError = nil
        }
    }
    
    func sendResetLink() {
        authorizationManager.forgotPassword(email: email)
    }
    
    deinit {
        print("deinit ForgotPasswordViewModel")
    }
}

