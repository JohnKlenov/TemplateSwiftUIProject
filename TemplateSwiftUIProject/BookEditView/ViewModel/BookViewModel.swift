//
//  BookViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//

import Foundation
import Combine

class BookViewModel:ObservableObject {
    
    @Published var book: Book
    @Published var modified = false
    
    private var originalBook: Book
    private var cancellables = Set<AnyCancellable>()
    
    init(book:Book = Book(title: "", author: "", description: "", pathImage: ""), mode:Mode = .new) {
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
    
    deinit {
        print("deinit BookViewModel")
    }
}
