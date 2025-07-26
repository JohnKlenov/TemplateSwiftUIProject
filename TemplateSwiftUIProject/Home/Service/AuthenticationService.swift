//
//  AuthenticationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//



///вызов authenticationService.authenticate() в bind() действительно произойдет раньше, чем любое authenticationPublisher.send в асинхронном коде. Это связано с порядком выполнения синхронного и асинхронного кода.
///что синхронные операции выполняются сразу, а асинхронные операции могут начаться позже. Это означает, что если вы вызываете синхронную операцию, она завершится до того, как начнется асинхронная операция.
///private var authenticationPublisher = CurrentValueSubject<Result<String, Error>, Never>(.success("nul"))
///if userId == "nul" {
///return Empty().eraseToAnyPublisher() // Завершение цепочки
///} else {
///return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")}




import Combine
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
    func getCurrentUserID() -> AnyPublisher<Result<String,Error>, Never>
    func reset()
    func signOutUser()
}



class AuthenticationService: AuthenticationServiceProtocol {
    
    private var authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
//        signOutUser()
        print("init AuthenticationService")
                addListeners()
    }
    
    private func addListeners() {
        
        if let handle = aythenticalSateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        aythenticalSateHandler = Auth.auth().addStateDidChangeListener({ [weak self]  _, user in
            print("AuthenticationService user.uid - \(user!.uid)")
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
            guard let user = authResult?.user else {
                let authenticationError = error ?? NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])
                self.authenticationPublisher.send(.failure(authenticationError))
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
    
    /// в нем нет необходимости для HomeView так как вся логика CRUDS  в  CRUDSManager
    func getCurrentUserID() -> AnyPublisher<Result<String, any Error>, Never> {
        Future { promise in
            if let user = Auth.auth().currentUser {
                promise(.success(.success(user.uid)))
            } else {
                promise(.success(.failure(FirebaseEnternalError.notSignedIn)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signOutUser() {
        do {
            try Auth.auth().signOut()
            print("Success signOut!")
        } catch let error {
            print("Failed signOut - \(error.localizedDescription)")
        }
    }
}







// MARK: - old code

//    private func createAnonymousUser() {
//        Auth.auth().signInAnonymously { [weak self] authResult, error in
//            guard let self = self else { return }
//            guard let _ = authResult?.user else {
//                if let error = error {
//
//                    self.authenticationPublisher.send(.failure(error))
//                } else {
//                    self.authenticationPublisher.send(.failure(NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])))
//                }
//                return
//            }
//            // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
//        }
//    }
