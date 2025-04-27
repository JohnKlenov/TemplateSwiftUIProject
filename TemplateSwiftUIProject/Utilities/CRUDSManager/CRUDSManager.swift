//
//  CRUDSManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 11.12.24.
//

import Foundation
import Combine

//protocol CRUDSManagerProtocol:ObservableObject {
//    func updateOrAddBook(book: BookCloud, forView:String, operationDescription: String)
//    func removeBook(book: BookCloud, forView:String, operationDescription: String)
//}

//:CRUDSManagerProtocol

class CRUDSManager {
    
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
        print("init CRUDSManager")
    }
    
    /// во входных параметрах должны передовать из какого rootView происходит операция и какая эта операция
    func updateOrAddBook(book: BookCloud, forView:String, operationDescription: String) {
        authService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                    
                case .success(let uid):
                    let path = "users/\(uid)/data"
                    if let _ = book.id {
                        self?.updateBook(path: path, book: book, forView: forView, operationDescription: operationDescription)
                    } else {
                        self?.addBook(path: path, book: book, forView: forView, operationDescription: operationDescription)
                    }
                case .failure(let error):
                    self?.handleError(error, forView: forView, operationDescription: operationDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    /// во входных параметрах должны передовать из какого rootView происходит операция и какая эта операция
    func removeBook(book: BookCloud, forView:String, operationDescription: String) {
        authService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                    
                case .success(let userID):
                    let path = "users/\(userID)/data"
                    self?.removeBook(book: book, path: path, forView: forView, operationDescription: operationDescription)
                case .failure(let error):
                    self?.handleError(error, forView: forView, operationDescription: operationDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    private func addBook(path:String, book:BookCloud, forView:String, operationDescription: String) {
        databaseService.addBook(path: path, book)
            .sink { [weak self] result in
                switch result {
                    
                case .success(_):
                    print("success addBook")
                    break
                case .failure(let error):
                    self?.handleError(error, forView: forView, operationDescription: operationDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateBook(path:String, book:BookCloud, forView:String, operationDescription: String) {
        databaseService.updateBook(path: path, book)
            .sink { [weak self] result in
                switch result {
                    
                case .success():
                    print("success updateBook")
                    break
                case .failure(let error):
                    self?.handleError(error, forView: forView, operationDescription: operationDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    private func removeBook(book:BookCloud, path:String, forView:String, operationDescription: String) {
        databaseService.removeBook(path: path, book)
            .sink { [weak self] result in
                switch result {
                    
                case .success():
                    print("removeBook success")
                    break
                case .failure(let error):
                    print("removeBook failure")
                    self?.handleError(error, forView: forView, operationDescription: operationDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    /// мы не должны перезатерать ошибки?
    /// так же мы должны передавать имя того корневого view из которого пришла ошибка!
    private func handleError(_ error: Error, forView:String, operationDescription: String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .common)
    }
    
    deinit {
        print("deinit CRUDSManager")
    }
}




// MARK: - before func resetFirstLocalAlert -

//import Foundation
//import Combine
//
//protocol CRUDSManagerProtocol:ObservableObject {
//    func updateOrAddBook(book: BookCloud)
//    func removeBook(book: BookCloud)
//}
//
//class CRUDSManager:CRUDSManagerProtocol {
//    
//    private var authService:AuthServiceProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    private var databaseService:any DatabaseCRUDServiceProtocol
//    private var alertManager:AlertManager
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    init(authService: AuthServiceProtocol, errorHandler: ErrorHandlerProtocol, databaseService: any DatabaseCRUDServiceProtocol, alertManager: AlertManager = AlertManager.shared) {
//        self.authService = authService
//        self.errorHandler = errorHandler
//        self.databaseService = databaseService
//        self.alertManager = alertManager
//        print("init CRUDSManager")
//    }
//    
//    /// во входных параметрах должны передовать из какого rootView происходит операция и какая эта операция
//    func updateOrAddBook(book: BookCloud) {
//        authService.getCurrentUserID()
//            .sink { [weak self] result in
//                switch result {
//                    
//                case .success(let uid):
//                    let path = "users/\(uid)/data"
//                    if let _ = book.id {
//                        self?.updateBook(path: path, book: book)
//                    } else {
//                        self?.addBook(path: path, book: book)
//                    }
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    /// во входных параметрах должны передовать из какого rootView происходит операция и какая эта операция
//    func removeBook(book: BookCloud) {
//        authService.getCurrentUserID()
//            .sink { [weak self] result in
//                switch result {
//                    
//                case .success(let userID):
//                    let path = "users/\(userID)/data"
//                    self?.removeBook(book: book, path: path)
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func addBook(path:String, book:BookCloud) {
//        databaseService.addBook(path: path, book)
//            .sink { [weak self] result in
//                switch result {
//                    
//                case .success(_):
//                    print("success addBook")
//                    break
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func updateBook(path:String, book:BookCloud) {
//        databaseService.updateBook(path: path, book)
//            .sink { [weak self] result in
//                switch result {
//                    
//                case .success():
//                    print("success updateBook")
//                    break
//                case .failure(let error):
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
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
//                    self?.handleError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    /// мы не должны перезатерать ошибки?
//    /// так же мы должны передавать имя того корневого view из которого пришла ошибка!
//    private func handleError(_ error: Error) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showLocalalAlert(message: errorMessage, forView: "HomeView")
//    }
//    
//    deinit {
//        print("deinit CRUDSManager")
//    }
//}
