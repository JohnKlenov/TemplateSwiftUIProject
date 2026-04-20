//
//  AppSessionManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

//import Combine
//import Foundation
//
//final class AppSessionManager {
//
//    // MARK: - Public reactive state
//
//    private let stateSubject = CurrentValueSubject<DropeState?, Never>(nil)
//    var statePublisher: AnyPublisher<DropeState?, Never> {
//        stateSubject.eraseToAnyPublisher()
//    }
//
//    // MARK: - Dependencies
//
//    private let authService: AuthenticationServiceProtocol
//    private let firestoreService: FirestoreCollectionObserverProtocol
//    private let errorHandler: ErrorDiagnosticsProtocol
//    private let alertManager: AlertManager
//
//    private var cancellables = Set<AnyCancellable>()
//    private(set) var globalRetryHandler: GlobalRetryHandler?
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
//    // MARK: - Public API
//
//    func start() {
//        authService.start()
//    }
//
//    /// Единая реактивная цепочка:
//    /// Auth → userId → Firestore → ViewState → stateSubject
//    func observe() {
//        authService.authenticate()
//            .flatMap { [weak self] resultOrNil -> AnyPublisher<DropeState, Never> in
//                guard let self = self else {
//                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription))
//                        .eraseToAnyPublisher()
//                }
//
//                // user == nil → deleteAccount / signOut / переходное состояние
//                guard let result = resultOrNil else {
//                    self.firestoreService.cancelListener()
//                    return Just(.loading).eraseToAnyPublisher()
//                }
//
//                switch result {
//                case .success(let userId):
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
//                                return self.handleError(
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
//                    return Just(
//                        self.handleError(
//                            error,
//                            context: .HomeManager_observeBooks_authService_authenticate
//                        )
//                    )
//                    .eraseToAnyPublisher()
//                }
//            }
//            .sink { [weak self] state in
//                self?.stateSubject.send(state)
//            }
//            .store(in: &cancellables)
//    }
//
//    func retry() {
//        stateSubject.send(.loading)
//        authService.reset()
//    }
//
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        self.globalRetryHandler = handler
//    }
//
//    // MARK: - Error Handling (единый маршрут ошибок)
//    
//    /// помоему мы решили эту проблему ?!
//    /// Локальные ошибки Firestore → без глобального алерта
//    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
//    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
//    private func handleError(_ error: Error, context: ErrorContext) -> DropeState {
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
//        return .error(message)
//    }
//}
//
