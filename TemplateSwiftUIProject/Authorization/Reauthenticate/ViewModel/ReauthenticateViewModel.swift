//
//  ReauthenticateViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//

import Combine
import SwiftUI

final class ReauthenticateViewModel: ObservableObject {
    
    // MARK: - Input
    @Published var email: String = ""
    @Published var password: String = ""
    
    // MARK: - Validation errors
    @Published var emailError: String?
    @Published var passwordError: String?
    
    // MARK: - State
    @Published var reauthState: AuthorizationManager.State = .idle
    
    // MARK: - Provider
    @Published private(set) var providerID: String?
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    // MARK: - Init
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        setupSubscriptions()
    }
    
    // MARK: - Subscriptions
    private func setupSubscriptions() {
        // Подписка на состояние
        authorizationManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.reauthState = state
            }
            .store(in: &cancellables)
        
        // Подписка на провайдер
        authorizationManager.$primaryProvider
            .receive(on: DispatchQueue.main)
            .sink { [weak self] provider in
                guard let self = self else { return }
                
                // ⚡️ Показываем UI только если провайдер есть и пользователь перманентный
                if let provider = provider,
                   let user = self.authorizationManager.currentAuthUser,
                   !user.isAnonymous {
                    self.providerID = provider
                    print("ReauthenticateViewModel получил providerID:", provider)
                } else {
                    // Сбрасываем, если аноним или nil
                    self.providerID = nil
                    print("ℹ️ ReauthenticateViewModel: анонимный или nil user — UI для реаутентификации не показываем")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
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
    
    // MARK: - Actions
    func reauthenticate() {
        guard let providerID = providerID else {
            print("⚠️ Нет провайдера для реаутентификации")
            return
        }
        
        switch providerID {
        case "password":
            authorizationManager.confirmIdentity(email: email, password: password)
        case "google.com":
            // TODO: вызвать Google flow
            print("⚠️ Реаутентификация через Google пока не реализована")
        case "apple.com":
            // TODO: вызвать Apple flow
            print("⚠️ Реаутентификация через Apple пока не реализована")
        default:
            print("⚠️ Неизвестный провайдер:", providerID)
        }
    }
    
    deinit {
        cancellables.removeAll()
        print("deinit ReauthenticateViewModel")
    }
}




// MARK: - before get provaider 

//class ReauthenticateViewModel: ObservableObject {
//    
//    @Published var email: String = ""
//    @Published var password: String = ""
//    
//    @Published var emailError: String?
//    @Published var passwordError: String?
//    
//    @Published var reauthState: AuthorizationManager.State = .idle
////    @Published var showAnonymousWarning = false
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
//        print("init ReauthenticateViewModel")
//        
//        authorizationManager.$state
//            .handleEvents(receiveOutput: { print("→ ReauthenticateViewModel подписка получила:", $0) })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.reauthState = state
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
//    func reauthenticate() {
//        authorizationManager.confirmIdentity(email: email, password: password)
//    }
//    
//    deinit {
//        cancellables.removeAll()
//        print("deinit ReauthenticateViewModel")
//    }
//}

