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

import SwiftUI
import Combine


struct HomeView: View {
    
    @StateObject private var viewModel:HomeViewModel
    
    init(viewModel:HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.viewState {
                case .loading:
                    ProgressView("Loading...")
                case .error(let error):
                    VStack{
                        Spacer() // Отступ сверху, который растягивается до начала Safe Area
                        ContentUnavailableView {
                            Label("Connection issue", systemImage: "wifi.slash")
                        } description: {
                            Text("Check your internet connection")
                        } actions: {
                            Button("Refresh") {
                                print("Did Tap Refresh ContentUnavailableView")
                                viewModel.retry()
                            }
                        }
                        .background(Color.red.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        Spacer() // Отступ снизу, который растягивается до конца Safe Area
                    }
                    .edgesIgnoringSafeArea([.horizontal])
                case .content(let data):
                    List(data, id: \.self) { item in
                        Text(item)
                    }
                    .background(Color.green)
                }
            }
        }
        .navigationTitle("Home")
        .alert("Error", isPresented: .constant(viewModel.viewState.isError) ) {
            Button("Retry") {
                viewModel.retry()
            }
            Button("Cancel", role: .cancel) {
                print("DidTapAlertCancel")
            }
        } message: {
            Text(viewModel.viewState.errorMessage ?? "Try again later")
        }
    }
}
    
extension ViewState {
    var isError:Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case let .error(message) = self {
            return message
        }
        return nil
    }
}


    
    
    
//    private var content: some View {
//        
//        List(viewModel.data, id: \.self) { item in
//            Text(item)
//        }
//        .background(Color.green)
//    }

//struct HomeView: View {
//    @StateObject private var viewModel: HomeViewModel
//    @State private var showPlaceholder = false
//    
//    init(viewModel: HomeViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//        _showPlaceholder = State(initialValue: viewModel.errorMessage != nil)
//    }
//    
//    var body: some View {
//        NavigationView {
//            
//            ZStack {
//                if viewModel.isLoading {
//                    ProgressView("Loading...")
//                } else if showPlaceholder {
//                    VStack{
//                        Spacer() // Отступ сверху, который растягивается до начала Safe Area
//                        ContentUnavailableView {
//                            Label("Connection issue", systemImage: "wifi.slash")
//                        } description: {
//                            Text("Check your internet connection")
//                        } actions: {
//                            Button("Refresh") {
//                                print("Did Tap Refresh ContentUnavailableView")
//                                viewModel.retry()
//                            }
//                        }
//                        .background(Color.red.opacity(0.5))
//                        .frame(maxWidth: .infinity)
//                        Spacer() // Отступ снизу, который растягивается до конца Safe Area
//                    }
//                    .edgesIgnoringSafeArea([.horizontal]) 
//                } else {
//                    content
//                }
//            }
//            .navigationTitle("Home")
//            .alert("Error", isPresented: isAlertPresented()) {
//                Button("Retry") {
//                    viewModel.retry()
//                }
//                Button("Cancel", role: .cancel) {
//                    print("DidTapAlertCancel")
//                }
//            } message: {
//                Text(viewModel.errorMessage ?? "Try again later")
//            }
//            .onChange(of: viewModel.errorMessage) { oldValue, newValue in
//                if newValue == nil {
//                    showPlaceholder = false
//                    print("showPlaceholder = false")
//                } else {
//                    showPlaceholder = true
//                    print("showPlaceholder = true")
//                }
//            }
//        }
//    }
//    
//    private var content: some View {
//        
//        List(viewModel.data, id: \.self) { item in
//            Text(item)
//        }
//        .background(Color.green)
//    }
//    
//    private func isAlertPresented() -> Binding<Bool> {
//        Binding {
//            viewModel.errorMessage != nil
//        } set: { _ in }
//    }
//}







//            ZStack {
//                if viewModel.isLoading {
//                    ProgressView("Loading...")
//                } else {
//                    content
//                }
//            }
//            .navigationTitle("Home")
//            .overlay {
//                if showPlaceholder {
//                    ContentUnavailableView {
//                        Label("Connection issue", systemImage: "wifi.slash")
//                    } description: {
//                        Text("Check your internet connection")
//                    } actions: {
//                        Button("Refresh") {
//                            print("Did Tap Refresh ContentUnavailableView")
//                            viewModel.retry()
//                        }
//                    }
//                    .background(Color.red.opacity(0.5))
//                    .padding()
//
//                }
//            }


//struct HomeView: View {
//    @StateObject private var viewModel: HomeViewModel
//    @State private var showPlaceholder = false
//    @State private var showAlert = false
//
//    init(viewModel: HomeViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//        _showPlaceholder = State(initialValue: viewModel.errorMessage != nil)
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                if viewModel.isLoading {
//                    ProgressView("Loading...")
//                } else {
//                    content
//                }
//            }
//            .navigationTitle("Home")
//            .overlay {
//                if showPlaceholder {
//                    ContentUnavailableView {
//                        Label("Connection issue", systemImage: "wifi.slash")
//                    } description: {
//                        Text("Check your internet connection")
//                    } actions: {
//                        Button("Refresh") {
//                            print("Did Tap Refresh ContentUnavailableView")
//                            viewModel.retry()
//                        }
//                    }
//                    .background(Color.red.opacity(0.5))
//                    .padding()
//
//                }
//            }
//            .alert("Error", isPresented: $showAlert) {
//                Button("Retry") {
////                    showAlert = false // Сброс состояния алерта перед новой попыткой
//                    viewModel.retry()
//                }
//                Button("Cancel", role: .cancel) {
//                    print("DidTapAlertCancel")
//                    showAlert = false
//                }
//            } message: {
//                Text(viewModel.errorMessage ?? "Try again later")
//            }
//            .onChange(of: viewModel.errorMessage) { _, newValue in
//                          showAlert = false // Сброс состояния алерта перед новой попыткой
//                          if newValue == nil {
//                              showPlaceholder = false
//                          } else {
//                              showPlaceholder = true
//                              showAlert = true // Отобразить алерт при новой ошибке
//                          }
//                      }
////            .onChange(of: viewModel.errorMessage) { oldValue, newValue in
////                if newValue == nil {
////                    showPlaceholder = false
////                } else {
////                    showPlaceholder = true
////                    showAlert = true // Отобразить алерт при наличии ошибки
////                }
////            }
//        }
//    }
//
//    private var content: some View {
//        List(viewModel.data, id: \.self) { item in
//            Text(item)
//        }
//    }
//}


//    private func isAlertPresented() -> Binding<Bool> {
//        return Binding {
//            viewModel.errorMessage != nil
//        } set: { newValue in
//            print("newValue - \(newValue)")
//            if !newValue  {
//                viewModel.errorMessage = nil
//            }
//        }
//    }

//            ZStack {
//                if viewModel.isLoading {
//                    ProgressView("Loading...")
//                } else if showPlaceholder {
//                    ContentUnavailableView {
//                        Label("Connection issue", systemImage: "wifi.slash")
//                    } description: {
//                        Text("Check your internet connection")
//                    } actions: {
//                        Button("Refresh") {
//                            print("Did Tap Refresh ContentUnavailableView")
//                        }
//                    }
//                    .background(Color.red.opacity(0.5))
//                } else {
//                    content
//                }
//            }

//struct HomeView: View {
//    
//    @StateObject private var viewModel: HomeViewModel
//    @State private var showPlaceholder = false
//    
//    init(viewModel: HomeViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//        _showPlaceholder = State(initialValue: viewModel.errorMessage != nil)
//    }
//    
//    var body: some View {
//        
//        ZStack {
//            if viewModel.isLoading {
//                ProgressView("Loading...")
//            } else if showPlaceholder {
//                //                PlaceholderView()
//            } else {
//                content
//            }
//            
//        }
//        .alert("Error", isPresented: isAlertPresented()) {
//            Button("Retry") {
//                viewModel.retry()
//            }
//            Button("Cancel", role: .cancel) {
//                print("DidTapAlertCancel")
//            }
//        } message: {
//            Text(viewModel.errorMessage ?? "Try again later")
//        }
//        .onChange(of: viewModel.errorMessage) { oldValue, newValue in
//            if newValue == nil {
//                showPlaceholder = false
//            } else {
//                showPlaceholder = true
//            }
//        }
//    }
//    
//    private var content: some View {
//        List(viewModel.data, id: \.self) { item in
//            Text(item)
//        }
//    }
//    
//    private func isAlertPresented() -> Binding<Bool> {
//        Binding {
//            viewModel.errorMessage != nil
//        } set: { newValue in
//            if !newValue  {
//                viewModel.errorMessage = nil
//            }
//        }
//    }
//}


//ZStack {
//    if viewModel.isLoading {
//        ProgressView("Loading...")
//    } else {
//        content
//    }
//}

//        .overlay {
//            if showPlaceholder {
//                ContentUnavailableView {
//                    Label("Connection issue", systemImage: "wifi.slash")
//                } description: {
//                    Text("Check your internet connection")
//                } actions: {
//                    Button("Refresh") {
//                        print("Did Tap Refresh ContentUnavailableView")
//                    }
//                }
//                .background(Color.red.opacity(0.5))
//            }
//        }
// MARK: - Trush

//    @ObservedObject private var viewModelWrapper: AnyViewModelWrapper
//
//    init(viewModel: any HomeViewModelProtocol) {
//        self.viewModelWrapper = AnyViewModelWrapper(wrapped: viewModel)
//    }

//struct HomeView: View {
//
//    @StateObject private var viewModel: HomeViewModel
//
//        init(viewModel: HomeViewModel) {
//            _viewModel = StateObject(wrappedValue: viewModel)
//        }
//
//    var body: some View {
//        ZStack {
//
//        }
//
//    }
//}

//            Color.purple
//                .ignoresSafeArea()
//            Text("I'm Home")
//                .font(.system(.largeTitle, design: .monospaced, weight: .black))
