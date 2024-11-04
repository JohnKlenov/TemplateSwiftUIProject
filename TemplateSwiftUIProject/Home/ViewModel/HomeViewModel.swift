//
//  HomeViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.10.24.
//

import Combine
import SwiftUI


enum ViewState {
    case loading
    case error(String)
    case content([Book])
}

protocol HomeViewModelProtocol: ObservableObject {
    var viewState: ViewState { get }
    func retry()
}


class HomeViewModel: HomeViewModelProtocol {
    @Published var viewState: ViewState = .loading
    
    private var cancellables = Set<AnyCancellable>()
    private var authenticationService: AuthenticationServiceProtocol
    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
    private let errorHandler: ErrorHandlerProtocol
    
    init(authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol, errorHandler: ErrorHandlerProtocol) {
        self.authenticationService = authenticationService
        self.firestorColletionObserverService = firestorColletionObserverService
        self.errorHandler = errorHandler
        bind()
    }
    
    func bind() {
        viewState = .loading
        
        //        authenticationService.signOutUser()
        authenticationService.authenticate()
            .flatMap { [weak self] result -> AnyPublisher<Result<[Book], Error>, Never> in
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
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func retry() {
        print("func retry()")
        authenticationService.reset()
        bind()
    }
    
    private func handleError(_ error: Error) {
        print("HomeViewModel.handleError - \(error.localizedDescription)")
        let errorMessage = errorHandler.handle(error: error)
        viewState = .error(errorMessage)
        
    }
    
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


