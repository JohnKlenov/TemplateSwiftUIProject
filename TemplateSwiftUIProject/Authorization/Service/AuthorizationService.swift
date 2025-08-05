//
//  AuthorizationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//



// func signInBasic в первой тестовой реализации будет реализован без удаления anonUser и его данных в CloudFunction
// мы будем это делать вручную + сначало мы потестим как отработает удаление личных данных пользователя из CloudFunction в след за удалением аккаунта пользователя 

import FirebaseAuth
import Combine
//import FirebaseFunctions

// Ошибка, специфичная для deleteAccount()
enum DeleteAccountError: Error {
  /// Firebase вернул код .requiresRecentLogin
  case reauthenticationRequired(Error)
  /// Любая другая ошибка — оборачиваем оригинальный Error
  case underlying(Error)
}

struct AuthUser {
    let uid: String
    let isAnonymous: Bool
}

final class AuthorizationService {
    
    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
//    private let functions = Functions.functions()
    
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    init() {
        
        print("AuthorizationService init")
        if let handle = aythenticalSateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        /// при удалении узера нам сначало должен прийти nil а потм уже объект user anon
        aythenticalSateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            print("AuthorizationService/AuthorizationManager user.uid - \(String(describing: user?.uid))")
            guard let user = user else {
                self?.authStateSubject.send(nil)
                return
            }
            let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
            self?.authStateSubject.send(authUser)
        }
    }
    
    // регистрация или линковка анонимного пользователя
    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
        currentUserPublisher()
            .flatMap { user -> AnyPublisher<AuthDataResult, Error> in
                if user.isAnonymous {
                    let cred = EmailAuthProvider.credential(withEmail: email, password: password)
                    return self.linkPublisher(user: user, credential: cred)
                } else {
                    return self.createUserPublisher(email: email, password: password)
                }
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // логирование и удаление анонимного пользователя
    func signInBasic(email: String, password: String)
    -> AnyPublisher<Void, Error>
    {
        currentUserPublisher()
            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: FirebaseEnternalError.defaultError)
                        .eraseToAnyPublisher()
                }
                if user.isAnonymous {
                    // Сохраняем UID анонима, чтобы потом удалить
                    let anonUid = user.uid
                    print("anonUid func signInBasic - \(anonUid)")
                    return self.signInPublisher(email: email, password: password)
                    // после успешного входа — зовём Cloud Function
//                        .flatMap { _ in
//                            self.cleanupAnonymous(anonUid: anonUid)
//                        }
                        .map { _ in () }
                        .eraseToAnyPublisher()
                } else {
                    // Обычный вход, просто мапим в Void
                    print("permanentUser func signInBasic - \(user.uid)")
                    return self.signInPublisher(email: email, password: password)
                        .map { _ in () }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
        
    
    // удаляем аккаунт
    func deleteAccount() -> AnyPublisher<Void, DeleteAccountError> {
        Future<Void, DeleteAccountError> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(.underlying(FirebaseEnternalError.notSignedIn)))
                return
            }
            
            user.delete { error in
                if let nsError = error as NSError? {
                    // создаём AuthErrorCode по rawValue и сравниваем
                    if let code = AuthErrorCode(rawValue: nsError.code),
                       code == .requiresRecentLogin {
                        promise(.failure(.reauthenticationRequired(nsError)))
                    } else {
                        promise(.failure(.underlying(nsError)))
                    }
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func reauthenticate(email: String, password: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                return promise(.failure(FirebaseEnternalError.notSignedIn))
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: password)

            user.reauthenticate(with: credential) { result, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
   


    // MARK: - Helpers

    private func currentUserPublisher() -> AnyPublisher<User, Error> {
        guard let user = Auth.auth().currentUser else {
            return Fail(error: FirebaseEnternalError.notSignedIn).eraseToAnyPublisher()
        }
        return Just(user)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func createUserPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { res, err in
                if let error = err {
                    promise(.failure(error))
                } else if let result = res {
                    promise(.success(result))
                } else {
                    /// вот эту ошибку нужно обязательно логировать
                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
                    promise(.failure(FirebaseEnternalError.defaultError))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func linkPublisher(user: User, credential: AuthCredential) -> AnyPublisher<AuthDataResult, Error> {
        Future { [weak self] promise in
            user.link(with: credential) { res, err in
                print("linkPublisher res - \(String(describing: res)), error - \(String(describing: err))")
                if let error = err {
                    promise(.failure(error))
                } else if let result = res {
                    // 💡 Обновляем authState сразу так как при успешной линковки addStateDidChangeListener не отработает
                    self?.updateAuthState(from: result.user)
                    promise(.success(result))
                } else {
                    /// вот эту ошибку нужно обязательно логировать
                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
                    promise(.failure(FirebaseEnternalError.defaultError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func updateAuthState(from user: FirebaseAuth.User) {
        let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
        authStateSubject.send(authUser)
    }

    private func signInPublisher(email: String, password: String)
    -> AnyPublisher<AuthDataResult, Error>
    {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { res, err in
                if let err = err {
                    promise(.failure(err))
                } else if let result = res {
                    promise(.success(result))
                } else {
                    /// вот эту ошибку нужно обязательно логировать
                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
                    promise(.failure(FirebaseEnternalError.defaultError))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendVerificationEmail() {
        Auth.auth().currentUser?.sendEmailVerification(completion: nil)
    }
    
    // сбрасываем локального юзера
    func signOut() -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 3) Вызываем HTTPS-функцию на удаление старого анонима
//    private func cleanupAnonymous(anonUid: String)
//    -> AnyPublisher<Void, Error>
//    {
//        let data: [String: Any] = ["uid": anonUid]
//        return Future { [weak self] promise in
//            self?.functions.httpsCallable("cleanupAnonymousUser")
//                .call(data) { result, error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//        }
//        .eraseToAnyPublisher()
//    }
    
    // создаём/обновляем профиль
//    func createProfile(name: String) -> AnyPublisher<Void, Error> {
//        Deferred {
//            Future { promise in
//                guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//                    return promise(.failure(FirebaseEnternalError.notSignedIn))
//                }
//                req.displayName = name
//                req.commitChanges { error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
    
    
    deinit {
        print("AuthorizationService deinit")
        if let handle = aythenticalSateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

}



// before DeleteAccountError
    
//    func deleteAccount() -> AnyPublisher<Void, Error> {
//        Future { promise in
//            guard let user = Auth.auth().currentUser else {
//                return promise(.failure(FirebaseEnternalError.notSignedIn))
//            }
//
//            user.delete { error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
    

//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
//            let authUser = user.map { AuthUser(isAnonymous: $0.isAnonymous) }
//            self?.authStateSubject.send(authUser)
//        }

/// Линкуем анонимного, делаем reload и шлём новый AuthUser
//    private func linkAndReload(
//        user: User,
//        credential: AuthCredential
//    ) -> AnyPublisher<Void, Error> {
//        linkPublisher(user: user, credential: credential)
//            .flatMap { [weak self] _ -> AnyPublisher<AuthUser, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseEnternalError.defaultError)
//                        .eraseToAnyPublisher()
//                }
//                return self.reloadCurrentUser()
//            }
//            .handleEvents(receiveOutput: { [weak self] updated in
//                self?.authStateSubject.send(updated)
//            })
//            .map { _ in () }
//            .eraseToAnyPublisher()
//    }
//
//    /// Перезагружает текущего пользователя и выдаёт обновлённый AuthUser
//    private func reloadCurrentUser() -> AnyPublisher<AuthUser, Error> {
//        Future<AuthUser, Error> { promise in
//            Auth.auth().currentUser?.reload(completion: { err in
//                if let err = err {
//                    return promise(.failure(err))
//                }
//                guard let u = Auth.auth().currentUser else {
//                    return promise(.failure(FirebaseEnternalError.defaultError))
//                }
//                let au = AuthUser(uid: u.uid, isAnonymous: u.isAnonymous)
//                promise(.success(au))
//            })
//        }
//        .eraseToAnyPublisher()
//    }

// MARK: - before AnyPublisher<Void, Error>

// AuthorizationService.swift
//import FirebaseAuth
//import Combine
//
/////case .unknown:  Баг или нестабильность в SDK Firebase — крайне редкий случай, но иногда можно словить такой "undefined" результат при сетевых сбоях или конфликтах версий SDK.
//enum AuthError: LocalizedError {
//  case notAuthorized
//  case firebase(Error)
//  case unknown
//
//  var errorDescription: String? {
//    switch self {
//    case .notAuthorized:       return "Пользователь не авторизован."
//    case .firebase(let error): return error.localizedDescription
//    case .unknown:             return "Неизвестная ошибка."
//    }
//  }
//}
//
///// Чистый сервис — регистрирует/линкует пользователя, обновляет профиль.
//final class AuthorizationService {
//  
//    // Шаг 1: регистрация или линковка анонимного пользователя → возвращает Void
//    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, AuthError> {
//      currentUserPublisher()
//        .flatMap { user -> AnyPublisher<AuthDataResult, AuthError> in
//          if user.isAnonymous {
//            let cred = EmailAuthProvider.credential(withEmail: email, password: password)
//            return self.linkPublisher(user: user, credential: cred)
//          } else {
//            return self.createUserPublisher(email: email, password: password)
//          }
//        }
//        .map { _ in () } // или .voidMap() если есть такое расширение
//        .eraseToAnyPublisher()
//    }
//
//  // Шаг 2: создаём/обновляем профиль → Void
//  func createProfile(name: String) -> AnyPublisher<Void, AuthError> {
//    Deferred {
//      Future { promise in
//        guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//          return promise(.failure(.notAuthorized))
//        }
//        req.displayName = name
//        req.commitChanges { error in
//          if let e = error {
//            promise(.failure(.firebase(e)))
//          } else {
//            promise(.success(()))
//          }
//        }
//      }
//    }
//    .eraseToAnyPublisher()
//  }
//
//  // MARK: — Helpers
//
//    private func currentUserPublisher() -> AnyPublisher<User, AuthError> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: .notAuthorized).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: AuthError.self)
//            .eraseToAnyPublisher()
//    }
//
//    private func createUserPublisher(email: String, password: String)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func linkPublisher(user: User, credential: AuthCredential)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            user.link(with: credential) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//  func sendVerificationEmail() {
//    Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//  }
//}


// MARK: - func signUp(email: String, password: String, name: String) - create user and create profile user

///// Чистый сервис — регистрирует/линкует пользователя, обновляет профиль.
//final class AuthorizationService {
//  
//    // Шаг 1: регистрация или линковка анонимного пользователя → возвращает userId
//  func signUpBasic(email: String, password: String) -> AnyPublisher<String, AuthError> {
//    currentUserPublisher()
//      .flatMap { user -> AnyPublisher<AuthDataResult, AuthError> in
//        if user.isAnonymous {
//          let cred = EmailAuthProvider.credential(
//            withEmail: email,
//            password: password
//          )
//          return self.linkPublisher(user: user, credential: cred)
//        } else {
//          return self.createUserPublisher(email: email, password: password)
//        }
//      }
//      .map { $0.user.uid }
//      .eraseToAnyPublisher()
//  }
//
//  // Шаг 2: создаём/обновляем профиль → Void
//  func createProfile(name: String) -> AnyPublisher<Void, AuthError> {
//    Deferred {
//      Future { promise in
//        guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//          return promise(.failure(.notAuthorized))
//        }
//        req.displayName = name
//        req.commitChanges { error in
//          if let e = error {
//            promise(.failure(.firebase(e)))
//          } else {
//            promise(.success(()))
//          }
//        }
//      }
//    }
//    .eraseToAnyPublisher()
//  }
//
//  // MARK: — Helpers
//
//    private func currentUserPublisher() -> AnyPublisher<User, AuthError> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: .notAuthorized).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: AuthError.self)
//            .eraseToAnyPublisher()
//    }
//
//    private func createUserPublisher(email: String, password: String)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func linkPublisher(user: User, credential: AuthCredential)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            user.link(with: credential) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//  func sendVerificationEmail() {
//    Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//  }
//}



// MARK: - legacy implementation

//import SwiftUI
//import FirebaseAuth
//
//class AuthorizationManager {
//    
//    var currentUser = Auth.auth().currentUser
//    
//    func signUp(email: String, password: String, name: String, completion: @escaping (Error?, Bool) -> Void) {
//        
//        let errorAuth = NSError(domain: "com.yourapp.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authorized."])
//        
//            guard let _ = currentUser else {
//                
//                completion(errorAuth, false)
//                return
//            }
//        
//            if currentUser?.isAnonymous == true {
//                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//                currentUser?.link(with: credential) { [weak self] (result, error) in
//                    // Обработайте результат
//                    if let error = error {
//                        completion(error, false)
//                    } else {
//                        self?.createProfileAndHandleError(name: name, isAnonymous: true, completion: completion)
//                    }
//                }
//            } else {
//                Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
//                    if let error = error  {
//                        completion(error,false)
//                    } else {
//                        self?.createProfileAndHandleError(name: name, isAnonymous: false, completion: completion)
//                    }
//                }
//            }
//        }
//    
//    func createProfileAndHandleError(name: String, isAnonymous: Bool, completion: @escaping (Error?, Bool) -> Void) {
//        createProfileChangeRequest(name: name, { error in
//            if let error = error {
//                completion(error, false)
//            } else {
//                self.verificationEmail()
//                completion(error, true)
//            }
//        })
//    }
//        
//        // Отправить пользователю электронное письмо с подтверждением регистрации
//        func verificationEmail() {
//            currentUser?.sendEmailVerification()
//        }
//        
//        // если callback: ((StateProfileInfo, Error?) -> ())? = nil) closure не пометить как @escaping (зачем он нам не обязательный?)
//        // if error == nil этот callBack не будет вызван(вызов проигнорируется) - callBack: ((Error?) -> Void)? = nil // callBack?(error)
//        func createProfileChangeRequest(name: String? = nil, photoURL: URL? = nil,_ completion: @escaping (Error?) -> Void) {
//
//            if let request = currentUser?.createProfileChangeRequest() {
//                if let name = name {
//                    request.displayName = name
//                }
//
//                if let photoURL = photoURL {
//                    request.photoURL = photoURL
//                }
//                
//                request.commitChanges { error in
//                    completion(error)
//                }
//            } else {
//                ///need created build Error
//                let error = NSError(domain: "com.yourapp.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authorized."])
//                completion(error)
//            }
//        }
//}
