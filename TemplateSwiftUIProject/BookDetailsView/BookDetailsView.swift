//
//  BookDetailsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 26.11.24.
//

import SwiftUI

struct BookDetailsView: View {
    var book: BookCloud
    
    init(book: BookCloud) {
        print("init BookDetailsView")
        self.book = book
    }
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            Text("BookDetailsView - \(book.title)")
                .font(.system(.largeTitle, design: .rounded, weight: .regular))
                .foregroundStyle(.brown)
        }
        .onAppear {
            print("BookDetailsView onAppear")
        }
        .onDisappear {
            print("BookDetailsView onDisappear")
        }
    }
}


//#Preview {
//    BookDetailsView()
//}
