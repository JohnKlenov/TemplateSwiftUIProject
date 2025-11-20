//
//  SignInViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.05.25.
//

import SwiftUI
import Combine


class SignInViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    @Published var signInState: AuthorizationManager.State = .idle
    @Published var isAuthOperationInProgress: Bool = false
    
    @Published var showAnonymousWarning = false
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    // Вычисляемое свойство для проверки валидности данных
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        print("init SignInViewModel")
        
        authorizationManager.$signInState
            .handleEvents(receiveOutput: { print("→ SignInViewModel подписка получила:", $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.signInState = state
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
    
    func signIn() {
        authorizationManager.signIn(email: email, password: password)
    }
    
    func trySignInWithWarningIfNeeded() {
        if authorizationManager.isUserAnonymous {
            showAnonymousWarning = true
        } else {
            signIn()
        }
    }

    func confirmAnonymousSignIn() {
        showAnonymousWarning = false
        signIn()
    }
    
    deinit {
        cancellables.removeAll()
        print("deinit SignInViewModel")
    }
}



// MARK: - before Local states


//import SwiftUI
//import Combine
//
//
//class SignInViewModel: ObservableObject {
//    @Published var email: String = ""
//    @Published var password: String = ""
//    
//    @Published var emailError: String?
//    @Published var passwordError: String?
//    
////    @Published var isSignIn: Bool = false
//    @Published var signInState: AuthorizationManager.State = .idle
//    @Published var showAnonymousWarning = false
//    
//    private let authorizationManager: AuthorizationManager
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Вычисляемое свойство для проверки валидности данных
//    var isValid: Bool {
//        !email.isEmpty && !password.isEmpty
//    }
//    
//    init(authorizationManager: AuthorizationManager) {
//        self.authorizationManager = authorizationManager
//        print("init SignInViewModel")
//        
//        authorizationManager.$state
//            .handleEvents(receiveOutput: { print("→ SignInViewModel подписка получила:", $0) })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.signInState = state
//            }
//            .store(in: &cancellables)
//    }
//    
//    func updateValidationEmail() {
//        if email.isEmpty {
//            emailError = Localized.ValidSignUp.emailEmpty
//        } else if !email.isValidEmail {
//            emailError = Localized.ValidSignUp.emailInvalid
//        } else {
//            emailError = nil
//        }
//    }
//    
//    func updateValidationPassword() {
//        if password.isEmpty {
//            passwordError = Localized.ValidSignUp.passwordEmpty
//        } else {
//            passwordError = nil
//        }
//    }
//    
//    func signIn() {
//        print("did tap signIn for SignInViewModel")
//        authorizationManager.signIn(email: email, password: password)
//    }
//    
//    func trySignInWithWarningIfNeeded() {
//        if authorizationManager.isUserAnonymous {
//            showAnonymousWarning = true
//        } else {
//            signIn()
//        }
//    }
//
//    func confirmAnonymousSignIn() {
//        showAnonymousWarning = false
//        signIn()
//    }
//    
//    deinit {
//        cancellables.removeAll()
//        print("deinit SignInViewModel")
//    }
//}
