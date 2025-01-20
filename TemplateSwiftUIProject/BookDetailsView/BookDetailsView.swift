//
//  BookDetailsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 26.11.24.
//

import SwiftUI


class BookDetailsViewModel:ObservableObject {
    var sheetManager: SheetManager
    var alertManager:AlertManager
    
    init(sheetManager: SheetManager, alertManager:AlertManager) {
        self.sheetManager = sheetManager
        self.alertManager = alertManager
    }
}

struct BookDetailsView: View {
    
    @StateObject var viewModel = BookDetailsViewModel(sheetManager: SheetManager.shared, alertManager: AlertManager.shared)
    @State private var isShowSheet:Bool = false
    
    var book: BookCloud
    
    init(book: BookCloud) {
        print("init BookDetailsView")
        self.book = book
    }
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            VStack {
                Text("title - \(book.title)")
                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
                    .foregroundStyle(.brown)
                Text("title - \(book.description)")
                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
                    .foregroundStyle(.brown)
                Text("title - \(book.author)")
                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
                    .foregroundStyle(.brown)
            }
            
        }
        .sheet(isPresented: $isShowSheet) {
//            BookEditView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    
                }
            }
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
