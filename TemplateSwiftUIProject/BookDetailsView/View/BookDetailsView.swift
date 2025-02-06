//
//  BookDetailsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 26.11.24.
//
//
import SwiftUI

struct BookDetailsView: View {
    
    @EnvironmentObject var homeCoordinator:HomeCoordinator
    @EnvironmentObject var homeBookDataStore:HomeBookDataStore
    @StateObject var viewModel:BookDetailsViewModel
    @Environment(\.dismiss) var dismiss
    @State var bookID: String
    
    init(managerCRUDS: CRUDSManager, bookID: String) {
        _viewModel = StateObject(wrappedValue: BookDetailsViewModel(managerCRUDS: managerCRUDS))
        self.bookID = bookID
        print("init BookDetailsView - \(bookID)")
    }
    
    var body: some View {
        if let book = homeBookDataStore.books.first(where: { $0.id == bookID}) {
            content(book: book)
        } else {
            Text("Book not found")
        }
    }
    
    private func content(book:BookCloud) -> some View {
        ZStack {
            //            let _ = Self._printChanges()
            Color.clear
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
                Button("GoToSomeView") {
                    homeCoordinator.navigateTo(page: .someHomeView)
                }
            }
            
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    ///Для struct использование [weak self] не требуется, так как они не создают циклов удержания.
                    ///Замыкания в вашем коде безопасны, если они не создают сильных ссылок на объекты (class) внутри себя.
                    let sheetContent = AnyView(BookEditView(book: book, mode: .edit, managerCRUDS: viewModel.crudManager, presentEditView: "HomeView") {  result in
                        switch result {
                        case .success(let action):
                            handleEditCompletion(action: action)
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    })
                    homeCoordinator.presentSheet(SheetItem(content: sheetContent))
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
    
    private func handleEditCompletion(action: Action) {
        switch action {
        case .done:
            break
        case .delete:
            dismiss()
        case .cancel:
            break
        }
    }
}




// MARK: - before HomeBookDataStore

//import SwiftUI
//
//class BookDetailsViewModel:ObservableObject {
//    var crudManager: CRUDSManager
//    
//    init(managerCRUDS: CRUDSManager) {
//        print("init BookDetailsViewModel")
//        self.crudManager = managerCRUDS
//    }
//    
//    deinit {
//        print("deinit BookDetailsViewModel")
//    }
//}
//
//struct BookDetailsView: View {
//    
//    @State private var isShowSheet:Bool = false
////    @EnvironmentObject private var crudManager: CRUDSManager
//    @EnvironmentObject var homeCoordinator:HomeCoordinator
//    @StateObject var viewModel:BookDetailsViewModel
//    @Environment(\.dismiss) var dismiss
//    @State var book: BookCloud
//    
//    init(managerCRUDS: CRUDSManager, book: BookCloud) {
//        _viewModel = StateObject(wrappedValue: BookDetailsViewModel(managerCRUDS: managerCRUDS))
//        self.book = book
//        print("init BookDetailsView - \(book.author)")
//    }
//    
//    var body: some View {
//        ZStack {
////            let _ = Self._printChanges()
//            Color.clear
//                .ignoresSafeArea()
//            VStack {
//                Text("title - \(book.title)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//                Text("title - \(book.description)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//                Text("title - \(book.author)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//                Button("GoToSomeView") {
//                    homeCoordinator.navigateTo(page: .someHomeView)
//                }
//            }
//            
//        }
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Edit") {
//                    ///Для struct использование [weak self] не требуется, так как они не создают циклов удержания.
//                    ///Замыкания в вашем коде безопасны, если они не создают сильных ссылок на объекты (class) внутри себя.
//                    let sheetContent = AnyView(BookEditView(book: book, mode: .edit, managerCRUDS: viewModel.crudManager, presentEditView: "HomeView") {  result in
//                        switch result {
//                        case .success(let (action, bookCloud)):
//                            handleEditCompletion(action: action, book: bookCloud)
//                        case .failure(let error):
//                            print("Error: \(error)")
//                        }
//                    })
//                    homeCoordinator.presentSheet(SheetItem(content: sheetContent))
//                }
//            }
//        }
//        .onAppear {
//            print("BookDetailsView onAppear")
//        }
//        .onDisappear {
//            print("BookDetailsView onDisappear")
//        }
//    }
//    
//    private func handleEditCompletion(action: Action, book: BookCloud) {
//        switch action {
//        case .done:
//            self.book = book
//        case .delete:
//            dismiss()
//        case .cancel:
//            break
//        }
//    }
//}



// MARK: - before pattern Coordinator


//import SwiftUI
//
//
//
//struct BookDetailsView: View {
//    
//    @State private var isShowSheet:Bool = false
//    @EnvironmentObject private var crudManager: CRUDSManager
//    @Environment(\.dismiss) var dismiss
//    @State var book: BookCloud
//    
//    init(book: BookCloud) {
//        print("init BookDetailsView")
//        self.book = book
//    }
//    
//    var body: some View {
//        ZStack {
////            let _ = Self._printChanges()
//            Color.clear
//                .ignoresSafeArea()
//            VStack {
//                Text("title - \(book.title)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//                Text("title - \(book.description)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//                Text("title - \(book.author)")
//                    .font(.system(.largeTitle, design: .rounded, weight: .regular))
//                    .foregroundStyle(.brown)
//            }
//            
//        }
//        .sheet(isPresented: $isShowSheet) {
//            ///Для struct использование [weak self] не требуется, так как они не создают циклов удержания.
//            ///Замыкания в вашем коде безопасны, если они не создают сильных ссылок на объекты (class) внутри себя.
//            BookEditView(book: book, mode: .edit, managerCRUDS: crudManager, presentEditView: "HomeView") {  result in
//                switch result {
//                case .success(let (action, bookCloud)):
//                    handleEditCompletion(action: action, book: bookCloud)
//                case .failure(let error):
//                    print("Error: \(error)")
//                }
//                //                isShowSheet = false // Закрытие листа после завершения
//            }
//        }
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Edit") {
//                    isShowSheet = true
//                }
//            }
//        }
//        .onAppear {
//            print("BookDetailsView onAppear")
//        }
//        .onDisappear {
//            print("BookDetailsView onDisappear")
//        }
//    }
//    
//    private func handleEditCompletion(action: Action, book: BookCloud) {
//        switch action {
//        case .done:
//            self.book = book
//        case .delete:
//            dismiss()
//        case .cancel:
//            break
//        }
//    }
//}


//#Preview {
//    BookDetailsView()
//}


//@StateObject var viewModel = BookDetailsViewModel(sheetManager: SheetManager.shared, alertManager: AlertManager.shared)
//class BookDetailsViewModel:ObservableObject {
//    var sheetManager: SheetManager
//    var alertManager:AlertManager
//    
//    init(sheetManager: SheetManager, alertManager:AlertManager) {
//        self.sheetManager = sheetManager
//        self.alertManager = alertManager
//    }
//    
//    deinit {
//        print("deinit BookDetailsViewModel")
//    }
//}

//struct HomeView: View {
//    @StateObject private var viewModel: HomeViewModel
//    @State private var isShowSheet: Bool = false
//    @State private var book: BookCloud = BookCloud(title: "", author: "", description: "", pathImage: "")
//    @State private var alertMessage: String = ""
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    init() {
//        _viewModel = StateObject(wrappedValue: HomeViewModel(sheetManager: SheetManager.shared, alertManager: AlertManager.shared))
//    }
//    
//    var body: some View {
//        VStack {
//            Button("Edit Book") {
//                isShowSheet.toggle()
//            }
//        }
//        .sheet(isPresented: $isShowSheet) {
//            BookEditView(book: book, mode: .edit, managerCRUDS: CRUDSManager()) { result in
//                switch result {
//                case .success(let (action, bookCloud)):
//                    handleEditCompletion(action: action, book: bookCloud)
//                case .failure(let error):
//                    print("Error: \(error)")
//                }
//                isShowSheet = false
//            }
//        }
//    }
//    
//    private func handleEditCompletion(action: Action, book: BookCloud) {
//        switch action {
//            case .done:
//                // Логика при завершении изменения или добавления книги
//                print("Book edited or added: \(book)")
//            case .delete:
//                // Логика при удалении книги
//                print("Book deleted: \(book)")
//            case .cancel:
//                // Логика при отмене действия
//                print("Editing cancelled")
//        }
//    }
//}


//
//struct SheetView: View {
//
//    init() {
//        print("init SheetView")
//    }
//    var body: some View {
//        ZStack {
//            Color.orange.ignoresSafeArea()
//        }
//    }
//}
//
//// Детальный View для отображения информации о книге
//struct BookDetailsView: View {
//    let book: BookCloud
//    @State private var isShowSheet:Bool = false
//    @EnvironmentObject private var crudManager: CRUDSManager
//    @Environment(\.dismiss) var dismiss
//
//    init(book: BookCloud) {
//        print("init BookDetailsView")
//        self.book = book
//    }
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//
//            Text(book.title)
//                .font(.largeTitle)
//                .fontWeight(.bold)
//            Text("Author: \(book.author)")
//                .font(.title3)
//                .foregroundColor(.secondary)
//            Text(book.description)
//                .font(.body)
//                .padding(.top, 8)
//            Button("Edit") {
//                self.isShowSheet = true
//            }
//            Spacer()
//        }
//        .sheet(isPresented: $isShowSheet) {
//            BookEditView(book: book, mode: .edit, managerCRUDS: crudManager)
//        }
//        .padding()
//        .navigationTitle("Book Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}

//            BookEditView(book: book, mode: .edit, managerCRUDS: crudManager) { result in
//                switch result {
//                case .success(let (action, bookCloud)):
//                    switch action {
//                    case .done:
//                        // Обработка сохранения книги
////                        if let book = bookCloud {
////                            self.book = book
////                        }
//                        print("Book saved: \(String(describing: bookCloud))")
//                    case .delete:
//                        // Обработка удаления книги
//                        print("Book deleted: \(String(describing: bookCloud))")
////                        dismiss()
//                    case .cancel:
//                        // Обработка отмены
//                        print("Editing cancelled")
//                    }
//                case .failure(let error):
//                    print("Error: \(error)")
//                }
////                isShowSheet = false // Закрытие листа после завершения
//            }
//            SheetView()
