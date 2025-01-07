//
//  HomeView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//


///.alert(isPresented: $showAlert, error: error)
/// Используя Binding<Bool>, ты создаёшь двустороннюю привязку к свойству errorMessage
/// get: Возвращает true, если errorMessage не равно nil, что означает, что есть ошибка, и алерт должен быть показан.
/// set: Если newValue равен false (то есть, когда алерт закрывается), устанавливает errorMessage в nil, что скрывает алерт.

/// @State private var showPlaceholder = false Первая инициализация State(initialValue: viewModel.errorMessage != nil) Вторичная инициализация Это позволяет заглушке быть видимой сразу при первом запуске, если ошибка уже есть. Чтобы гарантировать корректное поведение

/// Ты совершенно прав. Метод isAlertPresented создаёт Binding для свойства, которое изначально таковым не является.
/// Binding — это специальный тип в SwiftUI, который создает связь между источником данных и представлением. Он позволяет представлению не только получать значения, но и изменять их.
///  Позволяет изменять данные через UI и обновлять UI при изменении данных.

///.onChange — это модификатор представления в SwiftUI, который позволяет реагировать на изменения состояния или значения. Он вызывает указанное действие каждый раз, когда значение изменяется.

/// Safe Area: Это область экрана, которая не перекрыта системными элементами интерфейса, такими как NavigationBar и TabBar. Когда ты используешь Spacer, он заполняет доступное пространство внутри Safe Area.

///if viewModel.isLoading: Отображает ProgressView только при viewModel.isLoading = true.
///else if showPlaceholder: Отображает ContentUnavailableView, если showPlaceholder = true.
///else: Отображает content, когда оба viewModel.isLoading и showPlaceholder равны false.

///Неизменное состояние: Мы используем .constant, когда значение, которое мы передаём, не должно изменяться. В данном случае, viewModel.viewState.isError возвращает значение, которое не изменяется напрямую, а зависит от состояния представления.
///Облегчение кода: Это упрощает код, так как нам не нужно создавать отдельное состояние для управления видимостью алерта.

///Когда case .loading:, ProgressView автоматически отображается и начинает анимацию.
///Когда viewModel.isLoading становится false, ProgressView исчезает из экрана.

///.sheet - В SwiftUI, если BookViewModel деинициализирован, то можно быть уверенным, что и связанный с ним BookEditView также был удален из памяти, при условии, что на него не было других сильных ссылок.
///SwiftUI автоматически управляет жизненным циклом представлений и связанных объектов, таких как ViewModels. Это означает, что когда представление больше не нужно (например, после закрытия модального окна), связанные объекты также удаляются из памяти, если нет других сильных ссылок на них.

///Эти индексы генерируются на основе позиций элементов в List, когда пользователь делает свайп для удаления.
///IndexSet может содержать один или несколько индексов, в зависимости от того, сколько элементов было выбрано для удаления.
///setIndex.lazy.map { data[$0] } lazy - вычисления выполняются только тогда, когда мы действительно обращаемся к элементам последовательности.
///
///get: { viewModel.showAlert && isVisibleView } - до тех пор пока вырожение false alert не отработает.

///
/// на HomeView при открытом alert мы перерисовывали HomeView удаляя документ с сервера
/// срабатывал get у bindingError но не блок set , alert оставался живым
/// почему мы обеспокоиным этим поведением , потому что когда мы использовали Binding для .sheet то при перерисовки view на котором у нас открывался модальный экран срабатывал binding и его блок set со значением false что саоуничтожало модальный экран - помог SheetManager
/// Различия в поведении могут объясняться тем, как SwiftUI обрабатывает состояния для различных видов представлений. Для sheet, важно постоянное обновление состояния, чтобы избежать дублирования (поэтому когда у нас обновлялся bindingSheet в set создать новый он не мог так как генерировался false - !viewModel.isSheetActive && presentAddBookSheet ноj set вызывался что бы избежать дублирования автоматически - ответ чата). Для alert, достаточно установить состояние в true, чтобы отобразить алерт, и управлять его закрытием через пользовательские действия.

import SwiftUI
import Combine


struct HomeView: View {
    
    @StateObject private var viewModel:HomeViewModel
    
    @State private var isSubscribed = false
    
    //sheet
    @State private var isShowSheet:Bool = false
    
    //alert
    @State private var isShowAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(sheetManager: SheetManager.shared, alertManager: AlertManager.shared))
    }
    
    var body: some View {
        
        VStack {
            let _ = Self._printChanges()
            HomeContentView()
//            Text("\(isShowSheet)")
        }
        .sheet(isPresented: $isShowSheet) {
            
            BookEditView(managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()))
        }
        .onAppear {
            print("onAppear HomeView")
            guard !isSubscribed else { return }
            isSubscribed = true
            subscribeToActionSheet()
            subscribeToLocalAlerts()
        }
        .onDisappear {
            print("onDisappear HomeView")
        }
        .background {
            AlertViewLocal(isShowAlert: $isShowAlert, alertMessage: $alertMessage, nameView: "HomeView")
        }
    }
    
    private func subscribeToActionSheet() {
        viewModel.sheetManager.$isPresented
            .sink { isPresented in
                print(".sink { isPresented - \(isPresented)")
                isShowSheet = isPresented
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToLocalAlerts() {
        viewModel.alertManager.$localAlerts
            .combineLatest(viewModel.alertManager.$isHomeViewVisible)
            .sink { (localAlert, isHomeViewVisible) in
                print(".sink { (localAlert, isHomeViewVisible)")
                if isHomeViewVisible, let alert = localAlert["HomeView"], !localAlert.isEmpty {
                    print(".sink showAlert = true")
                    alertMessage = alert.first?.message ?? ""
                    isShowAlert = true
                }
            }
            .store(in: &cancellables)
    }
}




/// либо оставить пересоздание HomeContentView без инит его зависимостей или попробывать $viewModel.alertManager.isShowAlert
//        .alert("Local error", isPresented: $isShowAlert) {
//            Button("Ok") {
//                isShowAlert = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    viewModel.alertManager.resetFirstLocalAlert(forView: "HomeView")
//                }
//
//            }
//        } message: {
//            Text(alertMessage)
//        }

//struct LocalAlertView: View {
//    @State var showAlert: Bool
//    @State var alertMessage: String
//    @ObservedObject var alertManager: AlertManager
//    @State private var cancellables = Set<AnyCancellable>()
//    @State private var isSubscribed = false
//
//    private var nameView: String
//
//    init(showAlert: Bool = false, alertMessage: String = "", nameView: String, alertManager: AlertManager = AlertManager.shared) {
//        self.showAlert = showAlert
//        self.alertMessage = alertMessage
//        self.nameView = nameView
//        self.alertManager = alertManager
//        print("init LocalAlertView")
//    }
//
//    var body: some View {
//        EmptyView()
//            .alert("Local error", isPresented: $showAlert) {
//                Button("Ok") {
//                    showAlert = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        alertManager.resetFirstLocalAlert(forView: nameView)
//                    }
//
//                }
//            } message: {
//                Text(alertMessage)
//            }
//            .onAppear {
//                print("onAppear LocalAlertView")
//                guard !isSubscribed else { return }
//                subscribeToLocalAlerts()
//            }
//            .onDisappear {
//                print("onDisappear LocalAlertView")
////                unsubscribeFromLocalAlerts()
//            }
//    }
//
//    private func subscribeToLocalAlerts() {
//        isSubscribed = true
//        alertManager.$localAlerts
//            .combineLatest(alertManager.$isHomeViewVisible)
//            .sink { (localAlert, isHomeViewVisible) in
//                print(".sink { (localAlert, isHomeViewVisible)")
//                if isHomeViewVisible, let alert = localAlert[nameView], !localAlert.isEmpty {
//                    print(".sink showAlert = true")
//                    alertMessage = alert.first?.message ?? ""
//                    showAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    func unsubscribeFromLocalAlerts() {
//        cancellables.removeAll()
//    }
//}
///Если мы какое-то поле поменяем в EnvironmentObject то и вся view тоже перерисует!
///При чем не важно используем ли мы это поле на view.


//        Group {
//            let _ = Self._printChanges()
//            HomeContentView(authenticationService: AuthenticationService() , firestoreCollectionObserverService: FirestoreCollectionObserverService(), managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()), errorHandler: SharedErrorHandler())
//                .background {
//                    SheetHomeView()
//                }
//                .background {
//                    LocalAlertView(nameView: "HomeView")
//                }
//                .onAppear {
//                    print("onAppear HomeView")
//                }
//                .onDisappear {
//                    print("onDisappear HomeView")
//                }
//        }

// MARK: - before correct initialization of the state -

//import SwiftUI
//import Combine
//
//struct SheetHomeView:View {
//
////    @EnvironmentObject private var sheetManager:SheetManager
//    //$sheetManager.isPresented
//    private var sheetManager = SheetManager.shared
//    @State private var isSubscribed = false
//    @State private var cancellables = Set<AnyCancellable>()
//    @State private var isShow:Bool = false {
//        didSet {
//            print("isShow - \(isShow)")
//        }
//    }
//
//    init() {
//        print("init SheetHomeView")
//    }
//
//    var body: some View {
//        EmptyView()
//            .sheet(isPresented: $isShow) {
//
//                BookEditView(managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService()))
//            }
//            .onAppear {
//
//                print("onAppear SheetHomeView")
//                guard !isSubscribed else { return }
//                isSubscribed = true
//                sheetManager.$isPresented
//                    .sink { isPresented in
//                        print(".sink { isPresented - \(isPresented)")
//                        isShow = isPresented
//                    }
//                    .store(in: &cancellables)
//            }
//            .onDisappear {
//                print("onDisappear SheetHomeView")
//
//            }
//    }
//}


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


//import SwiftUI
//import Combine
//
//struct LocalAlertView: View {
//    @State var showAlert: Bool
//    @State var alertMessage: String
//    @ObservedObject var alertManager: AlertManager
//    @State private var cancellables = Set<AnyCancellable>()
//    @State private var isSubscribed = false
//    
//    private var nameView: String
//    
//    init(showAlert: Bool = false, alertMessage: String = "", nameView: String, alertManager: AlertManager = AlertManager.shared) {
//        self.showAlert = showAlert
//        self.alertMessage = alertMessage
//        self.nameView = nameView
//        self.alertManager = alertManager
//        print("init LocalAlertView")
//    }
//    
//    var body: some View {
//        EmptyView()
//            .alert("Local error", isPresented: $showAlert) {
//                Button("Ok") {
//                    showAlert = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        alertManager.resetFirstLocalAlert(forView: nameView)
//                    }
//                    
//                }
//            } message: {
//                Text(alertMessage)
//            }
//            .onAppear {
//                print("onAppear LocalAlertView")
//                guard !isSubscribed else { return }
//                subscribeToLocalAlerts()
//            }
//            .onDisappear {
//                print("onDisappear LocalAlertView")
////                unsubscribeFromLocalAlerts()
//            }
//    }
//    
//    private func subscribeToLocalAlerts() {
//        isSubscribed = true
//        alertManager.$localAlerts
//            .combineLatest(alertManager.$isHomeViewVisible)
//            .sink { (localAlert, isHomeViewVisible) in
//                print(".sink { (localAlert, isHomeViewVisible)")
//                if isHomeViewVisible, let alert = localAlert[nameView], !localAlert.isEmpty {
//                    print(".sink showAlert = true")
//                    alertMessage = alert.first?.message ?? ""
//                    showAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    func unsubscribeFromLocalAlerts() {
//        cancellables.removeAll()
//    }
//}
//
//
//struct HomeView: View {
//    
//    var contentView:HomeContentView
//    private var sheetManager:SheetManager
//    
//    init(contentView:HomeContentView, sheetManager:SheetManager = SheetManager()) {
//        self.contentView = contentView
//        self.sheetManager = sheetManager
//        print("init HomeView")
//    }
//    
//    var body: some View {
//        Group {
//                contentView
//                .background {
//                    SheetHomeView()
//                }
//                .background {
//                    LocalAlertView(nameView: "HomeView")
//                }
//                .onAppear {
//                    print("onAppear HomeView")
//                }
//                .onDisappear {
//                    print("onDisappear HomeView")
//                }
//        }
//        .environmentObject(sheetManager)
//    }
//}








//struct LocalAlertView: View {
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



//                alertManager.$localAlerts
//                    .sink { localAlert in
//
//                        if alertManager.isHomeViewVisible, let alert = localAlert[nameView], !localAlert.isEmpty {
//                            print(".sink showAlert = true")
//                            alertMessage = alert.first?.message ?? ""
//                            showAlert = true
//                        }
//                    }
//                    .store(in: &cancellables)




//    @ViewBuilder
//    private func localAlertView() -> some View {
//        LocalAlertView(nameView: "HomeView")
//    }



//import SwiftUI
//import Combine
//
//class LocalAlertViewModel: ObservableObject {
//    @Published var showAlert: Bool = false
//    @Published var alertMessage: String = ""
//
//    private var cancellables = Set<AnyCancellable>()
//    private var alertManager: AlertManager
//    private var nameView: String
//
//    init(nameView: String, alertManager: AlertManager = AlertManager.shared) {
//        self.nameView = nameView
//        self.alertManager = alertManager
//
//        // Подписка на изменения в localAlerts
//        alertManager.$localAlerts
//            .map { $0[nameView]?.isEmpty == false }
//            .sink { [weak self] in
//                if let self = self, $0 {
//                    self.alertMessage = self.alertManager.localAlerts[self.nameView]?.first?.message ?? ""
//                    self.showAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    deinit {
//        cancellables.forEach { $0.cancel() }
//    }
//}
//
//struct LocalAlertView: View {
//    @StateObject private var viewModel: LocalAlertViewModel
//
//    init(nameView: String) {
//        _viewModel = StateObject(wrappedValue: LocalAlertViewModel(nameView: nameView))
//        print("init LocalAlertView")
//    }
//
//    var body: some View {
//        EmptyView()
//            .alert("Local error", isPresented: $viewModel.showAlert) {
//                Button("Ok") {
//                    viewModel.showAlert = false
//                }
//            } message: {
//                Text(viewModel.alertMessage)
//            }
//    }
//}

//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("HomeView get bindingError")
//                return isVisibleView && (viewModel.alertManager.localAlerts["HomeView"] != nil)
//            },
//            set: { newValue in
//                print("HomeView set bindingError - \(newValue)")
//                if !newValue {
//                    viewModel.alertManager.resetFirstLocalAlert(forView: "HomeView")
//                }
//            }
//        )
//    }

 
//            .alert("Local error", isPresented: bindingError) {
//                Button("Ok") {}
//            } message: {
//                Text(viewModel.alertManager.localAlerts["HomeView"]?.first?.message ?? "Something went wrong. Please try again later.")
//            }


// MARK: - a old understanding of how bindingError works -

//import SwiftUI
//import Combine
//
//
//struct HomeView: View {
//    
//    @StateObject private var viewModel:HomeViewModel
//    @StateObject private var sheetManager:SheetManager
//    
//    @EnvironmentObject var managerCRUDS: CRUDSManager
//    
//    @State var isVisibleView: Bool = true // Флаг активности представления
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    private var bindingError: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("HomeView get bindingError")
//                return isVisibleView && (viewModel.alertManager.localAlerts["HomeView"] != nil)
//            },
//            set: { newValue in
//                print("HomeView set bindingError - \(newValue)")
//                if !newValue {
//                    viewModel.alertManager.resetFirstLocalAlert(forView: "HomeView")
//                }
//            }
//        )
//    }
//    
//    init(viewModel:HomeViewModel, sheetManager: SheetManager = SheetManager()) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//        _sheetManager = StateObject(wrappedValue: sheetManager)
//        print("init HomeView")
//    }
//    
//    var body: some View {
//        NavigationView {
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
////            .navigationBarTitleDisplayMode(.inline)
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
//            
//            .sheet(isPresented: $sheetManager.isPresented) {
//                let bookViewModel = BookViewModel(managerCRUDS: managerCRUDS)
//                BookEditView(viewModel: bookViewModel)
//            }
//            .alert("Local error", isPresented: bindingError) {
//                Button("Ok") {}
//            } message: {
//                Text(viewModel.alertManager.localAlerts["HomeView"]?.first?.message ?? "Something went wrong. Please try again later.")
//            }
//            .onAppear {
//                print("onAppear HomeView")
//                isVisibleView = true
//            }
//            .onDisappear {
//                print("onDisappear HomeView")
//                isVisibleView = false
//            }
//        }
//    }
//    
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
//





//            .onChange(of: viewModel.alertManager.showLocalAlert, { oldValue, newValue in
//                print(".onChange showLocalAlert")
//                bindingError.wrappedValue = true
//            })
//            .onChange(of: viewModel.alertManager.localAlerts["HomeView"]) { newValue in if isVisibleView && (newValue?.isEmpty == false) { bindingError.wrappedValue = true } }


//                viewModel.alertManager.$showLocalAlert
//                    .sink { isShowAlert in
//                        print(".sink { isShowAlert")
//                        if isShowAlert == true {
//                            bindingError.wrappedValue = true
//                        }
//                    }
//                    .store(in: &cancellables)
//                viewModel.alertManager.$localAlerts .map { $0["HomeView"] }
//                    .sink { newValue in
//                    if isVisibleView && (newValue?.isEmpty == false) {
//                        bindingError.wrappedValue = true
//                    }
//                }
//                .store(in: &cancellables)


/// before func resetFirstLocalAlert
//private var bindingError: Binding<Bool> {
//    Binding<Bool>(
//        get: {
//            print("HomeView get bindingError")
//            return isVisibleView && (viewModel.alertManager.localAlerts["HomeView"] != nil)
//        },
//        set: { newValue in
//            print("HomeView set bindingError - \(newValue)")
//            if !newValue {
//                viewModel.alertManager.resetLocalAlert(forView: "HomeView")
//            }
//        }
//    )
//}

// sheet logic



//    @State var presentAddBookSheet:Bool = false
//presentAddBookSheet = true
//    private var bindingSheet: Binding<Bool> {
//        Binding<Bool>(
//            get: {
//                print("get bindingSheet - isSheetActive - \(viewModel.isSheetActive)")
//                print("get bindingSheet - presentAddBookSheet - \(presentAddBookSheet)")
////                !viewModel.isSheetActive ? presentAddBookSheet : false
//                return !viewModel.isSheetActive && presentAddBookSheet
//            },
//            set: { newValue in
//                print("set bindingSheet - \(newValue)")
//                viewModel.isSheetActive = newValue
//                presentAddBookSheet = newValue
//            }
//        )
//    }


//                    BookEditView(viewModel: bookViewModel)
//                    .onAppear {
//                        viewModel.isSheetActive = true
//                    }



//            .alert("Error", isPresented: .constant(viewModel.viewState.isError) ) {
//                Button("Retry") {
//                    viewModel.retry()
//                }
//                Button("Ok") {}
//            } message: {
//                Text(viewModel.viewState.errorMessage ?? "Something went wrong. Please try again later.")
//            }


//            .alert("Error", isPresented: Binding<Bool>(
//                get: { viewModel.showAlert && isVisibleView },
//                set: { newValue in
//                    print("set Delete error")
//                    viewModel.showAlert = newValue
//                }
//            )) {
//                Button("Ok") {
//                    viewModel.resetErrorProperty()
//                }
//            } message: {
//                VStack {
//                    Text("Failed to delete book")
//                    Text(viewModel.alertMessage ?? "Something went wrong. Please try again later.")
//                }
//            }


//extension View { func errorAlert(isPresented: Binding<Bool>, message: String?, retryAction: @escaping () -> Void) -> some View { self.alert("Error", isPresented: isPresented) { Button("Retry", action: retryAction) Button("Cancel", role: .cancel) {} } message: { Text(message ?? "Try again later") } } }

    


    
// MARK: - Trush

//                        .clipShape(.circle)
//                        .shadow(radius: 3)
//                        .overlay(content: {
//                            Circle().stroke(.black, lineWidth: 2)
//                        })

//        VStack {
//            Spacer()
//            List(data) { item in
//                Text(item.title)
//            }
//            .background(AppColors.activeColor)
//            Spacer()
//        }
//        .ignoresSafeArea(edges: [.horizontal])

//        List(data) { book in
//            bookRowView(book)
//        }
//        .listStyle(.plain)
