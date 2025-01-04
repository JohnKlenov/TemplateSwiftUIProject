//
//  SheetHomeView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.12.24.
//

import SwiftUI
import Combine

struct SheetHomeView:View {
    
//    @EnvironmentObject private var sheetManager:SheetManager
    //$sheetManager.isPresented
    private var sheetManager = SheetManager.shared
    @State private var isSubscribed = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isShow:Bool = false
    
    init() {
        print("init SheetHomeView")
    }
    
    var body: some View {
        EmptyView()
            .sheet(isPresented: $isShow) {
                
                BookEditView(managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()))
            }
            .onAppear {
                
                print("onAppear SheetHomeView")
                guard !isSubscribed else { return }
                isSubscribed = true
                sheetManager.$isPresented
                    .sink { isPresented in
                        isShow = isPresented
                    }
                    .store(in: &cancellables)
            }
            .onDisappear {
                print("onDisappear SheetHomeView")
            }
    }
}


// MARK: - before correct initialization of the state -

//import SwiftUI
//
//struct SheetHomeView:View {
//    
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//    @EnvironmentObject var sheetManager: SheetManager
//    
//    init() {
//        print("init SheetHomeView")
//    }
//    
//    var body: some View {
//        EmptyView()
//            .sheet(isPresented: $sheetManager.isPresented) {
//                let bookViewModel = BookViewModel(managerCRUDS: managerCRUDS)
//                BookEditView(viewModel: bookViewModel)
//            }
//            .onAppear {
//                print("onAppear SheetHomeView")
//            }
//            .onDisappear {
//                print("onDisappear SheetHomeView")
//            }
//    }
//}
