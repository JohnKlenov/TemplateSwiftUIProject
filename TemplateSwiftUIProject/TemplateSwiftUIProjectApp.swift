//
//  TemplateSwiftUIProjectApp.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//


/// Когда ты передаешь объект managerCRUDS в ContentView с помощью .environmentObject(managerCRUDS), этот объект становится доступным для всех дочерних представлений, которые используют @EnvironmentObject.
/// в struct нам не нужно передавать зависимость через конструктор просто используем @EnvironmentObject var managerCRUDS: CRUDSManager а в классах нужно передавать через конструктор - HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)
import SwiftUI

@main
struct TemplateSwiftUIProjectApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    ///использование @AppStorage позволяет привязать переменную(tiedOnboarding) к UserDefaults, а SwiftUI автоматически отслеживает и реагирует на изменения этой переменной, что приводит к обновлению пользовательского интерфейса без необходимости явных вызовов для переключения представлений.
    @AppStorage("hasSeenOnboarding") var tiedOnboarding:Bool = false
    
    init() {
#if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
#endif
    }
    
    var body: some Scene {
        
        WindowGroup {
            if tiedOnboarding {
                let authService:AuthServiceProtocol = AuthService()
                let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
                let databaseService:any DatabaseCRUDServiceProtocol = FirestoreDatabaseCRUDService()
                let managerCRUDS = CRUDSManager(authService: authService, errorHandler: errorHandler, databaseService: databaseService)
                ContentView()
                    .environmentObject(managerCRUDS)
            } else {
                let onboardingService = OnboardingService()
                let viewModel = OnboardingViewModel(onboardingService: onboardingService)
                OnboardingView(viewModel: viewModel)
            }
        }
    }
}




// MARK: - before environment




//import SwiftUI
//
//@main
//struct TemplateSwiftUIProjectApp: App {
//    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    ///использование @AppStorage позволяет привязать переменную(tiedOnboarding) к UserDefaults, а SwiftUI автоматически отслеживает и реагирует на изменения этой переменной, что приводит к обновлению пользовательского интерфейса без необходимости явных вызовов для переключения представлений.
//    @AppStorage("hasSeenOnboarding") var tiedOnboarding:Bool = false
//    
//    init() {
//#if DEBUG
//        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
//#endif
//    }
//    
//    var body: some Scene {
//        
//        WindowGroup {
//            
//            if tiedOnboarding {
//                let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//                let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//                let databaseService = FirestoreDatabaseCRUDService() as DatabaseCRUDServiceProtocol
//                let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//                let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, databaseService: databaseService, errorHandler: errorHandler)
//                let homeView = HomeView(viewModel: viewModel)
//                ContentView(homeView: homeView, galleryView: GalleryView(), profileView: ProfileView())
//                
//            } else {
//                let onboardingService = OnboardingService()
//                let viewModel = OnboardingViewModel(onboardingService: onboardingService)
//                OnboardingView(viewModel: viewModel)
//            }
//        }
//    }
//}

