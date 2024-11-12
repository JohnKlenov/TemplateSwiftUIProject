//
//  ContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//



import SwiftUI

struct ContentView: View {
    
    @State var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {

            let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//            let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
            let firestoreCollectionObserver = RealtimeCollectionObserverService() as FirestoreCollectionObserverProtocol
            
            let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
            let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, errorHandler: errorHandler)
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
