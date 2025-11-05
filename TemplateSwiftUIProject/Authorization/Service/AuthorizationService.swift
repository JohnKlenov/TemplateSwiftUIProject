//
//  AuthorizationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//


// MARK: - ID токен Firebase

// Firebase Auth: срок жизни токена
//
// - ID токен Firebase по умолчанию живёт около 1 часа.
// - После этого он автоматически обновляется с помощью refresh‑токена,
//   если приложение активно и есть интернет.
// - Refresh‑токен не имеет жёсткого срока (может жить месяцами),
//   но сервер может его отозвать (например, при смене пароля или блокировке).
// - Если пользователь заходит в приложение раз в сутки или раз в две недели,
//   SDK при старте обновит ID токен через refresh‑токен и всё будет работать.
// - Проблемы возникают только если refresh‑токен недействителен
//   (например, пользователь удалён, пароль изменён, аккаунт отключён).
//
// Итог:
// - ID токен устаревает через ~1 час.
// - Для пользователя, который заходит раз в день или реже,
//   это прозрачно: SDK обновит токен автоматически.
// - Реаутентификация нужна только при критичных операциях
//   (delete, смена пароля/почты) или если refresh‑токен отозван.
//


// MARK: - паралельное выполнение auth‑операций

// Auth операции (SignIn / SignUp / DeleteAccount)
//
// - В боевых приложениях не допускают параллельных auth‑операций.
// - Пока выполняется SignIn или SignUp, UI блокирует другие действия (например, DeleteAccount).
// - Причина: Firebase Auth поддерживает только одного currentUser, параллельные вызовы создают гонки.
// - Правильный паттерн: "одна auth‑операция за раз" + возможность отмены на уровне UI.
// - Таким образом сохраняется консистентность и предсказуемое поведение.
//


// MARK: - func deleteAccount()


// Firebase Auth: user.delete — обработка ошибок и сетевое поведение
//
// 1) Подробно: возможные ошибки в блоке `user.delete { error in ... }`
//
//    - Домен ошибок: FIRAuthErrorDomain (можно преобразовать в AuthErrorCode по rawValue).
//    - Наиболее частые коды, которые стоит явно обрабатывать:
//
//      .requiresRecentLogin
//      // Удаление аккаунта требует «свежей» аутентификации.
//      // Нужно инициировать повторный вход пользователя и затем повторить удаление.
//
//      .networkError
//      // Проблемы с сетью: отсутствие интернета, сбои DNS, потеря пакетов.
//      // Следует показать пользователю сообщение об ошибке и предложить повторить.
//
//      .userTokenExpired
//      // Токен доступа устарел. Обычно помогает повторная аутентификация.
//
//      .invalidUserToken
//      // Токен недействителен (повреждён или отозван). Требуется повторный вход.
//
//      .userNotFound
//      // Пользователь больше не существует (например, уже удалён на сервере).
//      // С точки зрения UX можно трактовать как успешное удаление.
//
//      .internalError
//      // Внутренняя ошибка Firebase. Логируем и показываем общее сообщение об ошибке.
//
//      .appNotAuthorized
//      // Ошибка конфигурации проекта (неверные ключи, настройки).
//      // Критическая ошибка, требует исправления конфигурации.
//
//    // Общий паттерн:
//    // if let code = AuthErrorCode(rawValue: nsError.code) { switch code { ... } }
//
//
// 2) Ключевые моменты: плохой интернет или отсутствие сети
//    - При полном отсутствии соединения SDK быстро вернёт `.networkError`.
//    - При очень плохом соединении SDK будет пытаться достучаться до серверов,
//      пока системный стек не вернёт ошибку.
//
//
// 3) Ключевые моменты: таймаут
//    - У Firebase Auth SDK нет жёстко задокументированного таймаута для delete().
//    - Используется системный сетевой стек iOS (обычно таймаут соединения ~60 секунд).
//    - Если нужно предсказуемое поведение, оборачивайте вызов в Combine‑оператор
//      `.timeout(.seconds(15), ...)`, чтобы ограничить ожидание.
//
//
// Практические рекомендации
//    - Минимум обрабатывать: .requiresRecentLogin, .networkError, .userNotFound.
//    - Для временных проблем (сеть) показывать пользователю возможность повторить.
//    - Для предсказуемости использовать собственный таймаут на уровне Combine.
//    - Неизвестные коды логировать и показывать универсальное сообщение об ошибке.
//

// Поведение при таймауте и «позднем ответе» Firebase SDK (user.delete)
// для deleteAccount лучше не ставить таймаут, а довериться SDK и показать пользователю реальный результат.
//
// 1) Что делает таймаут в Combine
//    - Когда срабатывает .timeout, паблишер завершает цепочку с ошибкой.
//    - Подписчик (sink) получает .failure и считается завершённым.
//    - Все cancellable для этой подписки освобождаются.
//
// 2) Что происходит, если SDK вернёт ответ позже
//    - Firebase SDK всё равно вызовет completion-блок user.delete.
//    - Внутри Future будет вызван promise(...).
//    - Но Future по контракту принимает результат только один раз.
//    - Если promise уже был вызван (таймаут сработал), повторный вызов игнорируется.
//    - Никакого двойного завершения или краша не произойдёт.
//
// 3) Итоговое поведение
//    - Для подписчика: он увидит только ошибку таймаута.
//    - Поздний ответ SDK будет проигнорирован.
//    - Это нормальное и безопасное поведение.
//
// 4) Практический совет
//    - Если важно отлаживать такие ситуации, можно добавить print()
//      перед вызовом promise в user.delete, чтобы логировать «опоздавшие» ответы.
//    - Например: print("⚠️ SDK ответил после таймаута").
//




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

final class AuthorizationService {
    
    private let userProvider: CurrentUserProvider
    private var cancellable: AnyCancellable?
    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
    
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    init(userProvider: CurrentUserProvider) {
        print("AuthorizationService init")
        self.userProvider = userProvider
        observeUserChanges()
    }
    
    private func observeUserChanges() {
        cancellable = userProvider.currentUserPublisher
            .sink { [weak self] authUser in
                print("🔄 AuthorizationService получил нового пользователя: \(String(describing: authUser))")
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
                    return Fail(error: FirebaseInternalError.defaultError)
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
                promise(.failure(.underlying(FirebaseInternalError.notSignedIn)))
                return
            }
            user.delete { error in
                if let nsError = error as NSError? {
                    // создаём AuthErrorCode по rawValue и сравниваем
                    if let code = AuthErrorCode(rawValue: nsError.code) {
                        switch code {
                        case .requiresRecentLogin,
                             .userTokenExpired,
                             .invalidUserToken,
                             .invalidCredential:
                            // Все эти ошибки требуют повторной аутентификации
                            promise(.failure(.reauthenticationRequired(nsError)))
                            
                        default:
                            // Остальные ошибки пробрасываем как underlying
                            promise(.failure(.underlying(nsError)))
                        }
                    } else {
                        // Если не удалось распарсить код — пробрасываем как underlying
                        promise(.failure(.underlying(nsError)))
                    }
                } else {
                    // Ошибки нет — удаление прошло успешно
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    func reauthenticate(email: String, password: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                return promise(.failure(FirebaseInternalError.notSignedIn))
            }

            // может быть Apple + Google Provider
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
            return Fail(error: FirebaseInternalError.notSignedIn).eraseToAnyPublisher()
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
                    promise(.failure(FirebaseInternalError.defaultError))
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
                    promise(.failure(FirebaseInternalError.defaultError))
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
                    promise(.failure(FirebaseInternalError.defaultError))
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
    
    deinit {
        print("AuthorizationService deinit")
    }
    
}





//            user.delete { error in
//                if let nsError = error as NSError? {
//                    // создаём AuthErrorCode по rawValue и сравниваем
//                    if let code = AuthErrorCode(rawValue: nsError.code),
//                       code == .requiresRecentLogin {
//                        promise(.failure(.reauthenticationRequired(nsError)))
//                    } else {
//                        promise(.failure(.underlying(nsError)))
//                    }
//                } else {
//                    promise(.success(()))
//                }
//            }




// MARK: - Before refactoring AuthorizationService (DI FirebaseAuthUserProvider)

//final class AuthorizationService {
//    
//    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
//    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
////    private let functions = Functions.functions()
//    
//    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
//        authStateSubject.eraseToAnyPublisher()
//    }
//    
//    init() {
//        
//        print("AuthorizationService init")
//        if let handle = aythenticalSateHandler {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//        /// при удалении узера нам сначало должен прийти nil а потм уже объект user anon
//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
//            print("AuthorizationService/AuthorizationManager user.uid - \(String(describing: user?.uid))")
//            guard let user = user else {
//                self?.authStateSubject.send(nil)
//                return
//            }
//            let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
//            self?.authStateSubject.send(authUser)
//        }
//    }

//deinit {
//    print("AuthorizationService deinit")
//    if let handle = aythenticalSateHandler {
//        Auth.auth().removeStateDidChangeListener(handle)
//    }
//}











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
