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


import SwiftUI
import Combine


struct HomeView: View {
    
    @StateObject private var viewModel:HomeViewModel
    @State var presentAddBookSheet:Bool = false
    
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
                    errorView(error: error)
                case .content(let data):
                    contentView(data: data)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Home")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        self.presentAddBookSheet.toggle()
                    }
                    .foregroundStyle(AppColors.activeColor)
                    .padding()
                    .disabled(viewModel.viewState.isError)
                }
            }
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
            .sheet(isPresented: $presentAddBookSheet) {
                let viewModel = BookViewModel()
                BookEditView(viewModel: viewModel)
            }
        }
    }
    
    private func errorView(error:String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView(label: {
                Label("Connection issue", systemImage: "wifi.slash")
            }, description: {
                Text("Check your internet connection")
            }, actions: {
                Button("Refresh") {
                    viewModel.retry()
                }
            })
            .background(AppColors.secondaryBackground)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .ignoresSafeArea(edges: [.horizontal])
    }
    
    private func contentView(data:[BookRealtime]) -> some View {
        VStack {
            Spacer()
            List(data) { item in
                Text(item.title)
            }
            .background(AppColors.activeColor)
            Spacer()
        }
        .ignoresSafeArea(edges: [.horizontal])
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


    

//        .navigationTitle("Home")
//        .toolbar{
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Add") {
//                    print("Add item for List")
//                }
//                .foregroundStyle(AppColors.activeColor)
//                .padding()
//
//            }
//        }
//        .background(AppColors.background)
//        .alert("Error", isPresented: .constant(viewModel.viewState.isError) ) {
//            Button("Retry") {
//                viewModel.retry()
//            }
//            Button("Cancel", role: .cancel) {
//                print("DidTapAlertCancel")
//            }
//        } message: {
//            Text(viewModel.viewState.errorMessage ?? "Try again later")
//        }
    
// MARK: - Trush

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










