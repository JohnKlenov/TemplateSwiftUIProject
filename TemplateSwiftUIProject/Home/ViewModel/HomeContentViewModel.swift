//
//  HomeViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.10.24.
//


///Когда выполнится return Empty().eraseToAnyPublisher(), flatMap не отправит никаких значений дальше по цепочке.
///Последующие операторы (receive, sink) не получат никаких данных и обработка завершится.
///Если вам нужно, чтобы sink срабатывал даже в случае отсутствия данных, можно использовать Just.

///Firebase не предоставляет явного значения для таймаута по умолчанию, вы можете управлять таймаутами вручную.
///Контроль таймаутов в Firebase не является абсолютно необходимым и может усложнить ваш код, особенно если у вас нет строгих требований к времени ожидания. В большинстве случаев, можно доверить Firebase управлять соединением и ждать ответ от сервера столько, сколько необходимо.


import Combine
import SwiftUI


enum ViewState {
    case loading
    case error(String)
    case content([BookCloud])
}

extension ViewState {
    var isError:Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

enum StateError {
    case localError
    case globalError
}


protocol HomeViewModelProtocol: ObservableObject {
    var viewState: ViewState { get set }
    var alertManager:AlertManager { get set }
    func removeBook(book: BookCloud, forView:String, operationDescription: String)
    func retry()
}


class HomeContentViewModel: HomeViewModelProtocol {
    
    /// может просто var alertManager:AlertManager ???@ObservedObject
    var alertManager:AlertManager
    @Published var viewState: ViewState = .loading
    
    private var stateError:StateError = .localError
    private var cancellables = Set<AnyCancellable>()
    private var authenticationService: AuthenticationServiceProtocol
    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
    var managerCRUDS: CRUDSManager
    private let errorHandler: ErrorHandlerProtocol
    private var homeBookDataStore:HomeBookDataStore?
    
    init(alertManager: AlertManager = AlertManager.shared, authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, managerCRUDS: CRUDSManager, errorHandler: ErrorHandlerProtocol) {
        self.alertManager = alertManager
        self.authenticationService = authenticationService
        self.firestorColletionObserverService = firestorColletionObserverService
        self.errorHandler = errorHandler
        self.managerCRUDS = managerCRUDS
        print("init HomeContentViewModel")
    }
    
    //нужно понимать что данный экран не HomeView а CardProduct
    
    //.sink { case .failure = cachedData }
    //разшовор о том как использовать let cachedData = self?.homeBookDataStore?.books, !cachedData.isEmpty
    // к примеру мы ловим ошибку после того как уже заходили в систему удачно и не хотим видеть ContentErrorView (у нас уже есть кэшь)
    
    ///authenticationService.authenticate()
    /// ошибка из authenticationService.authenticate() может возникнуть, если Auth.auth().signInAnonymously вернул error
    /// это возможно при первом запуске App на device или при удалении permanent user
    /// при первом запуске cachedData пуст поэтому мы попадаем в  handleStateError(error) = все ok!
    /// если мы удалили permanent user и authenticationService.authenticate() возвращает error (из signInAnonymously)
    /// мы попадем в  .sink { case .failure = cachedData } и cachedData тут не пуст он остался от прошлого user = это плохо! (при успешном удалении permanent user мы должны  в observeCollection listener?.remove() и self?.homeBookDataStore?.books = [])
    private func bind() {
        
        viewState = .loading
        authenticationService.authenticate()
            .flatMap { [weak self] result -> AnyPublisher<Result<[BookCloud], Error>, Never> in
                guard let self = self else {
                    return Just(.success([])).eraseToAnyPublisher()
                }
                switch result {
                case .success(let userId):
                    
                    return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
                case .failure(let error):
                    stateError = .globalError
                    return Just(.failure(error)).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success(let data):
                    self?.homeBookDataStore?.books = data
                    self?.viewState = .content(data)
                case .failure(let error):
                    // Если уже есть кэшированные данные, отображаем их вместо ошибки
                    if let cachedData = self?.homeBookDataStore?.books, !cachedData.isEmpty {
                        print("Ошибка получения данных, используем кэш")
                        self?.viewState = .content(cachedData)
                        self?.handleError(error)
                        // Возможно, добавить механизм показа неинвазивного уведомления об ошибке
                    } else {
                        self?.handleStateError(error)
                    }
//                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func setupViewModel(dataStore:HomeBookDataStore) {
        homeBookDataStore = dataStore
        bind()
    }
    
    func retry() {
        homeBookDataStore?.books = []
        authenticationService.reset()
        bind()
    }
    
    private func handleStateError(_ error: Error) {
        switch stateError {
        case .localError: 
            handleFirestoreError(error)
        case .globalError:
            handleAuthenticationError(error)
        }
        stateError = .localError
    }
    
    func removeBook(book: BookCloud, forView:String, operationDescription: String) {
        managerCRUDS.removeBook(book: book, forView: forView, operationDescription: operationDescription)
    }
    
    private func handleAuthenticationError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: Localized.DescriptionOfOperationError.authentication)
        viewState = .error(errorMessage)
    }
    
    private func handleFirestoreError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView", operationDescription: Localized.DescriptionOfOperationError.database)
        viewState = .error(errorMessage)
    }
    
    private func handleError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView", operationDescription: Localized.DescriptionOfOperationError.database)
    }
}




// MARK: - before pattern Coordinator

//import Combine
//import SwiftUI
//
//
//enum ViewState {
//    case loading
//    case error(String)
//    case content([BookCloud])
//}
//
//extension ViewState {
//    var isError:Bool {
//        if case .error = self {
//            return true
//        }
//        return false
//    }
//}
//
//enum StateError {
//    case localError
//    case globalError
//}
//
//
//protocol HomeViewModelProtocol: ObservableObject {
//    var viewState: ViewState { get set }
//    var alertManager:AlertManager { get set }
//    func removeBook(book: BookCloud, forView:String, operationDescription: String)
//    func retry()
//}
//
//
//class HomeContentViewModel: HomeViewModelProtocol {
//    
//    /// может просто var alertManager:AlertManager ???@ObservedObject
//    var alertManager:AlertManager
//    var sheetManager:SheetManager
//    @Published var viewState: ViewState = .loading
//    
//    private var stateError:StateError = .localError
//    private var cancellables = Set<AnyCancellable>()
//    private var authenticationService: AuthenticationServiceProtocol
//    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
//    private var managerCRUDS: any CRUDSManagerProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    
//    init(alertManager: AlertManager = AlertManager.shared, sheetManager: SheetManager = SheetManager.shared, authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, managerCRUDS: any CRUDSManagerProtocol, errorHandler: ErrorHandlerProtocol) {
//        self.alertManager = alertManager
//        self.authenticationService = authenticationService
//        self.firestorColletionObserverService = firestorColletionObserverService
//        self.errorHandler = errorHandler
//        self.managerCRUDS = managerCRUDS
//        self.sheetManager = sheetManager
//        bind()
//        print("init HomeContentViewModel")
//    }
//    
//    private func bind() {
//        
//        viewState = .loading
//        authenticationService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<Result<[BookCloud], Error>, Never> in
//                guard let self = self else {
//                    return Just(.success([])).eraseToAnyPublisher()
//                }
//                switch result {
//                case .success(let userId):
//                    
//                    return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//                case .failure(let error):
//                    stateError = .globalError
//                    return Just(.failure(error)).eraseToAnyPublisher()
//                }
//            }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                switch result {
//                case .success(let data):
//                    self?.viewState = .content(data)
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    func retry() {
//        authenticationService.reset()
//        bind()
//    }
//    
//    private func handleError(_ error: Error) {
//        switch stateError {
//        case .localError:
//            handleFirestoreError(error)
//        case .globalError:
//            handleAuthenticationError(error)
//        }
//        stateError = .localError
//    }
//    
//    func removeBook(book: BookCloud, forView:String, operationDescription: String) {
//        managerCRUDS.removeBook(book: book, forView: forView, operationDescription: operationDescription)
//    }
//    
//    private func handleAuthenticationError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: "Error authentication")
//        viewState = .error(errorMessage)
//    }
//    
//    private func handleFirestoreError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView", operationDescription: "Error Database")
//        viewState = .error(errorMessage)
//    }
//}





// MARK: - a old understanding of how bindingError works -


//import Combine
//import SwiftUI
//
//
//enum ViewState {
//    case loading
//    case error(String)
//    case content([BookCloud])
//}
//
//extension ViewState {
//    var isError:Bool {
//        if case .error = self {
//            return true
//        }
//        return false
//    }
//}
//
//enum StateError {
//    case localError
//    case globalError
//}
//
//
//protocol HomeViewModelProtocol: ObservableObject {
//    var viewState: ViewState { get set }
//    var alertManager:AlertManager { get set }
//    func removeBook(book: BookCloud, forView:String, operationDescription: String)
//    func retry()
//}
//
//
//class HomeViewModel: HomeViewModelProtocol {
//    
//    @ObservedObject var alertManager:AlertManager
//    @Published var viewState: ViewState = .loading
//    
//    private var stateError:StateError = .localError
//    private var cancellables = Set<AnyCancellable>()
//    private var authenticationService: AuthenticationServiceProtocol
//    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
//    private var managerCRUDS: any CRUDSManagerProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    
//    init(alertManager: AlertManager = AlertManager.shared, authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, managerCRUDS: any CRUDSManagerProtocol, errorHandler: ErrorHandlerProtocol) {
//        self.alertManager = alertManager
//        self.authenticationService = authenticationService
//        self.firestorColletionObserverService = firestorColletionObserverService
//        self.errorHandler = errorHandler
//        self.managerCRUDS = managerCRUDS
//        bind()
//        print("init HomeViewModel")
//    }
//    
//    private func bind() {
//        
//        viewState = .loading
//        authenticationService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<Result<[BookCloud], Error>, Never> in
//                guard let self = self else {
//                    return Just(.success([])).eraseToAnyPublisher()
//                }
//                switch result {
//                case .success(let userId):
//                    
//                    return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//                case .failure(let error):
//                    stateError = .globalError
//                    return Just(.failure(error)).eraseToAnyPublisher()
//                }
//            }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                switch result {
//                case .success(let data):
//                    self?.viewState = .content(data)
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    func retry() {
//        authenticationService.reset()
//        bind()
//    }
//    
//    private func handleError(_ error: Error) {
//        switch stateError {
//        case .localError:
//            handleFirestoreError(error)
//        case .globalError:
//            handleAuthenticationError(error)
//        }
//        stateError = .localError
//    }
//    
//    func removeBook(book: BookCloud, forView:String, operationDescription: String) {
//        managerCRUDS.removeBook(book: book, forView: forView, operationDescription: operationDescription)
//    }
//    
//    private func handleAuthenticationError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: "Error authentication")
//        viewState = .error(errorMessage)
//    }
//    
//    private func handleFirestoreError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView", operationDescription: "Error Database")
//        viewState = .error(errorMessage)
//    }
//}







//    private var databaseService: any DatabaseCRUDServiceProtocol
//    private var databaseService: FirestoreDatabaseCRUDService

//    func removeBook(book: BookCloud) {
//        authenticationService.getCurrentUserID()
//            .sink { [weak self] result in
//                switch result {
//
//                case .success(let userID):
//                    let path = "users/\(userID)/data"
//                    self?.removeBook(book: book, path: path)
//                case .failure(let error):
//                    self?.handleDeleteError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
    
//    private func removeBook(book:BookCloud, path:String) {
//        databaseService.removeBook(path: path, book)
//            .sink { [weak self] result in
//                switch result {
//
//                case .success():
//                    print("removeBook success")
//                    break
//                case .failure(let error):
//                    print("removeBook failure")
//                    self?.handleDeleteError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }

//    private func handleDeleteError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView")
//    }


//        alertManager.showGlobalAlert(message: errorMessage)

//extension ViewState {
//    var isError:Bool {
//        if case .error = self {
//            return true
//        }
//        return false
//    }
//
//    var errorMessage: String? {
//        if case let .error(message) = self {
//            return message
//        }
//        return nil
//    }
//}


//                    self?.handleErrorChangeAuth(error)
//    private func handleErrorChangeAuth(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        viewState = .errorChangeAuth(errorMessage)
//    }


//protocol HomeViewModelProtocol: ObservableObject {
//    var data: [String] { get }
//    var isLoading:Bool { get }
//    var errorMessage: String? { get set }
//    func retry()
//}
//
//
//
//class HomeViewModel: HomeViewModelProtocol {
//    
//    @Published var data: [String] = []
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    
//    private var cancellables = Set<AnyCancellable>()
//    private var authenticationService: AuthenticationServiceProtocol
//    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    
//    init(authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, errorHandler: ErrorHandlerProtocol) {
//        self.authenticationService = authenticationService
//        self.firestorColletionObserverService = firestorColletionObserverService
//        self.errorHandler = errorHandler
//        bind()
//    }
//    
//    func retry() {
//        print("func retry()")
//        self.errorMessage = nil
//        authenticationService.reset()
//        bind()
//    }
//    
//    func bind() {
//        
//        DispatchQueue.main.async {
//            self.isLoading = true
//        }
//        
////        authenticationService.signOutUser()
//        authenticationService.authenticate()
//            .flatMap { [weak self] result -> AnyPublisher<Result<[String], Error>, Never> in
//                guard let self = self else {
//                    return Just(.success([])).eraseToAnyPublisher()
//                }
//                switch result {
//                case .success(let userId):
//                    return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//                case .failure(let error):
//                    return Just(.failure(error)).eraseToAnyPublisher()
//                }
//            }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                switch result {
//                case .success(let data):
//                    self?.data = data
//                    self?.isLoading = false
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//        
//    }
//    
//    private func handleError(_ error: Error) {
//        print("HomeViewModel.handleError - \(error.localizedDescription)")
//        self.errorMessage = errorHandler.handle(error: error)
//        self.isLoading = false
//    }
//    
//    
//}


//            .onDelete { setIndex in
//                let books = setIndex.lazy.map { data[$0] }
//                books.forEach { book in
//                    /// send data to delete
//
//                }
//            }
//    func removeBooks(atOfSets indexSet: IndexSet, data: [BookCloud]) {
//        let books = indexSet.lazy.map { data[$0] }
//        books.forEach { book in
//            authenticationService.getCurrentUserID()
//                .sink { result in
//                    switch result {
//                    case .success(let userId):
//                        let path = "users/\(userId)/data"
//                        self.databaseService.removeBook(path: path, book)
//                            .sink { result in
//                                switch result {
//
//                                case .success():
//                                    <#code#>
//                                case .failure(_):
//                                    <#code#>
//                                }
//                            }
//                    case .failure(let error):
//                        <#code#>
//                    }
//                }
//                .store(in: &cancellables)
//
//        }
//    }
