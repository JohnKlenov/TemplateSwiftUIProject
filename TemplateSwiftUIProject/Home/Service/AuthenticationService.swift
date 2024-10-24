//
//  AuthenticationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//


import Combine
import SwiftUI
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
    func reset()
}


class AuthenticationService: AuthenticationServiceProtocol {
    
    private var authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        addListeners()
    }
    
    private func addListeners() {
        
        if let handle = aythenticalSateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        aythenticalSateHandler = Auth.auth().addStateDidChangeListener({ [weak self]  _, user in
            
            guard let self = self else { return }
            
            if let user = user {
                self.authenticationPublisher.send(.success(user.uid))
            } else {
                self.createAnonymousUser()
            }
        })
    }
    
    private func createAnonymousUser() {
            Auth.auth().signInAnonymously { [weak self] authResult, error in
                guard let self = self else { return }
                guard let _ = authResult?.user else {
                    if let error = error {
                        self.authenticationPublisher.send(.failure(error))
                    } else {
                        self.authenticationPublisher.send(.failure(NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])))
                    }
                    return
                }
                // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
            }
        }
    
    func authenticate() -> AnyPublisher<Result<String, any Error>, Never> {
        return authenticationPublisher.eraseToAnyPublisher()
    }
    
    func reset() {
        authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
        addListeners()
    }
}



