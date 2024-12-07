//
//  ContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//

//            let firestoreCollectionObserver = RealtimeCollectionObserverService() as FirestoreCollectionObserverProtocol



/// может ли global alert автоматически кансельнуться?
/// если произойдет перерисовка ContentView
/// а она происходит видимо так как когда происходят изменения в alertManager у bindingError дергается get.
/// на HomeView при открытом alert мы перерисовывали HomeView удаляя документ с сервера
/// срабатывал get у bindingError но не блок set , alert оставался живым
/// почему мы обеспокоиным этим поведением , потому что когда мы использовали Binding для .sheet то при перерисовки view на котором у нас открывался модальный экран срабатывал binding и его блок set со значением false(это происходило автоматически) что самоуничтожало модальный экран - помог SheetManager.
/// Различия в поведении могут объясняться тем, как SwiftUI обрабатывает состояния для различных видов представлений. Для sheet, важно постоянное обновление состояния, чтобы избежать дублирования (поэтому когда у нас обновлялся bindingSheet в set создать новый он не мог так как генерировался false - !viewModel.isSheetActive && presentAddBookSheet ноj set вызывался что бы избежать дублирования автоматически - ответ чата). Для alert, достаточно установить состояние в true, чтобы отобразить алерт, и управлять его закрытием через пользовательские действия.

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
