//
//  HomeManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.01.26.
//


// Если HomeManager уничтожен, старая Combine-цепочка может ещё получать
// события от Firebase/Firestore. Возвращая .error("Internal state lost"),
// мы корректно завершаем старую цепочку и предотвращаем ситуацию, когда
// старый поток данных успевает отправить ложное состояние в UI (например,
// пустой список). Новый ContentView/ViewModel/HomeManager уже созданы и
// имеют собственную подписку, поэтому ошибка гарантирует, что старый поток
// не вмешается в работу нового стека.

// Если self == nil, HomeManager уже уничтожен (например, при пересоздании
// дерева SwiftUI). В этот момент его зависимости, включая errorHandler,
// тоже недоступны, поэтому логировать ошибку здесь невозможно. Мы
// возвращаем .error("Internal state lost") только для корректного
// завершения старой Combine-цепочки, чтобы она не вмешалась в работу
// нового стека сущностей.



/// Почему в HomeManager не может произойти гонки между cancelListener() и observeCollection()
///
/// Оба AuthStateDidChangeListener (в FirebaseAuthUserProvider и в AuthenticationService)
/// вызываются Firebase **строго в порядке регистрации** и **в одном и том же потоке** — на главном.
/// Это гарантирует последовательное выполнение без параллельных вызовов.
///
/// Последовательность при появлении сети всегда такая:
/// 1) Сначала вызывается listener в FirebaseAuthUserProvider → триггерит HomeManager.observeUserChanges() → cancelListener().
/// 2) Затем вызывается listener в AuthenticationService → триггерит HomeManager.observeBooks() → observeCollection().
///
/// Важно:
/// - cancelListener() и observeCollection() выполняются **в одном потоке (main thread)**.
/// - Параллельного выполнения нет, значит **гонка невозможна**.
/// - observeCollection() внутри себя всё равно вызывает cancelListener(), поэтому даже теоретически
///   невозможно создать новый listener, не удалив старый.
///
/// Итог:
/// Firestore listener никогда не потеряется, порядок вызовов детерминирован,
/// и HomeManager всегда сначала сбрасывает старый listener, а затем создаёт новый.



import Combine
import Foundation

final class HomeManager {
    
    private let authService: AuthenticationServiceProtocol
    private let firestoreService: FirestoreCollectionObserverProtocol
    private let errorHandler: ErrorDiagnosticsProtocol
    private let alertManager: AlertManager
    private let userProvider: CurrentUserProvider
    
//    private var cancellables = Set<AnyCancellable>()
    private var userListenerCancellable: AnyCancellable?
    private var currentUID: String?
    
    private(set) var globalRetryHandler: GlobalRetryHandler?
    private var stateError: StateError = .localError
    
    init(
        authService: AuthenticationServiceProtocol,
        firestoreService: FirestoreCollectionObserverProtocol,
        errorHandler: ErrorDiagnosticsProtocol,
        userProvider: CurrentUserProvider,
        alertManager: AlertManager = .shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        self.userProvider = userProvider
        self.alertManager = alertManager
        observeUserChanges()
        print("init HomeManager")
    }
    
    deinit {
        print("deinit HomeManager")
    }

    private func observeUserChanges() {
        userListenerCancellable = userProvider.currentUserPublisher
            .sink { [weak self] authUser in
                print("HomeManager observeUserChanges() userListenerCancellable = userProvider.currentUserPublisher .sink {")
                guard let self = self else { return }
                let newUID = authUser?.uid
                
                if self.currentUID != newUID {
                    print("🔄 HomeManager: смена пользователя \(String(describing: self.currentUID)) → \(String(describing: newUID))")
                    
                    // При смене пользователя гасим listener коллекции
                    self.firestoreService.cancelListener()
                    self.currentUID = newUID
                }
            }
    }

    
    func setRetryHandler(_ handler: GlobalRetryHandler) {
        self.globalRetryHandler = handler
    }
    
    func observeBooks() -> AnyPublisher<ViewState, Never> {
        authService.authenticate()
            .flatMap { [weak self] result -> AnyPublisher<ViewState, Never> in
                guard let self = self else {
                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription)).eraseToAnyPublisher()
                }
                
                switch result {
                case .success(let userId):
                    self.stateError = .localError
                    let path = "users/\(userId)/data"
                    
                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
                        self.firestoreService.observeCollection(at: path)
                    
                    return publisher
                        .map { result in
                            switch result {
                            case .success(let books):
                                return .content(books)
                            case .failure(let error):
                                return self.handleStateError(
                                    error,
                                    context: .HomeManager_observeBooks_firestoreService_observeCollection
                                )
                            }
                        }
                        .eraseToAnyPublisher()
                    
                case .failure(let error):
                    /// это ошибка может возникнуть только если createAnonymousUser вернет ошибку
                    /// она может возникнуть (при первом старте, если мы удалили account и не удадось createAnonymousUser ... )
                    /// так как HomeContentViewModel это единственная точка создания createAnonymousUser
                    /// refresh из любой точки приложения нужно делать сдесь через globalAlert и notification
                    /// может получится так что при первом старте время ответа от Firebase Auth будет долгим из за плохой сети
                    /// и пользователь перейдет на другую вкладку TabBar
                    /// тогда при ошибки создания createAnonymousUser мы должны через globalAlert на любом другом экране refresh
                    /// тут важно что бы globalAlert всегда первым отображался на экране ()
                    /// Таймауты Firebase Auth: Стандартный таймаут: 10-60 секунд (зависит от версии SDK и сетевых условий)
                    /// 3G: 2-8 секунд / Edge-сети (2G): 12-30 секунд / После 15 сек 60% пользователей закрывают приложение
                    self.stateError = .globalError
                    return Just(
                        self.handleStateError(
                            error,
                            context: .HomeManager_observeBooks_authService_authenticate
                        )
                    )
                    .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func retry() {
        authService.reset()
    }
    
    func start() {
        authService.start()
    }
    
    // MARK: - Error Routing
    
    private func handleStateError(_ error: Error, context: ErrorContext) -> ViewState {
        switch stateError {
        case .localError:
            return handleFirestoreError(error, context: context)
        case .globalError:
            return handleAuthenticationError(error, context: context)
        }
    }
    
    private func handleAuthenticationError(_ error: Error, context: ErrorContext) -> ViewState {
        let message = errorHandler.handle(error: error, context: context.rawValue)
        
        globalRetryHandler?.setAuthenticationRetryHandler { [weak self] in
            self?.retry()
        }
        
        alertManager.showGlobalAlert(
            message: message,
            operationDescription: Localized.TitleOfFailedOperationFirebase.authentication,
            alertType: .tryAgain
        )
        
        stateError = .localError
        return .error(message)
    }
    
    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
    private func handleFirestoreError(_ error: Error, context: ErrorContext) -> ViewState {
        let message = errorHandler.handle(error: error, context: context.rawValue)
        stateError = .localError
        return .error(message)
    }
}



// MARK: - before firestoreService.cancelListener()


//import Combine
//import Foundation
//
//final class HomeManager {
//    
//    private let authService: AuthenticationServiceProtocol
//    private let firestoreService: FirestoreCollectionObserverProtocol
//    private let errorHandler: ErrorDiagnosticsProtocol
//    private let alertManager: AlertManager
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    private(set) var globalRetryHandler: GlobalRetryHandler?
//    private var stateError: StateError = .localError
//    
//    init(
//        authService: AuthenticationServiceProtocol,
//        firestoreService: FirestoreCollectionObserverProtocol,
//        errorHandler: ErrorDiagnosticsProtocol,
//        alertManager: AlertManager = .shared
//    ) {
//        self.authService = authService
//        self.firestoreService = firestoreService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        print("init HomeManager")
//    }
//    
//    deinit {
//        print("deinit HomeManager")
//    }
//    
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        self.globalRetryHandler = handler
//    }
//    
//    func observeBooks() -> AnyPublisher<ViewState, Never> {
//        authService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<ViewState, Never> in
//                guard let self = self else {
//                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription)).eraseToAnyPublisher()
//                }
//                
//                switch result {
//                case .success(let userId):
//                    self.stateError = .localError
//                    let path = "users/\(userId)/data"
//                    
//                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
//                        self.firestoreService.observeCollection(at: path)
//                    
//                    return publisher
//                        .map { result in
//                            switch result {
//                            case .success(let books):
//                                return .content(books)
//                            case .failure(let error):
//                                return self.handleStateError(
//                                    error,
//                                    context: .HomeManager_observeBooks_firestoreService_observeCollection
//                                )
//                            }
//                        }
//                        .eraseToAnyPublisher()
//                    
//                case .failure(let error):
//                    /// это ошибка может возникнуть только если createAnonymousUser вернет ошибку
//                    /// она может возникнуть (при первом старте, если мы удалили account и не удадось createAnonymousUser ... )
//                    /// так как HomeContentViewModel это единственная точка создания createAnonymousUser
//                    /// refresh из любой точки приложения нужно делать сдесь через globalAlert и notification
//                    /// может получится так что при первом старте время ответа от Firebase Auth будет долгим из за плохой сети
//                    /// и пользователь перейдет на другую вкладку TabBar
//                    /// тогда при ошибки создания createAnonymousUser мы должны через globalAlert на любом другом экране refresh
//                    /// тут важно что бы globalAlert всегда первым отображался на экране ()
//                    /// Таймауты Firebase Auth: Стандартный таймаут: 10-60 секунд (зависит от версии SDK и сетевых условий)
//                    /// 3G: 2-8 секунд / Edge-сети (2G): 12-30 секунд / После 15 сек 60% пользователей закрывают приложение
//                    self.stateError = .globalError
//                    return Just(
//                        self.handleStateError(
//                            error,
//                            context: .HomeManager_observeBooks_authService_authenticate
//                        )
//                    )
//                    .eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    func retry() {
//        authService.reset()
//    }
//    
//    func start() {
//        authService.start()
//    }
//    
//    // MARK: - Error Routing
//    
//    private func handleStateError(_ error: Error, context: ErrorContext) -> ViewState {
//        switch stateError {
//        case .localError:
//            return handleFirestoreError(error, context: context)
//        case .globalError:
//            return handleAuthenticationError(error, context: context)
//        }
//    }
//    
//    private func handleAuthenticationError(_ error: Error, context: ErrorContext) -> ViewState {
//        let message = errorHandler.handle(error: error, context: context.rawValue)
//        
//        globalRetryHandler?.setAuthenticationRetryHandler { [weak self] in
//            self?.retry()
//        }
//        
//        alertManager.showGlobalAlert(
//            message: message,
//            operationDescription: Localized.TitleOfFailedOperationFirebase.authentication,
//            alertType: .tryAgain
//        )
//        
//        stateError = .localError
//        return .error(message)
//    }
//    
//    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
//    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
//    private func handleFirestoreError(_ error: Error, context: ErrorContext) -> ViewState {
//        let message = errorHandler.handle(error: error, context: context.rawValue)
//        stateError = .localError
//        return .error(message)
//    }
//}
//




// MARK: - before viewBuilderService in TemplateSwiftUIProjectApp

//import Combine
//import Foundation
//
//final class HomeManager {
//    
//    private let authService: AuthenticationServiceProtocol
//    private let firestoreService: FirestoreCollectionObserverProtocol
//    private let errorHandler: ErrorDiagnosticsProtocol
//    private let alertManager: AlertManager
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    private(set) var globalRetryHandler: GlobalRetryHandler?
//    private var stateError: StateError = .localError
//    
//    init(
//        authService: AuthenticationServiceProtocol,
//        firestoreService: FirestoreCollectionObserverProtocol,
//        errorHandler: ErrorDiagnosticsProtocol,
//        alertManager: AlertManager = .shared
//    ) {
//        self.authService = authService
//        self.firestoreService = firestoreService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        print("init HomeManager")
//    }
//    
//    deinit {
//        print("deinit HomeManager")
//    }
//    
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        self.globalRetryHandler = handler
//    }
//    
//    func observeBooks() -> AnyPublisher<ViewState, Never> {
//        authService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<ViewState, Never> in
//                guard let self = self else {
//                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription)).eraseToAnyPublisher()
//                }
//                
//                switch result {
//                case .success(let userId):
//                    self.stateError = .localError
//                    let path = "users/\(userId)/data"
//                    
//                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
//                        self.firestoreService.observeCollection(at: path)
//                    
//                    return publisher
//                        .map { result in
//                            switch result {
//                            case .success(let books):
//                                return .content(books)
//                            case .failure(let error):
//                                return self.handleStateError(
//                                    error,
//                                    context: .HomeManager_observeBooks_firestoreService_observeCollection
//                                )
//                            }
//                        }
//                        .eraseToAnyPublisher()
//                    
//                case .failure(let error):
//                    /// это ошибка может возникнуть только если createAnonymousUser вернет ошибку
//                    /// она может возникнуть (при первом старте, если мы удалили account и не удадось createAnonymousUser ... )
//                    /// так как HomeContentViewModel это единственная точка создания createAnonymousUser
//                    /// refresh из любой точки приложения нужно делать сдесь через globalAlert и notification
//                    /// может получится так что при первом старте время ответа от Firebase Auth будет долгим из за плохой сети
//                    /// и пользователь перейдет на другую вкладку TabBar
//                    /// тогда при ошибки создания createAnonymousUser мы должны через globalAlert на любом другом экране refresh
//                    /// тут важно что бы globalAlert всегда первым отображался на экране ()
//                    /// Таймауты Firebase Auth: Стандартный таймаут: 10-60 секунд (зависит от версии SDK и сетевых условий)
//                    /// 3G: 2-8 секунд / Edge-сети (2G): 12-30 секунд / После 15 сек 60% пользователей закрывают приложение
//                    self.stateError = .globalError
//                    return Just(
//                        self.handleStateError(
//                            error,
//                            context: .HomeManager_observeBooks_authService_authenticate
//                        )
//                    )
//                    .eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    func retry() {
//        authService.reset()
//    }
//
//    
//    // MARK: - Error Routing
//    
//    private func handleStateError(_ error: Error, context: ErrorContext) -> ViewState {
//        switch stateError {
//        case .localError:
//            return handleFirestoreError(error, context: context)
//        case .globalError:
//            return handleAuthenticationError(error, context: context)
//        }
//    }
//    
//    private func handleAuthenticationError(_ error: Error, context: ErrorContext) -> ViewState {
//        let message = errorHandler.handle(error: error, context: context.rawValue)
//        
//        globalRetryHandler?.setAuthenticationRetryHandler { [weak self] in
//            self?.retry()
//        }
//        
//        alertManager.showGlobalAlert(
//            message: message,
//            operationDescription: Localized.TitleOfFailedOperationFirebase.authentication,
//            alertType: .tryAgain
//        )
//        
//        stateError = .localError
//        return .error(message)
//    }
//    
//    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
//    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
//    private func handleFirestoreError(_ error: Error, context: ErrorContext) -> ViewState {
//        let message = errorHandler.handle(error: error, context: context.rawValue)
//        stateError = .localError
//        return .error(message)
//    }
//}


// MARK: - before ErrorDiagnosticsCenter



//import Combine
//import Foundation
//
//final class HomeManager {
//    
//    private let authService: AuthenticationServiceProtocol
//    private let firestoreService: FirestoreCollectionObserverProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    private let alertManager: AlertManager
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    private(set) var globalRetryHandler: GlobalRetryHandler?
//    private var stateError: StateError = .localError
//    
//    init(
//        authService: AuthenticationServiceProtocol,
//        firestoreService: FirestoreCollectionObserverProtocol,
//        errorHandler: ErrorHandlerProtocol,
//        alertManager: AlertManager = .shared
//    ) {
//        self.authService = authService
//        self.firestoreService = firestoreService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//    }
//    
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        self.globalRetryHandler = handler
//    }
//    
//    func observeBooks() -> AnyPublisher<ViewState, Never> {
//        authService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<ViewState, Never> in
//                guard let self = self else {
//                    return Just(.content([])).eraseToAnyPublisher()
//                }
//                
//                switch result {
//                case .success(let userId):
//                    self.stateError = .localError
//                    let path = "users/\(userId)/data"
//                    
//                    // 🔥 Явно указываем тип BookCloud
//                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
//                        self.firestoreService.observeCollection(at: path)
//                    
//                    return publisher
//                        .map { result in
//                            switch result {
//                            case .success(let books):
//                                return .content(books)
//                            case .failure(let error):
//                                return self.handleStateError(error)
//                            }
//                        }
//                        .eraseToAnyPublisher()
//                    
//                case .failure(let error):
                    /// это ошибка может возникнуть только если createAnonymousUser вернет ошибку
                    /// она может возникнуть (при первом старте, если мы удалили account и не удадось createAnonymousUser ... )
                    /// так как HomeContentViewModel это единственная точка создания createAnonymousUser
                    /// refresh из любой точки приложения нужно делать сдесь через globalAlert и notification
                    /// может получится так что при первом старте время ответа от Firebase Auth будет долгим из за плохой сети
                    /// и пользователь перейдет на другую вкладку TabBar
                    /// тогда при ошибки создания createAnonymousUser мы должны через globalAlert на любом другом экране refresh
                    /// тут важно что бы globalAlert всегда первым отображался на экране ()
                    /// Таймауты Firebase Auth: Стандартный таймаут: 10-60 секунд (зависит от версии SDK и сетевых условий)
                    /// 3G: 2-8 секунд / Edge-сети (2G): 12-30 секунд / После 15 сек 60% пользователей закрывают приложение
//                    self.stateError = .globalError
//                    return Just(self.handleStateError(error)).eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    func retry() {
//        authService.reset()
//    }
//    
//    // MARK: - Error Routing
//    
//    private func handleStateError(_ error: Error) -> ViewState {
//        switch stateError {
//        case .localError:
//            return handleFirestoreError(error)
//        case .globalError:
//            return handleAuthenticationError(error)
//        }
//    }
//    
//    private func handleAuthenticationError(_ error: Error) -> ViewState {
//        let message = errorHandler.handle(error: error)
//        
//        globalRetryHandler?.setAuthenticationRetryHandler { [weak self] in
//            self?.retry()
//        }
//        
//        alertManager.showGlobalAlert(
//            message: message,
//            operationDescription: Localized.TitleOfFailedOperationFirebase.authentication,
//            alertType: .tryAgain
//        )
//        
//        stateError = .localError
//        return .error(message)
//    }
//    
    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
//    private func handleFirestoreError(_ error: Error) -> ViewState {
//        let message = errorHandler.handle(error: error)
//        stateError = .localError
//        return .error(message)
//    }
//}
