//
//  SignUpViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.05.25.
//

import SwiftUI
import Combine

//@MainActor
class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    @Published var isRegistering: Bool = false
    @Published var isLandscape = false
    
    // Вычисляемое свойство для проверки валидности данных (без side‑эффектов)
    var isValid: Bool {
        email.isValidEmail && (password.validatePassword() == ValidationResult.success)
    }
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        
//         Подписываемся на state менеджера
        self.authorizationManager.$state
            .map { $0 == .loading }
            .removeDuplicates()
            .assign(to: \.isRegistering, on: self)
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
        switch password.validatePassword() {
        case .failure(let message):
            passwordError = message
        case .success:
            passwordError = nil
        }
    }
    
    func signUp() {

        authorizationManager.state = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.authorizationManager.state = .success
        }
    }
}
//        authorizationManager.signUp(email: email, password: password)

//    /// этот метод должен обращаться к сервису(Auth.createAccount) который существует в памяти независимо от SignUpViewModel
//    /// то есть существует в памяти на протяжении всего life cycle App
//    /// и из этого сервиса он должен дерагть GlobalAllert с оповещение success/failed
//    func registerUser(completion: @escaping (Bool) -> Void) {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//            completion(true)
//        }
//    }

// MARK: - before DI AuthorizationManager in ViewBuilderService

//import SwiftUI
//
//class SignUpViewModel: ObservableObject {
//    @Published var email: String = ""
//    @Published var password: String = ""
//    
//    @Published var emailError: String?
//    @Published var passwordError: String?
//    
//    @Published var isRegistering: Bool = false
//    @Published var isLandscape = false
//    
//    // Вычисляемое свойство для проверки валидности данных (без side‑эффектов)
//    var isValid: Bool {
//        email.isValidEmail && (password.validatePassword() == ValidationResult.success)
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
//        switch password.validatePassword() {
//        case .failure(let message):
//            passwordError = message
//        case .success:
//            passwordError = nil
//        }
//    }
//    /// этот метод должен обращаться к сервису(Auth.createAccount) который существует в памяти независимо от SignUpViewModel
//    /// то есть существует в памяти на протяжении всего life cycle App
//    /// и из этого сервиса он должен дерагть GlobalAllert с оповещение success/failed
//    func registerUser(completion: @escaping (Bool) -> Void) {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//            completion(true)
//        }
//    }
//}
