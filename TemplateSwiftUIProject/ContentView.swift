//
//  ContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//

//            let firestoreCollectionObserver = RealtimeCollectionObserverService() as FirestoreCollectionObserverProtocol



import SwiftUI
import Combine


struct ContentView: View {
    
    @ObservedObject var alertManager:AlertManager
    
    private let homeView:HomeView
    private let galleryView:GalleryView
    private let profileView:ProfileView
    
    @State private var selection:Int
    
    private var bindingError: Binding<Bool> {
        Binding<Bool>(
            get: {
                print("ContentView get bindingError")
                return alertManager.globalAlert != nil
            },
            set: { newValue in
                print("ContentView set bindingError - \(newValue)")
                if !newValue {
                    alertManager.resetGlobalAlert()
                }
            }
        )
    }
    
    init(alertManager: AlertManager = AlertManager.shared, homeView: HomeView, galleryView: GalleryView, profileView: ProfileView, selection: Int = 0) {
        self.alertManager = alertManager
        self.homeView = homeView
        self.galleryView = galleryView
        self.profileView = profileView
        self.selection = selection
    }
    
    var body: some View {
        TabView(selection: $selection) {
            
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                        .tag(0)
                }
            galleryView
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.fill")
                        .tag(1)
                }
            profileView
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


//struct ContentView: View {
//    
//@ObservedObject var alertManager = AlertManager.shared
//    private var cancellables = Set<AnyCancellable>()
//    @State var selection = 0
//    @State var isShowAlert = false
//    
//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("get bindingError")
//                return alertManager.globalAlert != nil
//            },
//            set: { newValue in
//                print("set bindingError - \(newValue)")
//                if !newValue {
//                    alertManager.resetGlobalAlert()
//                }
//            }
//        )
//    }
//   
//    var body: some View {
//        TabView(selection: $selection) {
//
//            let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//            let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//            let databaseService = FirestoreDatabaseCRUDService() as DatabaseCRUDServiceProtocol
//            let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//            let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, databaseService: databaseService, errorHandler: errorHandler)
//            HomeView(viewModel: viewModel)
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                        .tag(0)
//                }
//            GalleryView()
//                .tabItem {
//                    Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                        .tag(1)
//                }
//            ProfileView()
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle.fill")
//                        .tag(2)
//                }
//        }
////        .onReceive(alertManager.$globalAlert) { global in
////            isShowAlert = global != nil ? true : false
////        }
//        .alert("Global error", isPresented: $isShowAlert) {
//            Button("Ok") {
//                alertManager.resetGlobalAlert()
//            }
//        } message: {
//            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
//        }
////        .alert("Global error", isPresented: bindingError) {
////            Button("Ok") {}
////        } message: {
////            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
////        }
//    }
//}

//#Preview {
//    ContentView()
//}

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
