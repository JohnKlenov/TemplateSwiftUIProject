//
//  AuthService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.11.24.
//

import Foundation
import Combine
import FirebaseAuth

protocol AuthServiceProtocol {
    func getCurrentUserID() -> AnyPublisher<Result<String,Error>, Never>
}

class AuthService:AuthServiceProtocol {
    
    func getCurrentUserID() -> AnyPublisher<Result<String, any Error>, Never> {
        Future { promise in
            if let user = Auth.auth().currentUser {
                promise(.success(.success(user.uid)))
            } else {
                promise(.success(.failure(FirebaseEnternalAppError.notSignedIn)))
            }
        }
        .eraseToAnyPublisher()
    }
}
