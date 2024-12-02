//
//  ContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//

//            let firestoreCollectionObserver = RealtimeCollectionObserverService() as FirestoreCollectionObserverProtocol


import SwiftUI

struct ContentView: View {
    
    private var alertManager = AlertManager.shared
    @State var selection = 0
    private var bindingError: Binding<Bool> {
        Binding<Bool>(
            get: { alertManager.globalAlert != nil },
            set: { newValue in
                if !newValue {
                    alertManager.resetGlobalAlert()
                }
            }
        )
    }
   
    var body: some View {
        TabView(selection: $selection) {

            let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
            let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
            let databaseService = FirestoreDatabaseCRUDService() as DatabaseCRUDServiceProtocol
            let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
            let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, databaseService: databaseService, errorHandler: errorHandler)
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                        .tag(0)
                }
            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.fill")
                        .tag(1)
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                        .tag(2)
                }
        }
        .alert("Global error", isPresented: bindingError) {
            Button("Ok") {}
        } message: {
            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
        }
    }
}

#Preview {
    ContentView()
}

///в TabBarViewController инициализация вкладок происходит по умолчанию при их выборе.
///LazyView - это удобный и простой способ. Он позволяет отложить инициализацию до момента, когда представление действительно потребуется, что может улучшить производительность приложения.
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}



//            let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//            GalleryView()
