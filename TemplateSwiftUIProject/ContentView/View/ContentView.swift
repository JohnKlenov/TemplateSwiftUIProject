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



///почему в данном случае при вызове .onReceive(NotificationCenter.default.publisher(for: .globalAlert)) у нас не происходит не перерисовки ContentView и не происходит повторной инит GlobalAlertView ?
///В SwiftUI перерисовка происходит только для тех областей, где изменилось состояние. Когда вы используете @State и Binding, SwiftUI отслеживает изменения и перерисовывает только те части представления, которые зависят от этих состояний.
///изменение состояния @State переменных showAlert и alertMessage вызывает обновление только тех представлений, которые зависят от этих состояний, а не всего ContentView.
///Представление GlobalAlertView используется в качестве фона (background) для основного представления. Это помогает отделить управление алертами от основного контента, минимизируя перерисовку. Когда состояние алерта изменяется, SwiftUI обновляет только GlobalAlertView, а не все представление.
///GlobalAlertView инициализируется один раз и затем обновляется при изменении состояния. Если бы весь ContentView перерисовывался, вы бы видели повторную инициализацию, но поскольку SwiftUI отслеживает зависимости и минимизирует перерисовку, это не происходит.
///Представление GlobalAlertView добавляется в фоновый слой для TabView. В SwiftUI, .background добавляет указанное представление за основным контентом, не поверх него.
///GlobalAlertView будет добавлен позади всех вкладок внутри TabView, но на одном уровне с TabView в иерархии представлений VStack.
///Таким образом, GlobalAlertView не располагается поверх VStack, а является фоновым элементом для TabView, что позволяет ему управлять состоянием алертов без влияния на видимость основного контента.

/// При отображении global alert будет происходить dissmiss ModalView(если открыть alert из ModalView то он отобразится поверх модального view) и только после его исчезновения отобразится сам global alert. - Когда отображается алерт, SwiftUI может обрабатывать его как новое модальное представление, что приводит к закрытию предыдущего.
/// VStack { Button("Show Sheet")  { isPresentingSheet = true } } .alert("Alert", isPresented: $isPresentingAlert) {} .sheet(isPresented: $isPresentingSheet) { Button("Show Alert") {  isPresentingAlert = true } }
///   .sheet(isPresented: $isPresentingSheet) {ModalView(isPresentingAlert: $isPresentingAlert).alert(isPresented: $isPresentingAlert) {Alert(title: Text("Alert"), message: nil, dismissButton: .default(Text("OK"))) }} - вот так ок
///можно решить эту проблему добавив флаг в AlertManager, чтобы отслеживать, когда модальное окно открыто, и при необходимости перенаправлять глобальные алерты в модальное окно.


import SwiftUI
import Combine


struct ContentView: View {
    
    
    // MARK: - ViewBuilderService (вынести в TemplateSwiftUIProjectApp и HomeView, GalleryView, AccountView создавать там же и в LazyView { viewBuilderService.buildGalleryView } тогда все сервисы можно инициализировать в ViewBuilderService)
    private var homeView: LazyView<HomeView> {
        return LazyView { HomeView() }
    }
    
    private var galleryView: LazyView<GalleryView> {
        return LazyView { GalleryView() }
    }
   
    private var accountView: LazyView<AccountView> {
        return LazyView { AccountView() }
    }
    
    @StateObject private var viewModel:ContentViewModel
    @StateObject private var mainCoordinator = MainCoordinator()
    @StateObject private var viewBuilderService = ViewBuilderService()
    
    
    @State private var selection: Int = 0
    @State private var isShowAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var alertType: AlertType = .common
    @State private var cancellables = Set<AnyCancellable>()
    
    @EnvironmentObject var localization: LocalizationService
    
    init() {
        print("init ContentView")
        _viewModel = StateObject(wrappedValue: ContentViewModel(alertManager: AlertManager.shared))

    }

    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $selection) {
                    homeView
                        .tabItem {
                            Label(Localized.TabBar.home.localized(), systemImage: "house.fill")
                        }
                        .tag(0)
                        .environmentObject(mainCoordinator)
                        .environmentObject(mainCoordinator.homeCoordinator)
                        .environmentObject(viewBuilderService)
                    
                    galleryView
                        .tabItem {
                            Label(Localized.TabBar.gallery.localized(), systemImage: "photo.on.rectangle.fill")
                        }
                        .tag(1)
                        .environmentObject(mainCoordinator)
                        .environmentObject(mainCoordinator.galleryCoordinator)
                        .environmentObject(viewBuilderService)
                    
                    accountView
                        .tabItem {
                            Label(Localized.TabBar.profile.localized(), systemImage: "person.crop.circle.fill")
                        }
                        .tag(2)
                        .environmentObject(viewBuilderService)
                        .environmentObject(mainCoordinator)
                        .environmentObject(mainCoordinator.accountCoordinator)
                }
                .background(
                    AlertViewGlobal(isShowAlert: $isShowAlert,
                                    alertTitle: $alertTitle,
                                    alertMessage: $alertMessage,
                                    alertType: $alertType)
                )
                .onFirstAppear {
                    print("onFirstAppear ContentView")
                    subscribeToGlobalAlerts()
                    subscribeToSwitchTabViewItem()
                }
            }
        }
    }
    
    // Подписка на изменения глобальных алертов. При получении алерта извлекаем все данные, включая тип.
    private func subscribeToGlobalAlerts() {
        viewModel.alertManager.$globalAlert
            .sink { globalAlert in
                if let alerts = globalAlert["globalError"], let alert = alerts.first {
                    self.alertMessage = alert.message.localized()
                    self.alertTitle = alert.operationDescription.localized()
                    self.alertType = alert.type
                    self.isShowAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToSwitchTabViewItem() {
        mainCoordinator.tabViewSwitcher.$tabSelection
            .sink { selectionItem in
                selection = selectionItem
            }
            .store(in: &cancellables)
    }
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



// MARK: - body before NetworkStatusBanner

//    var body: some View {
//        let _ = Self._printChanges()
//        VStack {
//
//            TabView(selection:$selection) {
//                homeView
//                    .tabItem {
//                        Label(Localized.TabBar.home.localized(), systemImage: "house.fill")
//                    }
//                    .tag(0)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.homeCoordinator)
//                    .environmentObject(viewBuilderService)
//                galleryView
//                    .tabItem {
//                        Label(Localized.TabBar.gallery.localized(), systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.galleryCoordinator)
//                    .environmentObject(viewBuilderService)
//                accountView
//                    .tabItem {
//                        Label(Localized.TabBar.profile.localized(), systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//                    .environmentObject(viewBuilderService)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.accountCoordinator)
//            }
//            .background(
//                // Передаём все необходимые binding-переменные и замыкание для обработки retry
//                AlertViewGlobal(isShowAlert: $isShowAlert,
//                                alertTitle: $alertTitle,
//                                alertMessage: $alertMessage,
//                                alertType: $alertType)
//            )
//            .onFirstAppear {
//                print("onFirstAppear ContentView")
//                subscribeToGlobalAlerts()
//                subscribeToSwitchTabViewItem()
//            }
//        }
//    }

// MARK: - old implemintation with var isViewVisible: Bool


//struct ContentView: View {
//    
//    private var homeView: LazyView<HomeView> {
//        return LazyView { HomeView() }
//    }
//    
//    private var galleryView: LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//   
//    private var accountView: LazyView<AccountView> {
//        return LazyView { AccountView() }
//    }
//    
//    @StateObject private var viewModel:ContentViewModel
//    @StateObject private var mainCoordinator = MainCoordinator()
//    @StateObject private var viewBuilderService = ViewBuilderService()
//    
//    @State private var selection: Int = 0
//    @State private var isShowAlert: Bool = false
//    @State private var alertMessage: String = ""
//    @State private var alertTitle: String = ""
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    @EnvironmentObject var localization: LocalizationService
//    
//    init() {
//        print("init ContentView")
//        _viewModel = StateObject(wrappedValue: ContentViewModel(alertManager: AlertManager.shared))
//
//    }
//
//    var body: some View {
//        let _ = Self._printChanges()
//        VStack {
//            
//            TabView(selection:$selection) {
//                homeView
//                    .tabItem {
//                        Label(Localized.TabBar.home.localized(), systemImage: "house.fill")
//                    }
//                    .tag(0)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.homeCoordinator)
//                    .environmentObject(viewBuilderService)
//                galleryView
//                    .tabItem {
//                        Label(Localized.TabBar.gallery.localized(), systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.galleryCoordinator)
//                    .environmentObject(viewBuilderService)
//                accountView
//                    .tabItem {
//                        Label(Localized.TabBar.profile.localized(), systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//                    .environmentObject(viewBuilderService)
//                    .environmentObject(mainCoordinator)
//                    .environmentObject(mainCoordinator.accountCoordinator)
//            }
//            .background(
//                AlertViewGlobal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage)
//            )
//            .onFirstAppear {
//                print("onFirstAppear ContentView")
//                subscribeToGlobalAlerts()
//                subscribeToSwitchTabViewItem()
//            }
//        }
//    }
//    
//    private func subscribeToGlobalAlerts() {
//        viewModel.alertManager.$globalAlert
//            .sink { globalAlert in
//                print(".sink { globalAlert in")
//                if let alert = globalAlert["globalError"] {
//                    print(".sink showAlert = true")
//                    alertMessage = alert.first?.message.localized() ?? Localized.Alerts.defaultMessage.localized()
//                    alertTitle = alert.first?.operationDescription.localized() ?? Localized.Alerts.title.localized()
//                    isShowAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func subscribeToSwitchTabViewItem() {
//        mainCoordinator.tabViewSwitcher.$tabSelection
//            .sink { selectionItem in
//                selection = selectionItem
//            }
//            .store(in: &cancellables)
//    }
//}
//
//
/////в TabBarViewController инициализация вкладок происходит по умолчанию при их выборе.
/////LazyView - это удобный и простой способ. Он позволяет отложить инициализацию до момента, когда представление действительно потребуется, что может улучшить производительность приложения.
//struct LazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content {
//        build()
//    }
//}






//    @StateObject private var dataStore = DataStore()
//                    .environmentObject(dataStore.homeBookDataStore)

// MARK: - before pattern Coordinator

//import SwiftUI
//import Combine
//
//
//struct ContentView: View {
//    
//    private var homeView: LazyView<HomeView> {
//        return LazyView { HomeView() }
//    }
//    
//    private var galleryView: LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//    
//    private var profileView: LazyView<ProfileView> {
//        return LazyView { ProfileView() }
//    }
//    @StateObject private var viewModel:ContentViewModel
//    
//    @State private var selection: Int = 0
//    @State private var isShowAlert: Bool = false
//    @State private var alertMessage: String = "Error"
//    @State private var alertTitle: String = "Something went wrong try again!"
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    init() {
//        print("init ContentView")
//        _viewModel = StateObject(wrappedValue: ContentViewModel(alertManager: AlertManager.shared))
//
//    }
//    
//    var body: some View {
//        VStack {
//            TabView(selection: $selection) {
//                homeView
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                galleryView
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                profileView
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//            }
//            .background(
//                AlertViewGlobal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage)
//            )
//            .onFirstAppear {
//                print("onFirstAppear ContentView")
//                subscribeToGlobalAlerts()
//            }
//        }
//    }
//    
//    private func subscribeToGlobalAlerts() {
//        viewModel.alertManager.$globalAlert
//            .sink { globalAlert in
//                print(".sink { globalAlert in")
//                if let alert = globalAlert["globalError"] {
//                    print(".sink showAlert = true")
//                    alertMessage = alert.first?.message ?? "Something went wrong try again!"
//                    alertTitle = alert.first?.operationDescription ?? "Error"
//                    isShowAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//}
//
//
/////в TabBarViewController инициализация вкладок происходит по умолчанию при их выборе.
/////LazyView - это удобный и простой способ. Он позволяет отложить инициализацию до момента, когда представление действительно потребуется, что может улучшить производительность приложения.
//struct LazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content {
//        build()
//    }
//}



// MARK: - .environmentObject(crudManager)  -


//import SwiftUI
//import Combine
//
//
//struct ContentView: View {
//    
//    private var homeView: LazyView<HomeView> {
//        return LazyView { HomeView() }
//    }
//    
//    private var galleryView: LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//    
//    private var profileView: LazyView<ProfileView> {
//        return LazyView { ProfileView() }
//    }
//    @StateObject private var viewModel:ContentViewModel
//    
//    @State private var selection: Int = 0
//    @State private var isShowAlert: Bool = false
//    @State private var alertMessage: String = "Error"
//    @State private var alertTitle: String = "Something went wrong try again!"
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    init() {
//        print("init ContentView")
//        _viewModel = StateObject(wrappedValue: ContentViewModel(alertManager: AlertManager.shared))
//
//    }
//    
//    var body: some View {
//        VStack {
//            TabView(selection: $selection) {
//                homeView
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                galleryView
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                profileView
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//            }
//            .background(
//                AlertViewGlobal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage)
//            )
//            .onFirstAppear {
//                print("onFirstAppear ContentView")
//                subscribeToGlobalAlerts()
//            }
//        }
//    }
//    
//    private func subscribeToGlobalAlerts() {
//        viewModel.alertManager.$globalAlert
//            .sink { globalAlert in
//                print(".sink { globalAlert in")
//                if let alert = globalAlert["globalError"] {
//                    print(".sink showAlert = true")
//                    alertMessage = alert.first?.message ?? "Something went wrong try again!"
//                    alertTitle = alert.first?.operationDescription ?? "Error"
//                    isShowAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//}


///в TabBarViewController инициализация вкладок происходит по умолчанию при их выборе.
///LazyView - это удобный и простой способ. Он позволяет отложить инициализацию до момента, когда представление действительно потребуется, что может улучшить производительность приложения.
//struct LazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content {
//        build()
//    }
//}





//            .onReceive(NotificationCenter.default.publisher(for: .globalAlert)) { notification in
//                if let alertItem = notification.object as? AlertData {
//                    self.alertMessage = alertItem.message
////                    alertItem.operationDescription
//                    self.showAlert = true
//                }
//            }

// MARK: - before correct initialization of the state -


//import SwiftUI
//import Combine
//
//// Обособленное представление для алертов
//struct GlobalAlertView: View {
//    @Binding var showAlert: Bool
//    @Binding var alertMessage: String
//    
//    init(showAlert: Binding<Bool>, alertMessage: Binding<String>) {
//        self._showAlert = showAlert
//        self._alertMessage = alertMessage
//        print("GlobalAlertView initialized")
//    }
//    
//    var body: some View {
//        EmptyView()
//            .alert("Global error", isPresented: $showAlert) {
//                Button("Ok") {}
//            } message: {
//                Text(alertMessage)
//            }
//    }
//}
//
//
//struct ContentView: View {
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//    
//    private var homeView: LazyView<HomeView> {
//        let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//        let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//        ///errorHandler @EnvironmentObject?
//        let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//        let viewModel = HomeContentViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)
//        let homeContentView = HomeContentView(viewModel: viewModel)
//        return LazyView { HomeView(contentView: homeContentView) }
//    }
//    
//    private var galleryView: LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//    
//    private var profileView: LazyView<ProfileView> {
//        return LazyView { ProfileView() }
//    }
//    
//    @State private var selection: Int = 0
//    @State private var showAlert: Bool = false
//    @State private var alertMessage: String = ""
//    
//    var body: some View {
//        VStack {
//            TabView(selection: $selection) {
//                homeView
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                galleryView
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                profileView
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//            }
//            .background(
//                GlobalAlertView(showAlert: $showAlert, alertMessage: $alertMessage)
//            )
//            .onReceive(NotificationCenter.default.publisher(for: .globalAlert)) { notification in
//                if let alertItem = notification.object as? AlertData {
//                    self.alertMessage = alertItem.message
//                    self.showAlert = true
//                }
//            }
//        }
//    }
//}
//
//
/////в TabBarViewController инициализация вкладок происходит по умолчанию при их выборе.
/////LazyView - это удобный и простой способ. Он позволяет отложить инициализацию до момента, когда представление действительно потребуется, что может улучшить производительность приложения.
//struct LazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content {
//        build()
//    }
//}
//
//






//import SwiftUI
//import Combine
//
//
//struct ContentView: View {
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//
//    private var homeView: LazyView<HomeView> {
//        let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//        let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//        let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//        let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)
//        return LazyView { HomeView(viewModel: viewModel) }
//    }
//
//    private var galleryView: LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//
//    private var profileView: LazyView<ProfileView> {
//        return LazyView { ProfileView() }
//    }
//
//    @State private var selection: Int = 0
//    @State private var showAlert: Bool = false
//    @State private var alertMessage: String = ""
//
//    var body: some View {
//        VStack {
//            TabView(selection: $selection) {
//                homeView
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                galleryView
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                profileView
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//            }
//            .alert("Global error", isPresented: $showAlert) {
//                Button("Ok") {}
//            } message: {
//                Text(alertMessage)
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .globalAlert)) { notification in
//                if let alertItem = notification.object as? AlertData {
//                    self.alertMessage = alertItem.message
//                    self.showAlert = true
//                }
//            }
//        }
//    }
//}
// MARK: - Environment +  @State -

/// теперь при срабатывании @ObservedObject var alertManager повторного инит не происходило но выглядит сложновато

//struct ContentView: View {
//    @ObservedObject var alertManager: AlertManager = AlertManager.shared
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//
//    @State private var homeView: LazyView<AnyView>?
//    @State private var galleryView: LazyView<AnyView>?
//    @State private var profileView: LazyView<AnyView>?
//
//    @State private var selection: Int = 0
//
//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("ContentView get bindingError")
//                return alertManager.globalAlert != nil
//            },
//            set: { newValue in
//                print("ContentView set bindingError - \(newValue)")
//                if !newValue {
//                    alertManager.resetGlobalAlert()
//                }
//            }
//        )
//    }
//
//    var body: some View {
//        TabView(selection: $selection) {
//            if let homeView = homeView {
//                homeView
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//            } else {
//                Text("") // Используем Text("") для заполнения пространства
//                    .tabItem {
//                        Label("Home", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                    .onAppear {
//                        let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//                        let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//                        let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//                        let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)
//                        self.homeView = LazyView { AnyView(HomeView(viewModel: viewModel)) }
//                    }
//            }
//
//            if let galleryView = galleryView {
//                galleryView
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//            } else {
//                Text("") // Используем Text("") для заполнения пространства
//                    .tabItem {
//                        Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                    }
//                    .tag(1)
//                    .onAppear {
//                        self.galleryView = LazyView { AnyView(GalleryView()) }
//                    }
//            }
//
//            if let profileView = profileView {
//                profileView
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//            } else {
//                Text("") // Используем Text("") для заполнения пространства
//                    .tabItem {
//                        Label("Profile", systemImage: "person.crop.circle.fill")
//                    }
//                    .tag(2)
//                    .onAppear {
//                        self.profileView = LazyView { AnyView(ProfileView()) }
//                    }
//            }
//        }
//        .alert("Global error", isPresented: bindingError) {
//            Button("Ok") {}
//        } message: {
//            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
//        }
//    }
//}

// MARK: - after environment -

/// все работало корректно до тех пор пока не срабатывал @ObservedObject var alertManager и происходила перерисовка ContentView с повторной инит homeView

//struct ContentView: View {
//
//    /// можем пользоваться alertManager из managerCRUDS?
//    @ObservedObject var alertManager:AlertManager = AlertManager.shared
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//
//   private var homeView:LazyView<HomeView> {
//        let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//        let firestoreCollectionObserver = FirestoreCollectionObserverService() as FirestoreCollectionObserverProtocol
//        let errorHandler = SharedErrorHandler() as ErrorHandlerProtocol
//        let viewModel = HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)
//        return LazyView { HomeView(viewModel: viewModel) }
//    }
//
//    private var galleryView:LazyView<GalleryView> {
//        return LazyView { GalleryView() }
//    }
//
//    private var profileView:LazyView<ProfileView> {
//        return LazyView { ProfileView() }
//    }
//
//    @State private var selection:Int = 0
//
//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("ContentView get bindingError")
//                return alertManager.globalAlert != nil
//            },
//            set: { newValue in
//                print("ContentView set bindingError - \(newValue)")
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
//            homeView
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
//                .tag(0)
//            galleryView
//                .tabItem {
//                    Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                }
//                .tag(1)
//            profileView
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle.fill")
//                }
//                .tag(2)
//        }
//        .alert("Global error", isPresented: bindingError) {
//            Button("Ok") {}
//        } message: {
//            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
//        }
//    }
//}


// MARK: - before environment

//import SwiftUI
//import Combine
//
//
//struct ContentView: View {
//    
//    @ObservedObject var alertManager:AlertManager
//    
//    private let homeView:HomeView
//    private let galleryView:GalleryView
//    private let profileView:ProfileView
//    
//    @State private var selection:Int
//    
//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("ContentView get bindingError")
//                return alertManager.globalAlert != nil
//            },
//            set: { newValue in
//                print("ContentView set bindingError - \(newValue)")
//                if !newValue {
//                    alertManager.resetGlobalAlert()
//                }
//            }
//        )
//    }
//    
//    init(alertManager: AlertManager = AlertManager.shared, homeView: HomeView, galleryView: GalleryView, profileView: ProfileView, selection: Int = 0) {
//        self.alertManager = alertManager
//        self.homeView = homeView
//        self.galleryView = galleryView
//        self.profileView = profileView
//        self.selection = selection
//    }
//    
//    var body: some View {
//        TabView(selection: $selection) {
//            
//            homeView
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                        .tag(0)
//                }
//            galleryView
//                .tabItem {
//                    Label("Gallery", systemImage: "photo.on.rectangle.fill")
//                        .tag(1)
//                }
//            profileView
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle.fill")
//                        .tag(2)
//                }
//        }
//        .alert("Global error", isPresented: bindingError) {
//            Button("Ok") {}
//        } message: {
//            Text(alertManager.globalAlert?.message ?? "Something went wrong. Please try again later.")
//        }
//    }
//}
//




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




//            let authenticationService = AuthenticationService() as AuthenticationServiceProtocol
//            GalleryView()
