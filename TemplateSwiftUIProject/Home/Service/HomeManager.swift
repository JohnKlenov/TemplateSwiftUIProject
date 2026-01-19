//
//  HomeManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.01.26.
//

import Combine
import Foundation

final class HomeManager {
    
//    enum StateError {
//        case localError
//        case globalError
//    }
    
    private let authService: AuthenticationServiceProtocol
    private let firestoreService: FirestoreCollectionObserverProtocol
    private let errorHandler: ErrorHandlerProtocol
    private let alertManager: AlertManager
    
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var globalRetryHandler: GlobalRetryHandler?
    private var stateError: StateError = .localError
    
    init(
        authService: AuthenticationServiceProtocol,
        firestoreService: FirestoreCollectionObserverProtocol,
        errorHandler: ErrorHandlerProtocol,
        alertManager: AlertManager = .shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
    }
    
    func setRetryHandler(_ handler: GlobalRetryHandler) {
        self.globalRetryHandler = handler
    }
    
    func observeBooks() -> AnyPublisher<ViewState, Never> {
        authService.authenticate()
            .flatMap { [weak self] result -> AnyPublisher<ViewState, Never> in
                guard let self = self else {
                    return Just(.content([])).eraseToAnyPublisher()
                }
                
                switch result {
                case .success(let userId):
                    self.stateError = .localError
                    let path = "users/\(userId)/data"
                    
                    // 🔥 Явно указываем тип BookCloud
                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
                        self.firestoreService.observeCollection(at: path)
                    
                    return publisher
                        .map { result in
                            switch result {
                            case .success(let books):
                                return .content(books)
                            case .failure(let error):
                                return self.handleStateError(error)
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
                    return Just(self.handleStateError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func retry() {
        authService.reset()
    }
    
    // MARK: - Error Routing
    
    private func handleStateError(_ error: Error) -> ViewState {
        switch stateError {
        case .localError:
            return handleFirestoreError(error)
        case .globalError:
            return handleAuthenticationError(error)
        }
    }
    
    private func handleAuthenticationError(_ error: Error) -> ViewState {
        let message = errorHandler.handle(error: error)
        
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
    private func handleFirestoreError(_ error: Error) -> ViewState {
        let message = errorHandler.handle(error: error)
        stateError = .localError
        return .error(message)
    }
}
