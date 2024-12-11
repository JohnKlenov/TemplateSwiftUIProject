//
//  CRUDSManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 11.12.24.
//

import Foundation
import Combine

protocol CRUDSManagerProtocol:ObservableObject {
    func updateOrAddBook(book: BookCloud)
    func removeBook(book: BookCloud)
}

class CRUDSManager:CRUDSManagerProtocol {
    
    private var authService:AuthServiceProtocol
    private let errorHandler: ErrorHandlerProtocol
    private var databaseService:any DatabaseCRUDServiceProtocol
    private var alertManager:AlertManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthServiceProtocol, errorHandler: ErrorHandlerProtocol, databaseService: any DatabaseCRUDServiceProtocol, alertManager: AlertManager = AlertManager.shared) {
        self.authService = authService
        self.errorHandler = errorHandler
        self.databaseService = databaseService
        self.alertManager = alertManager
    }
    func updateOrAddBook(book: BookCloud) {
        <#code#>
    }
    
    func removeBook(book: BookCloud) {
        authService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                    
                case .success(let userID):
                    let path = "users/\(userID)/data"
                    self?.removeBook(book: book, path: path)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func removeBook(book:BookCloud, path:String) {
        databaseService.removeBook(path: path, book)
            .sink { [weak self] result in
                switch result {
                    
                case .success():
                    print("removeBook success")
                    break
                case .failure(let error):
                    print("removeBook failure")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView")
    }
    
}
