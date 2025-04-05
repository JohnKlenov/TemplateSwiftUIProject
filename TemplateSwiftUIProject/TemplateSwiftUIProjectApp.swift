//
//  TemplateSwiftUIProjectApp.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//


// MARK: - Life Cicle Application

//⌘ + Shift + H
///симулятор предоставляет возможность перейти в режим App Switcher и проверить, как ваше приложение ведёт себя, когда оно уходит в фон или происходит переключение между приложениями.

//@Environment(\.scenePhase)

///В SwiftUI можно использовать как NotificationCenter, так и новый механизм отслеживания жизненного цикла приложения через среду (Environment). Например, SwiftUI предоставляет свойство scenePhase:
///Active (Активное): Приложение находится на переднем плане и активно взаимодействует с пользователем. Здесь выполняется вся анимация, обработка пользовательского ввода и обновление пользовательского интерфейса. Это оптимальное состояние для работы с ресурсами, так как приложение «на виду» и должно работать максимально откликается. Обновление данных: При переходе в активное состояние (active) можно инициировать обновление контента или возобновление отложенных операций, чтобы пользователь видел актуальную информацию.
///Inactive (Неактивное): Это переходное или временное состояние, когда приложение временно теряет фокус (например, во время входящего звонка, появления системных уведомлений или короткого перехода между активными состояниями). Здесь приложение не обрабатывает пользовательский ввод, а многие задачи приостанавливаются. Можно воспринимать это как «задержку» перед полноценным переходом в фон или обратно в активное состояние. Приостановка задач: При событии перехода в состояние inactive или background можно приостановить «тяжёлые» задачи, такие как анимации или интенсивные вычисления, чтобы освободить ресурсы.
///Background (Фоновое): Приложение работает в фоновом режиме, то есть оно не находится на переднем плане и визуально не доступно пользователю, но может продолжать выполнять ограниченные задачи (например, сохранять данные, обновлять содержимое, завершать уже начатые операции). Здесь система накладывает ограничения на использование ресурсов, поэтому интенсивные операции или обновление интерфейса не проводятся. Сохранение состояния и данных: При переходе в фон (background) можно сохранять текущее состояние приложения, например, данные формы или прогресс загрузки, чтобы при возвращении пользователю всё восстановилось без потерь.
///В iOS нет "магического" уведомления, которое гарантированно сообщило бы вашему приложению, что оно вот-вот будет выгружено (терминировано) из памяти.
///Переход в фон и сохранение состояния: Лучший способ "подготовиться" к возможной выгрузке из памяти – это сохранять критичные данные и состояние во время перехода в фон (например, в методе scenePhase актуального SwiftUI или в applicationDidEnterBackground у делегата). Так, если система в какой‑то момент решит выгрузить приложение, восстановление состояния произойдёт при следующем запуске, даже если вы не получили явного уведомления о завершении работы.
///Метод делегата applicationWillTerminate: Если ваше приложение работает в активном состоянии (на переднем плане) и затем закрывается (например, пользователь вручную завершает работу приложения через App Switcher или система осуществляет корректное завершение), то вызывается метод applicationWillTerminate в UIApplicationDelegate. Однако этот метод вызывается не во всех случаях. Если приложение уже находится в фоне (и заморожено системой) и затем выгружается для освобождения памяти, этот метод не гарантируется.


//NotificationCenter.default.publisher(...):

///Даже если вы не используете классический UIApplicationDelegate в SwiftUI, можно отслеживать многие события жизненного цикла приложения через уведомления NotificationCenter или через новые возможности самого SwiftUI.

///UIApplication.didEnterBackgroundNotification Отправляется, когда приложение переходит в фон. Это удобно для сохранения данных или освобождения ресурсов.
///UIApplication.willEnterForegroundNotification Отправляется, когда приложение собирается выйти из фонового режима и вернуться на передний план, что позволяет обновить интерфейс или данные.
///UIApplication.didBecomeActiveNotification Отправляется, когда приложение становится активным. Здесь можно возобновить паузенные задачи или обновить информацию.
///UIApplication.willResignActiveNotification Отправляется, когда приложение переходит в состояние неактивности (например, при входящем звонке или при переходе в меню), что может быть полезно для временной остановки обработки.
///Помимо этого, можно подписаться на такие уведомления, как изменения ориентации устройства (например, UIDevice.orientationDidChangeNotification).


// MARK: - something else
/// Когда ты передаешь объект managerCRUDS в ContentView с помощью .environmentObject(managerCRUDS), этот объект становится доступным для всех дочерних представлений, которые используют @EnvironmentObject.
/// в struct нам не нужно передавать зависимость через конструктор просто используем @EnvironmentObject var managerCRUDS: CRUDSManager а в классах нужно передавать через конструктор - HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)



import SwiftUI
import Combine

@main
struct TemplateSwiftUIProjectApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    ///использование @AppStorage позволяет привязать переменную(tiedOnboarding) к UserDefaults, а SwiftUI автоматически отслеживает и реагирует на изменения этой переменной, что приводит к обновлению пользовательского интерфейса без необходимости явных вызовов для переключения представлений.
    @AppStorage("hasSeenOnboarding") var tiedOnboarding:Bool = false
    @StateObject private var localizationService = LocalizationService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
      
        
#if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        self.setupCache()
#endif
    }
    
    var body: some Scene {
        
        WindowGroup {
            if tiedOnboarding {
                ContentView()
                    .environmentObject(localizationService)
                    .environment(\.sizeCategory, .medium)
            } else {
                OnboardingView()
            }
        }
        .onChange(of: scenePhase) { newPhase, _ in
            switch newPhase {
            case .active:
                print("App became active")
            case .inactive:
                print("App became inactive")
            case .background:
                print("App entered background")
            @unknown default:
                print("Unknown scene phase")
            }
        }

    }
    
    private func setupCache() {
        ImageCacheManager.shared.deleteOldFiles()
    }
}



// MARK: - before pattern Coordinator

//import SwiftUI
//import Combine
//
//@main
//struct TemplateSwiftUIProjectApp: App {
//    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    ///использование @AppStorage позволяет привязать переменную(tiedOnboarding) к UserDefaults, а SwiftUI автоматически отслеживает и реагирует на изменения этой переменной, что приводит к обновлению пользовательского интерфейса без необходимости явных вызовов для переключения представлений.
//    @AppStorage("hasSeenOnboarding") var tiedOnboarding:Bool = false
//    
//    // Создаем глобальный экземпляр CRUDSManager
//       @StateObject private var crudManager = CRUDSManager(
//           authService: AuthService(),
//           errorHandler: SharedErrorHandler(),
//           databaseService: FirestoreDatabaseCRUDService()
//       )
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
//            if tiedOnboarding {
//                ContentView()
//                    .environmentObject(crudManager) // Передаем экземпляр во всю иерархию
//            } else {
//                OnboardingView()
//            }
//        }
//    }
//}





// MARK: - .environmentObject(crudManager)  -


//import SwiftUI
//import Combine
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
//            if tiedOnboarding {
//                ContentView()
//            } else {
//                OnboardingView()
//            }
//        }
//    }
//}



// MARK: - before correct initialization of the state -

//import SwiftUI
//import Combine
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
//            if tiedOnboarding {
//                let authService:AuthServiceProtocol = AuthService()
//                let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
//                let databaseService:any DatabaseCRUDServiceProtocol = FirestoreDatabaseCRUDService()
//                let managerCRUDS = CRUDSManager(authService: authService, errorHandler: errorHandler, databaseService: databaseService)
//                ContentView()
//                    .environmentObject(managerCRUDS)
//            } else {
//                let onboardingService = OnboardingService()
//                let viewModel = OnboardingViewModel(onboardingService: onboardingService)
//                OnboardingView(viewModel: viewModel)
//            }
//        }
//    }
//}





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

