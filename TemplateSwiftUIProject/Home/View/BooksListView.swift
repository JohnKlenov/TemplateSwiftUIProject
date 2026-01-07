//
//  BooksListView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.02.25.
//

import SwiftUI

struct BooksListView: View {
    @EnvironmentObject var localization: LocalizationService
    let data: [BookCloud]
    let removeBookAction: (BookCloud) -> Void
    
    var body: some View {
        List(data) { book in
            BookRowView(book: book)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeBookAction(book)
                    } label: {
                        Label(Localized.Home.BookRowView.swipeActionsDelete.localized(), systemImage: "trash.fill")
                    }
                }
        }
    }
}



