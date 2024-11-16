//
//  BookViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//


///Один Set<AnyCancellable> служит контейнером для всех подписок в вашем классе. Это упрощает управление подписками и гарантирует, что они будут оставаться активными до тех пор, пока существует контейнер (в данном случае, до тех пор, пока существует ViewModel).
///Управление памятью: Когда вы добавляете объект AnyCancellable в Set, он сохраняется в памяти до тех пор, пока существует этот Set. Когда Set (или объект, которому он принадлежит) уничтожается, все подписки автоматически отменяются.

import Foundation
import Combine


enum OperationState {
    case idle
    case loading
    case success
    case failure(String)
}

class BookViewModel:ObservableObject {
    
    @Published var book: BookRealtime
    @Published var modified = false
    @Published var operationState: OperationState = .idle
    
    private var databaseService:DatabaseCRUDServiceProtocol
    private var authService:AuthServiceProtocol
    private let errorHandler: ErrorHandlerProtocol
    private var originalBook: BookRealtime
    private var cancellables = Set<AnyCancellable>()
    
    init(book:BookRealtime = BookRealtime(title: "", author: "", description: "", pathImage: ""), mode:Mode = .new, databaseService: DatabaseCRUDServiceProtocol, authService:AuthServiceProtocol, errorHandler: ErrorHandlerProtocol) {
        
        self.databaseService = databaseService
        self.authService = authService
        self.errorHandler = errorHandler
        
        self.book = book
        self.originalBook = book
        
        $book
            .sink { [weak self] _ in
                self?.validateFields(for: mode)
            }
            .store(in: &self.cancellables)
    }
    
    private func validateFields(for mode:Mode) {
        switch mode {
            
        case .new:
            self.modified = !book.title.isEmpty && !book.author.isEmpty && !book.description.isEmpty && !book.pathImage.isEmpty
        case .edit:
            self.modified = !book.title.isEmpty && !book.author.isEmpty && !book.description.isEmpty && !book.pathImage.isEmpty && (book.title != originalBook.title || book.author != originalBook.author || book.description != originalBook.description || book.pathImage != originalBook.pathImage)
        }
    }

    // Обновление или добавление книги
    func updateOrAddBook() {
        operationState = .loading
        authService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                    
                case .success(let userID):
                    let path = "users/\(userID)/data"
                    if let _ = self?.book.id {
                        self?.updateBook(with: path)
                    } else {
                        self?.addBook(with: path)
                    }
                case .failure(let error):
                    guard let self = self else {
                        return
                    }
                    let textError = self.errorHandler.handle(error: error)
                    self.operationState = .failure(textError)
                }
            }
            .store(in: &self.cancellables)
    }
    
    // Удаление книги
    func removeBook() {
        operationState = .loading
        authService.getCurrentUserID()
            .sink { [weak self] result in
                switch result {
                case .success(let userID):
                    let path = "users/\(userID)/data"
                    self?.remove(with: path)
                case .failure(let error):
                    guard let self = self else {
                        return
                    }
                    let textError = self.errorHandler.handle(error: error)
                    self.operationState = .failure(textError)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateBook(with path:String) {
        databaseService.updateBook(path: path, book)
            .sink { [weak self] result in
                self?.handleDatabaseResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func addBook(with path:String) {
        databaseService.addBook(path: path, book)
            .sink { [weak self] result in
                self?.handleDatabaseResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func remove(with path:String) {
        databaseService.removeBook(path: path, book)
            .sink { [weak self] result in
                self?.handleDatabaseResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func handleDatabaseResult(_ result:Result<Void,Error>) {
        switch result {
            
        case .success():
            operationState = .success
        case .failure(let error):
            let textError = errorHandler.handle(error: error)
            operationState = .failure(textError)
        }
    }
    
    deinit {
        print("deinit BookViewModel")
    }
}
