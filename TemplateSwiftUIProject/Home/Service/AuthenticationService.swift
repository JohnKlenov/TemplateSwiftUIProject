//
//  AuthenticationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//



// MARK: - PassthroughSubject vs CurrentValueSubject


// Почему PassthroughSubject раньше работал корректно:
//
// Вся цепочка SwiftUI → ViewModel → observeBooks() → authenticate()
// выполнялась синхронно и очень быстро, тогда как Firebase Auth
// вызывает addStateDidChangeListener callback строго асинхронно,
// в следующем runloop. Это означало, что подписка на
// authenticationPublisher почти всегда успевала установиться раньше,
// чем Firebase отправлял событие. Поэтому PassthroughSubject
// «работал», хотя теоретически мог потерять событие при редкой гонке.



// Используем CurrentValueSubject вместо PassthroughSubject, чтобы:
// 1) Хранить последнее состояние авторизации (успех/ошибка).
// 2) Реплеить это состояние новым подписчикам (HomeManager.observeBooks),
//    даже если Firebase Auth успел вызвать listener ДО того, как ViewModel
//    подписался на authenticate().
// 3) Полностью устранить гонку, при которой событие могло быть потеряно,
//    а UI зависал бы в .loading. Теперь любой новый подписчик всегда
//    получает актуальное состояние (success/failure), даже после
//    пересоздания ContentView или ViewModel.




import Combine
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
    func reset()
}

class AuthenticationService: AuthenticationServiceProtocol {
    
    private let trackerService: AnonAccountTrackerServiceProtocol
    
    // Храним последнее состояние (nil → ещё нет данных)
    private var authenticationPublisher =
        CurrentValueSubject<Result<String, Error>?, Never>(nil)
    
    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
    
    init(trackerService: AnonAccountTrackerServiceProtocol) {
        print("init AuthenticationService")
        self.trackerService = trackerService
        addListeners()
    }
    
    deinit {
        print("deinit AuthenticationService")
    }
    
    private func addListeners() {
        
        if let handle = aythenticalSateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        aythenticalSateHandler = Auth.auth().addStateDidChangeListener({ [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                if user.isAnonymous {
                    self.trackerService.updateLastActive(for: user.uid)
                }
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
                let authenticationError = error ?? AppInternalError.anonymousAuthFailed
                self.authenticationPublisher.send(.failure(authenticationError))
                return
            }
            // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
        }
    }
    
    func authenticate() -> AnyPublisher<Result<String, Error>, Never> {
        authenticationPublisher
            .compactMap { $0 } // пропускаем nil
            .eraseToAnyPublisher()
    }
    
    func reset() {
        authenticationPublisher = CurrentValueSubject<Result<String, Error>?, Never>(nil)
        addListeners()
    }
}




// MARK: - before CurrentValueSubject

//import Combine
//import FirebaseAuth
//
//protocol AuthenticationServiceProtocol {
//    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
//    func reset()
//}
//
//
//
//class AuthenticationService: AuthenticationServiceProtocol {
//    
//    private let trackerService: AnonAccountTrackerServiceProtocol
//    private var authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
//    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
//    
//    init(trackerService: AnonAccountTrackerServiceProtocol) {
//        print("init AuthenticationService")
//        self.trackerService = trackerService
//        addListeners()
//    }
//    
//    private func addListeners() {
//        
//        if let handle = aythenticalSateHandler {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//        
//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener({ [weak self]  _, user in
//            print("AuthenticationService user.uid - \(String(describing: user?.uid))")
//            guard let self = self else { return }
//            
//            if let user = user {
//                if user.isAnonymous {
//                    self.trackerService.updateLastActive(for: user.uid)
//                }
//                self.authenticationPublisher.send(.success(user.uid))
//            } else {
//                self.createAnonymousUser()
//            }
//        })
//    }
//    
//    
//    private func createAnonymousUser() {
//        Auth.auth().signInAnonymously { [weak self] authResult, error in
//            guard let self = self else { return }
//            guard let _ = authResult?.user else {
////                let authenticationError = error ?? NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])
//                let authenticationError = error ?? AppInternalError.anonymousAuthFailed
//                self.authenticationPublisher.send(.failure(authenticationError))
//                return
//            }
////            self.trackerService.createOrUpdateTracker(for: user.uid)
//            // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
//        }
//    }
//    
//    func authenticate() -> AnyPublisher<Result<String, any Error>, Never> {
//        return authenticationPublisher.eraseToAnyPublisher()
//    }
//    
//    func reset() {
//        authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
//        addListeners()
//    }
//}



//protocol AuthenticationServiceProtocol {
//    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
//    func getCurrentUserID() -> AnyPublisher<Result<String,Error>, Never>
//    func reset()
//    func signOutUser()
//}

/// в нем нет необходимости для HomeView так как вся логика CRUDS  в  CRUDSManager
//    func getCurrentUserID() -> AnyPublisher<Result<String, any Error>, Never> {
//        Future { promise in
//            if let user = Auth.auth().currentUser {
//                promise(.success(.success(user.uid)))
//            } else {
//                promise(.success(.failure(FirebaseInternalError.notSignedIn)))
//            }
//        }
//        .eraseToAnyPublisher()
//    }

//    func signOutUser() {
//        do {
//            try Auth.auth().signOut()
//            print("Success signOut!")
//        } catch let error {
//            print("Failed signOut - \(error.localizedDescription)")
//        }
//    }


// MARK: - before AnonAccountTrackerService

//import Combine
//import FirebaseAuth
//
//protocol AuthenticationServiceProtocol {
//    func authenticate() -> AnyPublisher<Result<String, Error>, Never>
//    func getCurrentUserID() -> AnyPublisher<Result<String,Error>, Never>
//    func reset()
//    func signOutUser()
//}
//
//
//
//class AuthenticationService: AuthenticationServiceProtocol {
//    
//    private var authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
//    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
//    
//    init() {
//        print("init AuthenticationService")
//                addListeners()
//    }
//    
//    private func addListeners() {
//        
//        if let handle = aythenticalSateHandler {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//        
//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener({ [weak self]  _, user in
//            print("AuthenticationService user.uid - \(String(describing: user?.uid))")
//            guard let self = self else { return }
//            
//            if let user = user {
//                self.authenticationPublisher.send(.success(user.uid))
//            } else {
//                self.createAnonymousUser()
//            }
//        })
//    }
//    
//    
//    private func createAnonymousUser() {
//        Auth.auth().signInAnonymously { [weak self] authResult, error in
//            guard let self = self else { return }
//            guard let user = authResult?.user else {
//                let authenticationError = error ?? NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])
//                self.authenticationPublisher.send(.failure(authenticationError))
//                return
//            }
//            // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
//        }
//    }
//    
//    func authenticate() -> AnyPublisher<Result<String, any Error>, Never> {
//        return authenticationPublisher.eraseToAnyPublisher()
//    }
//    
//    func reset() {
//        authenticationPublisher = PassthroughSubject<Result<String, Error>, Never>()
//        addListeners()
//    }
//    
//    /// в нем нет необходимости для HomeView так как вся логика CRUDS  в  CRUDSManager
//    func getCurrentUserID() -> AnyPublisher<Result<String, any Error>, Never> {
//        Future { promise in
//            if let user = Auth.auth().currentUser {
//                promise(.success(.success(user.uid)))
//            } else {
//                promise(.success(.failure(FirebaseInternalError.notSignedIn)))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    func signOutUser() {
//        do {
//            try Auth.auth().signOut()
//            print("Success signOut!")
//        } catch let error {
//            print("Failed signOut - \(error.localizedDescription)")
//        }
//    }
//}




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
