//
//  HomeContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.12.24.
//


import SwiftUI

struct HomeContentView:View {
    
    @StateObject private var viewModel: HomeContentViewModel
    private var sheetManager = SheetManager.shared
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeContentViewModel(
            authenticationService: AuthenticationService(),
            firestorColletionObserverService: FirestoreCollectionObserverService(),
            managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()),
            errorHandler: SharedErrorHandler()))
        print("init HomeContentView")
    }
    
    var body: some View {
        /// NavigationView вызывал жёлтую ошибку в консоли
        NavigationStack {
            let _ = Self._printChanges()
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
                        sheetManager.showSheet()
                    }
                    .foregroundStyle(AppColors.activeColor)
                    .padding()
                    .disabled(viewModel.viewState.isError)
                }
            }
            .onAppear {
                print("onAppear HomeContentView")
                viewModel.alertManager.isHomeViewVisible = true
            }
            .onDisappear {
                print("onDisappear HomeContentView")
                viewModel.alertManager.isHomeViewVisible = false

            }
            .task {
                print("task HomeContentView")
            }
        }
    }
    
    private func errorView(error:String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView(label: {
                Label("Connection issue", systemImage: "wifi.slash")
            }, description: {
                Text("Check your internet connection")
            }, actions: {
                Button("Refresh") {
                    viewModel.retry()
                }
            })
            .background(AppColors.secondaryBackground)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .ignoresSafeArea(edges: [.horizontal])
    }

    private func contentView(data:[BookCloud]) -> some View {
        List {
            ForEach(data) { book in
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
    }
    
    private func bookRowView(_ book: BookCloud) -> some View {
        NavigationLink {
            /// можем передать viewModel через @ObservedObject ?
            /// происходит многократный вызов  init BookDetailsView но onAppear только при переходе на него
            BookDetailsView(book: book)
        } label: {
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
            }
        }
    }
}




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


