//
//  MainCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.01.25.
//

import Foundation
import SwiftUI
import Combine

class MainCoordinator:ObservableObject {
    
    var tabViewSwitcher = TabViewSwitcher()
    var homeCoordinator = HomeCoordinator()
    var viewBuilder = ViewBuilderService()
}

class TabViewSwitcher:ObservableObject {
    @Published var tabSelection:Int = 0
}

class HomeCoordinator:ObservableObject {
    
    @Published var path: NavigationPath = NavigationPath() {
        didSet {
            print("NavigationPath updated: \(path.count)")
        }
    }
    @Published var sheet:SheetItem?
    @Published var fullScreenItem:FullScreenItem?
    
    func navigateTo(page:HomeFlow) {
        path.append(page)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func presentSheet(_ sheet: SheetItem) {
        self.sheet = sheet
    }
    
    func presentFullScreenCover(_ cover: FullScreenItem) {
        self.fullScreenItem = cover
    }
    
    func dismissSheet() {
        self.sheet = nil
    }
    
    func dismissCover() {
        self.fullScreenItem = nil
    }
}

struct ViewBuilderService {
    
    private var crudManager = CRUDSManager(
        authService: AuthService(),
        errorHandler: SharedErrorHandler(),
        databaseService: FirestoreDatabaseCRUDService()
    )
    
    @ViewBuilder func homeViewBuild(page:HomeFlow) -> some View {
        switch page {
            
        case .home:
            HomeContentView(managerCRUDS: crudManager)
        case .bookDetails(let book):
            BookDetailsView(managerCRUDS: crudManager, book: book)
        case .someHomeView:
            EmptyView()
        }
    }
    
    @ViewBuilder
    func buildSheet(sheet: SheetItem) -> some View {
        sheet.content
    }
    
    @ViewBuilder
    func buildCover(cover: FullScreenItem) -> some View {
        cover.content
    }
}


///В твоем коде, HomeFlow используется в качестве значения в NavigationPath, что требует соответствия протоколам Hashable и Equatable.
///NavigationPath использует хэширование для хранения и отслеживания пути. Это означает, что типы значений, передаваемые в NavigationPath, должны быть Hashable и Equatable.
///Протокол Equatable используется для сравнения экземпляров одного и того же типа. Если тип соответствует Equatable, это означает, что экземпляры этого типа можно сравнивать с помощью оператора ==.
///Протокол Hashable используется для создания хэш-кода для объекта. Если тип соответствует Hashable, это означает, что экземпляры этого типа можно хэшировать, что требуется для использования в структурах данных, таких как словари и множества.


enum HomeFlow: Hashable, Equatable {
    case home
    case bookDetails(BookCloud)
    case someHomeView

    static func == (lhs: HomeFlow, rhs: HomeFlow) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.someHomeView, .someHomeView):
            return true
        case (.bookDetails(let lhsBook), .bookDetails(let rhsBook)):
            return lhsBook == rhsBook
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .someHomeView:
            hasher.combine("someHomeView")
        case .bookDetails(let book):
            hasher.combine(book)
        }
    }
}

struct SheetItem: Identifiable {
    var id = UUID()
    var content: AnyView
}

struct FullScreenItem: Identifiable {
    var id = UUID()
    var content: AnyView
}


//enum Sheet: String, Identifiable {
//    var id: String {
//        self.rawValue
//    }
//    
//    case bookEdit
//}


//import SwiftUI
//
//// Определяем различные шаги навигации
//enum AppPages: Hashable {
//    case main
//    case login
//    case bookDetails(BookCloud)  // Передача объекта
//    case authorDetails(String)   // Передача строки
//    case profile                 // Простой случай
//}
//
//class Coordinator: ObservableObject {
//    @Published var path = NavigationPath()
//    @Published var sheet: Sheet?
//    @Published var fullScreenCover: FullScreenCover?
//
//    func navigateTo(page: AppPages) {
//        path.append(page)
//    }
//
//    func pop() {
//        path.removeLast()
//    }
//
//    func popToRoot() {
//        path = NavigationPath()
//    }
//
//    func presentSheet(_ sheet: Sheet) {
//        self.sheet = sheet
//    }
//
//    func presentFullScreenCover(_ cover: FullScreenCover) {
//        self.fullScreenCover = cover
//    }
//
//    func dismissSheet() {
//        self.sheet = nil
//    }
//
//    func dismissCover() {
//        self.fullScreenCover = nil
//    }
//}
//
//@ViewBuilder
//func build(page: AppPages) -> some View {
//    switch page {
//    case .main:
//        HomeContentView()
//    case .login:
//        LoginView()
//    case let .bookDetails(book):
//        BookDetailsView(book: book)  // Страница деталей книги
//    case let .authorDetails(authorName):
//        AuthorDetailsView(authorName: authorName)  // Страница автора
//    case .profile:
//        ProfileView()
//    }
//}
//
//struct AuthorDetailsView: View {
//    let authorName: String
//
//    var body: some View {
//        Text("Author: \(authorName)")
//            .navigationTitle("Author Details")
//    }
//}

// Пример использования различных типов в NavigationPath
//struct HomeContentView: View {
//    @EnvironmentObject var coordinator: Coordinator
//    @ObservedObject var viewModel: HomeViewModel
//    
//    var body: some View {
//        contentView(data: viewModel.books)
//    }
//
//    private func contentView(data: [BookCloud]) -> some View {
//        List(data) { book in
//            bookRowView(book)
//                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                    Button(role: .destructive) {
//                        viewModel.removeBook(book: book, forView: "HomeView", operationDescription: "Error deleting book")
//                    } label: {
//                        Label("delete", systemImage: "trash.fill")
//                    }
//                }
//        }
//    }
//
//    private func bookRowView(_ book: BookCloud) -> some View {
//        VStack {
//            HStack(spacing: 10) {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                
//                VStack(alignment: .leading) {
//                    Text(book.title)
//                        .font(.headline)
//                    Text(book.description)
//                        .font(.subheadline)
//                    Text(book.author)
//                        .font(.subheadline)
//                }
//                Spacer()
//            }
//            .contentShape(Rectangle())
//            .onTapGesture {
//                coordinator.navigateTo(page: .bookDetails(book))  // Передача объекта
//            }
//            .onLongPressGesture {
//                coordinator.navigateTo(page: .authorDetails(book.author))  // Передача строки
//            }
//        }
//    }
//}



//class Coordinator: ObservableObject {
//    @Published var path: NavigationPath = NavigationPath()
//    @Published var sheet: SheetItem?
//    @Published var fullScreenCover: FullScreenItem?
//    
//    func navigateTo(page: AppPages) {
//        path.append(page)
//    }
//    
//    func presentSheet(_ sheet: SheetItem) {
//        self.sheet = sheet
//    }
//    
//    func dismissSheet() {
//        self.sheet = nil
//    }
//    
//    func presentFullScreenCover(_ cover: FullScreenItem) {
//        self.fullScreenCover = cover
//    }
//    
//    func dismissFullScreenCover() {
//        self.fullScreenCover = nil
//    }
//}
//
//struct SheetItem: Identifiable {
//    var id = UUID()
//    var content: AnyView
//}
//
//struct FullScreenItem: Identifiable {
//    var id = UUID()
//    var content: AnyView
//}
