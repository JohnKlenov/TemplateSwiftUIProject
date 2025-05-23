//
//  SignInViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.05.25.
//

import SwiftUI

class SignInViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    @Published var isSignIn: Bool = false
    
    // Вычисляемое свойство для проверки валидности данных
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
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
    /// этот метод должен обращаться к сервису(Auth.createAccount) который существует в памяти независимо от SignUpViewModel
    /// то есть существует в памяти на протяжении всего life cycle App
    /// и из этого сервиса он должен дерагть GlobalAllert с оповещение success/failed
    func signInUser(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            completion(true)
        }
    }
}

