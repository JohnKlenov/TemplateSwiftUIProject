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

import SwiftUI
import Combine


struct HomeView: View {
    
    @StateObject private var viewModel:HomeViewModel
    @State var presentAddBookSheet:Bool = false
    @State var isActive: Bool = true // Флаг активности представления

    private var binding: Binding<Bool> {
        Binding<Bool>(
            get: {
                return !viewModel.isSheetActive ? presentAddBookSheet : false
            },
            set: { newValue in
                viewModel.isSheetActive = newValue
                presentAddBookSheet = newValue
            }
        )
    }
            
    init(viewModel:HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.viewState {
                case .loading:
                    ProgressView("Loading...")
                case .content(let data):
                    contentView(data: data)
                case .errorChangeAuth(let error):
                    errorView(error: error)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Home")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        presentAddBookSheet = true
                    }
                    .foregroundStyle(AppColors.activeColor)
                    .padding()
                    .disabled(viewModel.viewState.isError)
                }
            }
            
            .sheet(isPresented: binding) {
//                    let databaseService = RealtimeDatabaseCRUDService()
                    let databaseService = FirestoreDatabaseCRUDService()
                    let authService = AuthService()
                    let errorService = SharedErrorHandler()
                    let bookViewModel = BookViewModel(databaseService: databaseService, authService: authService, errorHandler: errorService)
                    BookEditView(viewModel: bookViewModel)
                    .onAppear {
                        viewModel.isSheetActive = true
                    }
                
            }
            .alert("Error", isPresented: .constant(viewModel.viewState.isError) ) {
                Button("Retry") {
                    viewModel.retry()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(viewModel.viewState.errorMessage ?? "Try again later")
            }
            .alert("Delete error", isPresented: Binding<Bool>(
                get: { viewModel.showAlert && isActive },
                set: { newValue in
                    viewModel.showAlert = newValue
                }
            )) {
                Button("Cancel", role: .cancel) {
                    viewModel.resetErrorProperty()
                }
            } message: {
                Text(viewModel.alertMessage ?? "Try again later")
            }
            .onAppear {
                print("onAppear HomeView")
                isActive = true
            }
            .onDisappear {
                print("onDisappear HomeView")
                isActive = false
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

    private func contentView(data:[BookCloud]) -> some View {
        List {
            ForEach(data) { book in
                bookRowView(book)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.removeBook(book: book)
                        } label: {
                            Label("delete", systemImage: "trash.fill")
                        }
                        
                    }
            }
        }
    }
    
    private func bookRowView(_ book: BookCloud) -> some View {
        NavigationLink {
            BookDetailsView(book: book)
        } label: {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: "swift")
                        .foregroundStyle(.pink)
                        .frame(width: 30, height: 30)
                    
                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.headline)
                        Text(book.description)
                            .font(.subheadline)
                        Text(book.author)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
    }
}
    



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
