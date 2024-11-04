//
//  BookViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//

import Foundation

class BookViewModel:ObservableObject {
    
    @Published var book: Book
    @Published var modified = false
    
    init(book:Book = Book(title: "", author: "", description: "", pathImage: "")) {
        self.book = book
    }
    
}
