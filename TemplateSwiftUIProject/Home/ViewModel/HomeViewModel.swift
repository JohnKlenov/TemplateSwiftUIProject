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
    case errorChangeAuth(String)
    case content([BookCloud])
}


extension ViewState {
    var isError:Bool {
        if case .errorChangeAuth = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case let .errorChangeAuth(message) = self {
            return message
        }
        return nil
    }
}



protocol HomeViewModelProtocol: ObservableObject {
    var viewState: ViewState { get }
    var isSheetActive:Bool { get set }
//    var showAlert:Bool { get set }
//    var alertMessage:String? { get set }
    func removeBook(book: BookCloud)
    func retry()
//    func resetErrorProperty()
}


class HomeViewModel: HomeViewModelProtocol {
    
    private var alertManager = AlertManager.shared
    @Published var viewState: ViewState = .loading
    var isSheetActive = false 
    
//    @Published var showAlert = false
//    @Published var alertMessage:String?
    
    private var cancellables = Set<AnyCancellable>()
    private var authenticationService: AuthenticationServiceProtocol
    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
    private var databaseService:DatabaseCRUDServiceProtocol
    private let errorHandler: ErrorHandlerProtocol
    
    init(authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, databaseService:DatabaseCRUDServiceProtocol, errorHandler: ErrorHandlerProtocol) {
        self.authenticationService = authenticationService
        self.firestorColletionObserverService = firestorColletionObserverService
        self.errorHandler = errorHandler
        self.databaseService = databaseService
        bind()
    }
    
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
                    return Just(.failure(error)).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success(let data):
                    self?.viewState = .content(data)
                case .failure(let error):
                    self?.handleErrorChangeAuth(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func retry() {
        authenticationService.reset()
        bind()
    }
    
    func removeBook(book: BookCloud) {
        authenticationService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                    
                case .success(let userID):
                    let path = "users/\(userID)/data"
                    self?.removeBook(book: book, with: path)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func removeBook(book:BookCloud, with path:String) {
        databaseService.removeBook(path: path, book)
            .sink { [weak self] result in
                switch result {
                    
                case .success():
                    print("removeBook success")
                    break
                case .failure(let error):
                    print("removeBook  error - \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func handleErrorChangeAuth(_ error: Error) {
//        print("HomeViewModel.handleError - \(error.localizedDescription)")
        let errorMessage = errorHandler.handle(error: error)
        viewState = .errorChangeAuth(errorMessage)
    }
    
    private func handleError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView")
//        alertMessage = errorMessage
//        showAlert = true
    }
    
//    func resetErrorProperty() {
//        print("resetErrorProperty()")
//        alertMessage = nil
//        showAlert = false
//    }
}



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
