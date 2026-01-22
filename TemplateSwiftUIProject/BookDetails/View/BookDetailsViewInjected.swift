//
//  BookDetailsViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.01.26.
//

import SwiftUI

struct BookDetailsViewInjected: View {
    
    @StateObject private var viewModel: BookDetailsViewModel
    private let book: BookCloud
    
    init(managerCRUDS: CRUDSManager, book: BookCloud) {
        _viewModel = StateObject(
            wrappedValue: BookDetailsViewModel(managerCRUDS: managerCRUDS)
        )
        self.book = book
        print("init BookDetailsViewInjected - \(String(describing: book.id))")
    }
    
    var body: some View {
        BookDetailsView(viewModel: viewModel, book: book)
    }
}

