//
//  HomeContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.12.24.
//


/// так как observer firebase при отсутствии интернета не изменит свое состояние а при его появлении не отобразит минувшие изменения
/// то нам нужно предусмотреть refresh вызывав viewModel.retry() потянув за list сверху вниз.

import SwiftUI

struct HomeContentView:View {
    
    @StateObject private var viewModel: HomeContentViewModel
    @EnvironmentObject var homeDataStore:HomeBookDataStore
    @EnvironmentObject var homeCoordinator:HomeCoordinator
    
    init(managerCRUDS: CRUDSManager) {
        _viewModel = StateObject(wrappedValue: HomeContentViewModel(
            authenticationService: AuthenticationService(),
            firestorColletionObserverService: FirestoreCollectionObserverService(),
            managerCRUDS: managerCRUDS,
            errorHandler: SharedErrorHandler()))
        print("init HomeContentView")
    }
    
    var body: some View {
//            let _ = Self._printChanges()
            ZStack {
                switch viewModel.viewState {
                case .loading:
                    ProgressView("Loading...")
                case .content(let data):
                    contentView(data: data)
                case .error(let error):
                    errorView(error: error)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Home")
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let sheetContent = AnyView(BookEditView(managerCRUDS: viewModel.managerCRUDS as! CRUDSManager, presentEditView: "HomeView"))
                        homeCoordinator.presentSheet(SheetItem(content: sheetContent))
                    }
                    .foregroundStyle(AppColors.activeColor)
                    .padding()
                    .disabled(viewModel.viewState.isError)
                }
            }
            .onFirstAppear {
                print("onFirstAppear HomeContentView")
                viewModel.setupViewModel(dataStore: homeDataStore)
            }
            .onAppear {
                print("onAppear HomeContentView")
            }
            .onDisappear {
                print("onDisappear HomeContentView")
                
            }
            .task {
                print("task HomeContentView")
            }
//        }
    }
    
    /// так как errorView заполняет пространство при первом старте или неожиданно возникшей ошибкой уже после успеха
    /// но дублируется локальным или гобальным алертам
    /// мы должны сделать его контент подходящим для любой ситуации
    private func errorView(error:String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView(label: {
                
                Label("Ups :(", systemImage: "exclamationmark.triangle")
            }, description: {
                Text("Try again! Something went wrong!")
            }, actions: {
                Button("Refresh") {
                    viewModel.retry()
                }
            })
            //            .background(AppColors.secondaryBackground)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .ignoresSafeArea(edges: [.horizontal])
    }
    
    private func contentView(data:[BookCloud]) -> some View {
        List(data) { book in
            bookRowView(book)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.removeBook(book: book, forView: "HomeView", operationDescription: "Error deleting book")
                    } label: {
                        Label("delete", systemImage: "trash.fill")
                    }
                }
        }
    }
    
    private func bookRowView(_ book: BookCloud) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "swift")
                    .foregroundStyle(.pink)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.description)
                        .font(.subheadline)
                    Text(book.author)
                        .font(.subheadline)
                }
                Spacer()
            }
            .onTapGesture {
                if let id = book.id {
                    homeCoordinator.navigateTo(page: .bookDetails(id))
                }
            }
        }
    }
}

//        NavigationLink(destination: BookDetailsView(book: book)) {
//            VStack {
//                HStack(spacing: 10) {
//                    Image(systemName: "swift")
//                        .foregroundStyle(.pink)
//                        .frame(width: 30, height: 30)
//
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.description)
//                            .font(.subheadline)
//                        Text(book.author)
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                }
//            }
//        }

// MARK: - before pattern Coordinator


//import SwiftUI
//
//struct HomeContentView:View {
//    
//    @StateObject private var viewModel: HomeContentViewModel
//    
//    init(managerCRUDS: CRUDSManager) {
//        _viewModel = StateObject(wrappedValue: HomeContentViewModel(
//            authenticationService: AuthenticationService(),
//            firestorColletionObserverService: FirestoreCollectionObserverService(),
//            managerCRUDS: managerCRUDS,
//            errorHandler: SharedErrorHandler()))
//        print("init HomeContentView")
//    }
//    
//    var body: some View {
//        /// NavigationView вызывал жёлтую ошибку в консоли
//        NavigationStack {
//            let _ = Self._printChanges()
//            ZStack {
//                switch viewModel.viewState {
//                case .loading:
//                    ProgressView("Loading...")
//                case .content(let data):
//                    contentView(data: data)
//                case .error(let error):
//                    errorView(error: error)
//                }
//            }
//            .background(AppColors.background)
//            .navigationTitle("Home")
//            .toolbar{
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Add") {
//                        viewModel.sheetManager.showSheet()
//                    }
//                    .foregroundStyle(AppColors.activeColor)
//                    .padding()
//                    .disabled(viewModel.viewState.isError)
//                }
//            }
//            .onAppear {
//                print("onAppear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = true
//            }
//            .onDisappear {
//                print("onDisappear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = false
//                
//            }
//            .task {
//                print("task HomeContentView")
//            }
//        }
//    }
//    
//    /// так как errorView заполняет пространство при первом старте или неожиданно возникшей ошибкой уже после успеха
//    /// но дублируется локальным или гобальным алертам
//    /// мы должны сделать его контент подходящим для любой ситуации
//    private func errorView(error:String) -> some View {
//        VStack {
//            Spacer()
//            ContentUnavailableView(label: {
//                
//                Label("Ups :(", systemImage: "exclamationmark.triangle")
//            }, description: {
//                Text("Try again! Something went wrong!")
//            }, actions: {
//                Button("Refresh") {
//                    viewModel.retry()
//                }
//            })
//            //            .background(AppColors.secondaryBackground)
//            .frame(maxWidth: .infinity)
//            Spacer()
//        }
//        .ignoresSafeArea(edges: [.horizontal])
//    }
//    
//    private func contentView(data:[BookCloud]) -> some View {
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
//        NavigationLink(destination: BookDetailsView(book: book)) {
//            VStack {
//                HStack(spacing: 10) {
//                    Image(systemName: "swift")
//                        .foregroundStyle(.pink)
//                        .frame(width: 30, height: 30)
//                    
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.description)
//                            .font(.subheadline)
//                        Text(book.author)
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }
//}







//    private func contentView(data: [BookCloud]) -> some View {
//        List(data) { book in
//            NavigationLink(destination: BookDetailsView(book: book)) {
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.author)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                    Button(role: .destructive) {
//                        viewModel.removeBook(book: book, forView: "HomeView", operationDescription: "Error deleting book")
//                    } label: {
//                        Label("delete", systemImage: "trash.fill")
//                    }
//                }
//                .padding(.vertical, 8)
//            }
//        }
//        .listStyle(PlainListStyle())
//    }

//private func contentView(data:[BookCloud]) -> some View {
//    List {
//        ForEach(data) { book in
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
//}


//    private func bookRowView(_ book: BookCloud) -> some View {
//        NavigationLink {
//            /// можем передать viewModel через @ObservedObject ?
//            /// происходит многократный вызов  init BookDetailsView но onAppear только при переходе на него
//            BookDetailsView(book: book)
//        } label: {
//            VStack {
//                HStack(spacing: 10) {
//                    Image(systemName: "swift")
//                        .foregroundStyle(.pink)
//                        .frame(width: 30, height: 30)
//                    
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.description)
//                            .font(.subheadline)
//                        Text(book.author)
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }

//struct HomeContentView: View {
//    
//    @StateObject private var viewModel: HomeContentViewModel
//    
//    init(managerCRUDS: CRUDSManager) {
//        _viewModel = StateObject(wrappedValue: HomeContentViewModel(
//            authenticationService: AuthenticationService(),
//            firestorColletionObserverService: FirestoreCollectionObserverService(),
//            managerCRUDS: managerCRUDS,
//            errorHandler: SharedErrorHandler()))
//        print("init HomeContentView")
//    }
//    
//    var body: some View {
//        NavigationStack {
//            let _ = Self._printChanges()
//            ZStack {
//                switch viewModel.viewState {
//                case .loading:
//                    ProgressView("Loading...")
//                case .content(let data):
//                    contentView(data: data)
//                case .error(let error):
//                    errorView(error: error)
//                }
//            }
//            .background(AppColors.background)
//            .navigationTitle("Home")
//        }
//    }
//    
//    private func contentView(data: [BookCloud]) -> some View {
//        List(data) { book in
//            NavigationLink(destination: BookDetailView(book: book)) {
//                HStack {
//                    // Асинхронная загрузка изображения
//                    AsyncImage(url: URL(string: book.pathImage)) { image in
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 50, height: 50)
//                            .clipped()
//                            .cornerRadius(8)
//                    } placeholder: {
//                        ProgressView()
//                            .frame(width: 50, height: 50)
//                    }
//                    
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.author)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .padding(.vertical, 8)
//            }
//        }
//        .listStyle(PlainListStyle())
//    }
//    
//    private func errorView(error: String) -> some View {
//        VStack {
//            Text("An error occurred:")
//                .font(.headline)
//            Text(error)
//                .font(.body)
//                .foregroundColor(.red)
//            Button("Retry") {
//                viewModel.loadContent() // Попытка повторной загрузки
//            }
//        }
//        .padding()
//    }
//}
//
//// Детальный View для отображения информации о книге
//struct BookDetailView: View {
//    let book: BookCloud
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            AsyncImage(url: URL(string: book.pathImage)) { image in
//                image
//                    .resizable()
//                    .scaledToFit()
//                    .cornerRadius(12)
//            } placeholder: {
//                ProgressView()
//            }
//            .frame(height: 200)
//            .padding(.bottom, 16)
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
//            
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Book Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}






// MARK: - .environmentObject(crudManager)  -

//import SwiftUI
//
//struct HomeContentView:View {
//    
//    @StateObject private var viewModel: HomeContentViewModel
//    
//    init() {
//        _viewModel = StateObject(wrappedValue: HomeContentViewModel(
//            authenticationService: AuthenticationService(),
//            firestorColletionObserverService: FirestoreCollectionObserverService(),
//            managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()),
//            errorHandler: SharedErrorHandler()))
//        print("init HomeContentView")
//    }
//    
//    var body: some View {
//        /// NavigationView вызывал жёлтую ошибку в консоли
//        NavigationStack {
//            let _ = Self._printChanges()
//            ZStack {
//                switch viewModel.viewState {
//                case .loading:
//                    ProgressView("Loading...")
//                case .content(let data):
//                    contentView(data: data)
//                case .error(let error):
//                    errorView(error: error)
//                }
//            }
//            .background(AppColors.background)
//            .navigationTitle("Home")
//            .toolbar{
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Add") {
//                        viewModel.sheetManager.showSheet()
//                    }
//                    .foregroundStyle(AppColors.activeColor)
//                    .padding()
//                    .disabled(viewModel.viewState.isError)
//                }
//            }
//            .onAppear {
//                print("onAppear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = true
//            }
//            .onDisappear {
//                print("onDisappear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = false
//
//            }
//            .task {
//                print("task HomeContentView")
//            }
//        }
//    }
//    
//    /// так как errorView заполняет пространство при первом старте или неожиданно возникшей ошибкой уже после успеха
//    /// но дублируется локальным или гобальным алертам
//    /// мы должны сделать его контент подходящим для любой ситуации
//    private func errorView(error:String) -> some View {
//        VStack {
//            Spacer()
//            ContentUnavailableView(label: {
//                
//                Label("Ups :(", systemImage: "exclamationmark.triangle")
//            }, description: {
//                Text("Try again! Something went wrong!")
//            }, actions: {
//                Button("Refresh") {
//                    viewModel.retry()
//                }
//            })
////            .background(AppColors.secondaryBackground)
//            .frame(maxWidth: .infinity)
//            Spacer()
//        }
//        .ignoresSafeArea(edges: [.horizontal])
//    }
//
//    private func contentView(data:[BookCloud]) -> some View {
//        List {
//            ForEach(data) { book in
//                bookRowView(book)
//                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                        Button(role: .destructive) {
//                            viewModel.removeBook(book: book, forView: "HomeView", operationDescription: "Error deleting book")
//                        } label: {
//                            Label("delete", systemImage: "trash.fill")
//                        }
//                    }
//            }
//        }
//    }
//    
//    private func bookRowView(_ book: BookCloud) -> some View {
//        NavigationLink {
//            /// можем передать viewModel через @ObservedObject ?
//            /// происходит многократный вызов  init BookDetailsView но onAppear только при переходе на него
//            BookDetailsView(book: book)
//        } label: {
//            VStack {
//                HStack(spacing: 10) {
//                    Image(systemName: "swift")
//                        .foregroundStyle(.pink)
//                        .frame(width: 30, height: 30)
//                    
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.description)
//                            .font(.subheadline)
//                        Text(book.author)
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }
//}


// MARK: - before correct initialization of the state -



//import SwiftUI
//
//struct HomeContentView:View {
//    
//    @StateObject private var viewModel:HomeContentViewModel
//    @EnvironmentObject var sheetManager: SheetManager
//    
//    init(viewModel:HomeContentViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//        print("init HomeContentView")
//    }
//    
//    var body: some View {
//        /// NavigationView вызывал жёлтую ошибку в консоли
//        NavigationStack {
//            ZStack {
//                switch viewModel.viewState {
//                case .loading:
//                    ProgressView("Loading...")
//                case .content(let data):
//                    contentView(data: data)
//                case .error(let error):
//                    errorView(error: error)
//                }
//            }
//            .background(AppColors.background)
//            .navigationTitle("Home")
//            .toolbar{
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Add") {
//                        sheetManager.showSheet()
//                    }
//                    .foregroundStyle(AppColors.activeColor)
//                    .padding()
//                    .disabled(viewModel.viewState.isError)
//                }
//            }
//            .onAppear {
//                print("onAppear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = true
//            }
//            .onDisappear {
//                print("onDisappear HomeContentView")
//                viewModel.alertManager.isHomeViewVisible = false
//
//            }
//            .task {
//                print("task HomeContentView")
//            }
//        }
//    }
//    
//    //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//    //                    print("asyncAfter")
//    //                    viewModel.alertManager.isHomeViewVisible = false
//    //                }
//                    
//    //                viewModel.alertManager.isHomeViewVisible = true
//    private func errorView(error:String) -> some View {
//        VStack {
//            Spacer()
//            ContentUnavailableView(label: {
//                Label("Connection issue", systemImage: "wifi.slash")
//            }, description: {
//                Text("Check your internet connection")
//            }, actions: {
//                Button("Refresh") {
//                    viewModel.retry()
//                }
//            })
//            .background(AppColors.secondaryBackground)
//            .frame(maxWidth: .infinity)
//            Spacer()
//        }
//        .ignoresSafeArea(edges: [.horizontal])
//    }
//
//    private func contentView(data:[BookCloud]) -> some View {
//        List {
//            ForEach(data) { book in
//                bookRowView(book)
//                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                        Button(role: .destructive) {
//                            viewModel.removeBook(book: book, forView: "HomeView", operationDescription: "Error deleting book")
//                        } label: {
//                            Label("delete", systemImage: "trash.fill")
//                        }
//                    }
//            }
//        }
//    }
//    
//    private func bookRowView(_ book: BookCloud) -> some View {
//        NavigationLink {
//            BookDetailsView(book: book)
//        } label: {
//            VStack {
//                HStack(spacing: 10) {
//                    Image(systemName: "swift")
//                        .foregroundStyle(.pink)
//                        .frame(width: 30, height: 30)
//                    
//                    VStack(alignment: .leading) {
//                        Text(book.title)
//                            .font(.headline)
//                        Text(book.description)
//                            .font(.subheadline)
//                        Text(book.author)
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }
//}


