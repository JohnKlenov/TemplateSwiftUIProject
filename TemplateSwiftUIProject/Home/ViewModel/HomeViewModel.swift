//
//  HomeViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.10.24.
//

import Combine
import SwiftUI

protocol HomeViewModelProtocol: ObservableObject {
    var data: [String] { get }
    var isLoading:Bool { get }
    var errorMessage: String? { get set }
    func retry()
}



class HomeViewModel: HomeViewModelProtocol {
    
    @Published var data: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var authenticationService: AuthenticationServiceProtocol
    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
    
    init(authenticationService: AuthenticationServiceProtocol, firestorColletionObserverService: FirestoreCollectionObserverProtocol) {
        self.authenticationService = authenticationService
        self.firestorColletionObserverService = firestorColletionObserverService
        bind()
    }
    
    func retry() {
        authenticationService.reset()
        bind()
    }
    
    func bind() {
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        authenticationService.authenticate()
            .flatMap { [weak self] result -> AnyPublisher<Result<[String], Error>, Never> in
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
                    self?.data = data
                    self?.isLoading = false
                case .failure(let error):
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
        
    }
    
    private func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.isLoading = false
    }
    
    
}


