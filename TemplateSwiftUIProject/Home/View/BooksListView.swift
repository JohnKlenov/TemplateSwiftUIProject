//
//  BooksListView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.02.25.
//

import SwiftUI

struct BooksListView: View {
    let data: [BookCloud]
    let removeBookAction: (BookCloud) -> Void
    
    var body: some View {
        List(data) { book in
            BookRowView(book: book)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeBookAction(book)
                    } label: {
                        Label(Localized.Home.BookRowView.swipeActionsDelete, systemImage: "trash.fill")
                    }
                }
        }
    }
}


