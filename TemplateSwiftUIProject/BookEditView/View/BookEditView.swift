//
//  BookEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//

/// вот это нам нужно что бы общаться с DetailView для его удаления из стека navView при удалении Book из BookEditView?
/// В struct BookEditView - > var completionHandler: ((Result<Action, Error>) -> Void)?
//enum Action {
//  case delete
//  case done
//  case cancel
//}


///SwiftUI: Асинхронная обработка событий
///UIKit: Синхронная обработка событий гарантирует последовательность и предсказуемость действий

///Если захотим отколонить фокус с текст филдов може использовать жест на форму по двойному тапу.

///alertMessage принимает все ошибки даже те что можно было не отображать(нет сети или что то что невелирвует кэш)

/// Стратегия обработки алертов в App
/// Мы не ждем ответа от сервера с методами которые работают с локальным кэшом.
/// Ошибки которые приходят в таких сценариях мы отправляем в локальный алерт самого root view с которого был осуществлен переход до ошибки(он должен всегда жить в памяти в рамках одной сессии)
/// Все ошибки которые поступают на счет этого root view накапливаются в словаре (если ошибки одинаковые по errorMassege то они объединяются в одну) и отображаются в виде alert на rootView по очереди, при каждом уничтожении отображенного алерта удаляется ошибка из словаря в alertManager и далее если есть еще ошибки в словаре для этого root view отображаются последовательно.



import SwiftUI

enum Action {
    case done(BookCloud)
    case delete
    case cancel
}

enum Mode {
    case new
    case edit
}

enum FocusedField:Hashable {
    case title, description, pathImage, author
}


struct BookEditView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: BookViewModel
    @FocusState var focus:FocusedField?
    @State var presentActionSheet = false
    @EnvironmentObject var localization: LocalizationService
    
    var completionHandler: ((Result<Action, Error>) -> Void)?
    var presentEditView = ""
    var cancelButton: some View {
        Button(Localized.BookEditView.cancel.localized()) {
            handleCancelTapped()
        }
    }
    
    
    var saveButton: some View {
        Button(viewModel.mode == .new ? Localized.BookEditView.done.localized() : Localized.BookEditView.save.localized()) {
            handleDoneTapped()
        }
        .disabled(!viewModel.modified)
    }
    
   
    init(book:BookCloud = BookCloud(title: "", author: "", description: "", urlImage: ""), mode:Mode = .new, managerCRUDS: CRUDSManager, presentEditView:String, completionHandler: ((Result<Action, Error>) -> Void)? = nil) {
        print("init BookEditView")
        _viewModel = StateObject(wrappedValue: BookViewModel(book: book, mode: mode, managerCRUDS: managerCRUDS))
        self.presentEditView = presentEditView
        self.completionHandler = completionHandler
    }
    

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text(Localized.BookEditView.bookSection.localized())) {
                        customTextField(Localized.BookEditView.title.localized(), text: $viewModel.book.title, field: .title, focus: $focus)
                        customTextField(Localized.BookEditView.description.localized(), text: $viewModel.book.description, field: .description, focus: $focus)
                        customTextField(Localized.BookEditView.pathImage.localized(), text: $viewModel.book.urlImage, field: .pathImage, focus: $focus)
                    }
                    Section(header: Text(Localized.BookEditView.authorSection.localized())) {
                        customTextField(Localized.BookEditView.author.localized(), text: $viewModel.book.author, field: .author, focus: $focus)
                    }
                    
                    if viewModel.mode == .edit {
                        Button(Localized.BookEditView.deleteBook.localized(), role: .destructive) {
                            self.presentActionSheet.toggle()
                        }
                    }
                }
                .navigationTitle(viewModel.mode == .new ? Localized.BookEditView.newBook.localized() : viewModel.book.title)
                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
                .toolbar{
                    ToolbarItem(placement: .topBarTrailing) {
                        saveButton
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        cancelButton
                    }
                }
                .confirmationDialog(Localized.BookEditView.confirmationDialog.localized(), isPresented: $presentActionSheet) {
                    Button(Localized.BookEditView.deleteBook.localized(), role: .destructive) {
                        handleDeleteTapped()
                    }
                    Button(Localized.BookEditView.cancel.localized(), role: .cancel) {}
                }
            }
        }
        .onAppear {
            print("onAppear BookEditView")
        }
    }
    
    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
        ZStack(alignment: .leading) {
            TextField(title, text: text)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused(focus, equals: field)
                .padding([.leading, .trailing], 30)
                .tint(.pink)
                .foregroundStyle(.secondary)
                .onSubmit {
                    withAnimation {
                        switch field {
                        case .title:
                            focus.wrappedValue = .description
                        case .description:
                            focus.wrappedValue = .pathImage
                        case .pathImage:
                            focus.wrappedValue = .author
                        case .author:
                            focus.wrappedValue = nil
                        }
                    }
                }
            Button(action: {
                print("Did tap Image")
            }, label: {
                Image(systemName: "swift")
                    .foregroundStyle(AppColors.pink)
                    .frame(width: 30, height: 30)
                    .padding(.leading, -10)
            })
        }
    }
    
    private func handleCancelTapped() {
        self.completionHandler?(.success((.cancel)))
        dismiss()
    }
    
    private func handleDoneTapped() {
        viewModel.updateOrAddBook(forView: presentEditView, operationDescription: Localized.DescriptionOfOperationError.addingOrChangingBook)
        // Передаем ассоциированный параметр с текущей книгой
        self.completionHandler?(.success(.done(viewModel.book)))
        dismiss()
    }
    
    private func handleDeleteTapped() {
        viewModel.removeBook(forView: presentEditView, operationDescription: Localized.DescriptionOfOperationError.deletingBook)
        self.completionHandler?(.success((.delete)))
        dismiss()
    }
}


// MARK: - Cancel HomeBookDataStore


//enum Action {
//    case done
//    case delete
//    case cancel
//}
//
//enum Mode {
//    case new
//    case edit
//}
//
//enum FocusedField:Hashable {
//    case title, description, pathImage, author
//}
//
//
//struct BookEditView: View {
//    
//    @Environment(\.dismiss) private var dismiss
//    @StateObject var viewModel: BookViewModel
//    @FocusState var focus:FocusedField?
//    @State var presentActionSheet = false
//    @EnvironmentObject var localization: LocalizationService
//    
//    var completionHandler: ((Result<Action, Error>) -> Void)?
//    var presentEditView = ""
//    var cancelButton: some View {
//        Button(Localized.BookEditView.cancel.localized()) {
//            handleCancelTapped()
//        }
//    }
//    
//    
//    var saveButton: some View {
//        Button(viewModel.mode == .new ? Localized.BookEditView.done.localized() : Localized.BookEditView.save.localized()) {
//            handleDoneTapped()
//        }
//        .disabled(!viewModel.modified)
//    }
//    
//   
//    init(book:BookCloud = BookCloud(title: "", author: "", description: "", urlImage: ""), mode:Mode = .new, managerCRUDS: CRUDSManager, presentEditView:String, completionHandler: ((Result<Action, Error>) -> Void)? = nil) {
//        print("init BookEditView")
//        _viewModel = StateObject(wrappedValue: BookViewModel(book: book, mode: mode, managerCRUDS: managerCRUDS))
//        self.presentEditView = presentEditView
//        self.completionHandler = completionHandler
//    }
//    
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Form {
//                    Section(header: Text(Localized.BookEditView.bookSection.localized())) {
//                        customTextField(Localized.BookEditView.title.localized(), text: $viewModel.book.title, field: .title, focus: $focus)
//                        customTextField(Localized.BookEditView.description.localized(), text: $viewModel.book.description, field: .description, focus: $focus)
//                        customTextField(Localized.BookEditView.pathImage.localized(), text: $viewModel.book.urlImage, field: .pathImage, focus: $focus)
//                    }
//                    Section(header: Text(Localized.BookEditView.authorSection.localized())) {
//                        customTextField(Localized.BookEditView.author.localized(), text: $viewModel.book.author, field: .author, focus: $focus)
//                    }
//                    
//                    if viewModel.mode == .edit {
//                        Button(Localized.BookEditView.deleteBook.localized(), role: .destructive) {
//                            self.presentActionSheet.toggle()
//                        }
//                    }
//                }
//                .navigationTitle(viewModel.mode == .new ? Localized.BookEditView.newBook.localized() : viewModel.book.title)
//                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
//                .toolbar{
//                    ToolbarItem(placement: .topBarTrailing) {
//                        saveButton
//                    }
//                    ToolbarItem(placement: .topBarLeading) {
//                        cancelButton
//                    }
//                }
//                .confirmationDialog(Localized.BookEditView.confirmationDialog.localized(), isPresented: $presentActionSheet) {
//                    Button(Localized.BookEditView.deleteBook.localized(), role: .destructive) {
//                        handleDeleteTapped()
//                    }
//                    Button(Localized.BookEditView.cancel.localized(), role: .cancel) {}
//                }
//            }
//        }
//        .onAppear {
//            print("onAppear BookEditView")
//        }
//    }
//    
//    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
//        ZStack(alignment: .leading) {
//            TextField(title, text: text)
//                .keyboardType(.default)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .focused(focus, equals: field)
//                .padding([.leading, .trailing], 30)
//                .tint(.pink)
//                .foregroundStyle(.secondary)
//                .onSubmit {
//                    withAnimation {
//                        switch field {
//                        case .title:
//                            focus.wrappedValue = .description
//                        case .description:
//                            focus.wrappedValue = .pathImage
//                        case .pathImage:
//                            focus.wrappedValue = .author
//                        case .author:
//                            focus.wrappedValue = nil
//                        }
//                    }
//                }
//            Button(action: {
//                print("Did tap Image")
//            }, label: {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                    .padding(.leading, -10)
//            })
//        }
//    }
//    
//    private func handleCancelTapped() {
//        self.completionHandler?(.success((.cancel)))
//        dismiss()
//    }
//    
//    private func handleDoneTapped() {
//        viewModel.updateOrAddBook(forView: presentEditView, operationDescription: Localized.DescriptionOfOperationError.addingOrChangingBook)
//        self.completionHandler?(.success((.done)))
//        dismiss()
//    }
//    
//    private func handleDeleteTapped() {
//        viewModel.removeBook(forView: presentEditView, operationDescription: Localized.DescriptionOfOperationError.deletingBook)
//        self.completionHandler?(.success((.delete)))
//        dismiss()
//    }
//}

// MARK: - before pattern Coordinator

//import SwiftUI
//
//enum Action {
//    case done
//    case delete
//    case cancel
//}
//
//enum Mode {
//    case new
//    case edit
//}
//
//enum FocusedField:Hashable {
//    case title, description, pathImage, author
//}
//
//
//struct BookEditView: View {
//    
//    @Environment(\.dismiss) private var dismiss
//    @StateObject var viewModel: BookViewModel
//    @FocusState var focus:FocusedField?
//    @State var presentActionSheet = false
//    
//    var completionHandler: ((Result<(Action, BookCloud), Error>) -> Void)?
//    var presentEditView = ""
//    var cancelButton: some View {
//        Button("Cancel") {
//            handleCancelTapped()
//        }
//    }
//    
//    
//    var saveButton: some View {
//        Button(viewModel.mode == .new ? "Done" : "Save") {
//            handleDoneTapped()
//        }
//        .disabled(!viewModel.modified)
//    }
//    
//    init(book:BookCloud = BookCloud(title: "", author: "", description: "", pathImage: ""), mode:Mode = .new, managerCRUDS: CRUDSManager, presentEditView:String, completionHandler: ((Result<(Action, BookCloud), Error>) -> Void)? = nil) {
//        print("init BookEditView")
//        _viewModel = StateObject(wrappedValue: BookViewModel(book: book, mode: mode, managerCRUDS: managerCRUDS))
//        self.presentEditView = presentEditView
//        self.completionHandler = completionHandler
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Form {
//                    Section(header: Text("Book")) {
//                        customTextField("Title", text: $viewModel.book.title, field: .title, focus: $focus)
//                        customTextField("Description", text: $viewModel.book.description, field: .description, focus: $focus)
//                        customTextField("PathImage", text: $viewModel.book.pathImage, field: .pathImage, focus: $focus)
//                    }
//                    Section(header: Text("Author")) {
//                        customTextField("Author", text: $viewModel.book.author, field: .author, focus: $focus)
//                    }
//                    
//                    if viewModel.mode == .edit {
//                        Button("Delete book", role: .destructive) {
//                            self.presentActionSheet.toggle()
//                        }
//                    }
//                }
//                .navigationTitle(viewModel.mode == .new ? "New book" : viewModel.book.title)
//                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
//                .toolbar{
//                    ToolbarItem(placement: .topBarTrailing) {
//                        saveButton
//                    }
//                    ToolbarItem(placement: .topBarLeading) {
//                        cancelButton
//                    }
//                }
//                .confirmationDialog("Are you sure?", isPresented: $presentActionSheet) {
//                    Button("Delete book", role: .destructive) {
//                        handleDeleteTapped()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//            }
//        }
//        .onAppear {
//            print("onAppear BookEditView")
//        }
//    }
//    
//    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
//        ZStack(alignment: .leading) {
//            TextField(title, text: text)
//                .keyboardType(.default)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .focused(focus, equals: field)
//                .padding([.leading, .trailing], 30)
//                .tint(.pink)
//                .foregroundStyle(.secondary)
//                .onSubmit {
//                    withAnimation {
//                        switch field {
//                        case .title:
//                            focus.wrappedValue = .description
//                        case .description:
//                            focus.wrappedValue = .pathImage
//                        case .pathImage:
//                            focus.wrappedValue = .author
//                        case .author:
//                            focus.wrappedValue = nil
//                        }
//                    }
//                }
//            Button(action: {
//                print("Did tap Image")
//            }, label: {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                    .padding(.leading, -10)
//            })
//        }
//    }
//    
//    private func handleCancelTapped() {
//        self.completionHandler?(.success((.cancel, viewModel.book)))
//        dismiss()
//    }
//    
//    private func handleDoneTapped() {
//        viewModel.updateOrAddBook(forView: presentEditView, operationDescription: "Error adding or change book")
//        self.completionHandler?(.success((.done, viewModel.book)))
//        dismiss()
//    }
//    
//    private func handleDeleteTapped() {
//        viewModel.removeBook(forView: presentEditView, operationDescription: "Error deleting book")
//        self.completionHandler?(.success((.delete, viewModel.book)))
//        dismiss()
//    }
//}









//#Preview {
//    BookEditView(viewModel:  BookViewModel())
//}

// MARK: - .environmentObject(crudManager)  -

//import SwiftUI
//
//enum Action {
//    case done
//    case delete
//    case cancel
//}
//
//enum Mode {
//    case new
//    case edit
//}
//
//enum FocusedField:Hashable {
//    case title, description, pathImage, author
//}
//
//
//struct BookEditView: View {
//    
//    @Environment(\.dismiss) private var dismiss
//    @StateObject var viewModel: BookViewModel
//    @FocusState var focus:FocusedField?
//    @State var presentActionSheet = false
//    
//    var completionHandler: ((Result<Action, Error>) -> Void)?
////    var mode: Mode = .new
//    
//    var cancelButton: some View {
//        Button("Cancel") {
//            handleCancelTapped()
//        }
//    }
//    
//    
//    var saveButton: some View {
//        Button(viewModel.mode == .new ? "Done" : "Save") {
//            handleDoneTapped()
//        }
//        .disabled(!viewModel.modified)
//    }
//    
//    init() {
//        print("init BookEditView")
//        _viewModel = StateObject(wrappedValue: BookViewModel(managerCRUDS: CRUDSManager(authService: AuthService(), errorHandler: SharedErrorHandler(), databaseService: FirestoreDatabaseCRUDService())))
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Form {
//                    Section(header: Text("Book")) {
//                        customTextField("Title", text: $viewModel.book.title, field: .title, focus: $focus)
//                        customTextField("Description", text: $viewModel.book.description, field: .description, focus: $focus)
//                        customTextField("PathImage", text: $viewModel.book.pathImage, field: .pathImage, focus: $focus)
//                    }
//                    Section(header: Text("Author")) {
//                        customTextField("Author", text: $viewModel.book.author, field: .author, focus: $focus)
//                    }
//                    
//                    if viewModel.mode == .edit {
//                        Button("Delete book", role: .destructive) {
//                            self.presentActionSheet.toggle()
//                        }
//                    }
//                }
//                .navigationTitle(viewModel.mode == .new ? "New book" : viewModel.book.title)
//                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
//                .toolbar{
//                    ToolbarItem(placement: .topBarTrailing) {
//                        saveButton
//                    }
//                    ToolbarItem(placement: .topBarLeading) {
//                        cancelButton
//                    }
//                }
//                .confirmationDialog("Are you sure?", isPresented: $presentActionSheet) {
//                    Button("Delete book", role: .destructive) {
//                        handleDeleteTapped()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//            }
//        }
//    }
//    
//    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
//        ZStack(alignment: .leading) {
//            TextField(title, text: text)
//                .keyboardType(.default)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .focused(focus, equals: field)
//                .padding([.leading, .trailing], 30)
//                .tint(.pink)
//                .foregroundStyle(.secondary)
//                .onSubmit {
//                    withAnimation {
//                        switch field {
//                        case .title:
//                            focus.wrappedValue = .description
//                        case .description:
//                            focus.wrappedValue = .pathImage
//                        case .pathImage:
//                            focus.wrappedValue = .author
//                        case .author:
//                            focus.wrappedValue = nil
//                        }
//                    }
//                }
//            Button(action: {
//                print("Did tap Image")
//            }, label: {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                    .padding(.leading, -10)
//            })
//        }
//    }
//    
//    private func handleCancelTapped() {
//        self.completionHandler?(.success(.cancel))
//        dismiss()
//    }
//    
//    private func handleDoneTapped() {
//        viewModel.updateOrAddBook(forView: "HomeView", operationDescription: "Error adding or change book")
//        self.completionHandler?(.success(.done))
//        dismiss()
//    }
//    
//    private func handleDeleteTapped() {
//        viewModel.removeBook(forView: "HomeView", operationDescription: "Error deleting book")
//        self.completionHandler?(.success(.delete))
//        dismiss()
//    }
//}


// MARK: - before correct initialization of the state -

//import SwiftUI
//
//enum Mode {
//    case new
//    case edit
//}
//
//enum FocusedField:Hashable {
//    case title, description, pathImage, author
//}
//
//
//struct BookEditView: View {
//    
//    @Environment(\.dismiss) private var dismiss
//    @StateObject var viewModel: BookViewModel
//    @FocusState var focus:FocusedField?
//    @State var presentActionSheet = false
//    
////    var mode: Mode = .new
//    
//    var cancelButton: some View {
//        Button("Cancel") {
//            handleCancelTapped()
//        }
//    }
//    
//    
//    var saveButton: some View {
//        Button(viewModel.mode == .new ? "Done" : "Save") {
//            handleDoneTapped()
//        }
//        .disabled(!viewModel.modified)
//    }
//    
//    init(viewModel:BookViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Form {
//                    Section(header: Text("Book")) {
//                        customTextField("Title", text: $viewModel.book.title, field: .title, focus: $focus)
//                        customTextField("Description", text: $viewModel.book.description, field: .description, focus: $focus)
//                        customTextField("PathImage", text: $viewModel.book.pathImage, field: .pathImage, focus: $focus)
//                    }
//                    Section(header: Text("Author")) {
//                        customTextField("Author", text: $viewModel.book.author, field: .author, focus: $focus)
//                    }
//                    
//                    if viewModel.mode == .edit {
//                        Button("Delete book", role: .destructive) {
//                            self.presentActionSheet.toggle()
//                        }
//                    }
//                }
//                .navigationTitle(viewModel.mode == .new ? "New book" : viewModel.book.title)
//                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
//                .toolbar{
//                    ToolbarItem(placement: .topBarTrailing) {
//                        saveButton
//                    }
//                    ToolbarItem(placement: .topBarLeading) {
//                        cancelButton
//                    }
//                }
//                .confirmationDialog("Are you sure?", isPresented: $presentActionSheet) {
//                    Button("Delete book", role: .destructive) {
//                        handleDeleteTapped()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//            }
//        }
//    }
//    
//    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
//        ZStack(alignment: .leading) {
//            TextField(title, text: text)
//                .keyboardType(.default)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .focused(focus, equals: field)
//                .padding([.leading, .trailing], 30)
//                .tint(.pink)
//                .foregroundStyle(.secondary)
//                .onSubmit {
//                    withAnimation {
//                        switch field {
//                        case .title:
//                            focus.wrappedValue = .description
//                        case .description:
//                            focus.wrappedValue = .pathImage
//                        case .pathImage:
//                            focus.wrappedValue = .author
//                        case .author:
//                            focus.wrappedValue = nil
//                        }
//                    }
//                }
//            Button(action: {
//                print("Did tap Image")
//            }, label: {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                    .padding(.leading, -10)
//            })
//        }
//    }
//    
//    private func handleCancelTapped() {
//        dismiss()
//    }
//    
//    private func handleDoneTapped() {
//        viewModel.updateOrAddBook(forView: "HomeView", operationDescription: "Error adding or change book")
//        dismiss()
//    }
//    
//    private func handleDeleteTapped() {
//        viewModel.removeBook(forView: "HomeView", operationDescription: "Error deleting book")
//        dismiss()
//    }
//    
//}
//



// MARK: - Trash


//                Section {
//                    customTextField("Title", text: $viewModel.book.title)
//                        .focused($focus, equals: .title)
//                    customTextField("Description", text: $viewModel.book.description)
//                        .focused($focus, equals: .description)
//                    customTextField("PathImage", text: $viewModel.book.pathImage)
//                        .focused($focus, equals: .pathImage)
//                } header: {
//                    Text("Book")
//                }
//
//                Section {
//                    customTextField("Author", text: $viewModel.book.author)
//                        .focused($focus, equals: .author)
//                } header: {
//                    Text("Author")
//                }

//    private func customTextField(_ title: String, text: Binding<String>) -> some View {
//        TextField(title, text: text)
//            .keyboardType(.default)
//            .autocapitalization(.none)
//            .disableAutocorrection(true)
//            .onSubmit {
//                switch focus {
//                case .title:
//                    focus = .description
//                case .description:
//                    focus = .pathImage
//                case .pathImage:
//                    focus = .author
//                case .author:
//                    focus = nil
//                case nil:
//                    break
//                }
//            }
//    }



//            ZStack {
//                Color.clear // Скрытое представление для перехвата нажатий
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        print(".onTapGesture")
//                        focus = nil
//                    }}





// MARK: - code with error handler





//import SwiftUI
//
//enum Mode {
//    case new
//    case edit
//}
//
//enum FocusedField:Hashable {
//    case title, description, pathImage, author
//}
//
//
//struct BookEditView: View {
//
//    @Environment(\.dismiss) private var dismiss
//    @StateObject var viewModel: BookViewModel
//    @FocusState var focus:FocusedField?
//
//    @State private var showAlert = false
//    @State private var isLoading = false
////    @State private var alertMessage:String?
//    @State var presentActionSheet = false
//
////    var mode: Mode = .new
//
//    var cancelButton: some View {
//        Button("Cancel") {
//            handleCancelTapped()
//        }
//    }
//
//    /// многократное нажатие до ответа от сервера?
//    var saveButton: some View {
//        Button(viewModel.mode == .new ? "Done" : "Save") {
//            isLoading ?  {}() : handleDoneTapped()
////            handleDoneTapped()
//        }
//        .disabled(!viewModel.modified)
//    }
//
//    init(viewModel:BookViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//    }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Form {
//                    Section(header: Text("Book")) {
//                        customTextField("Title", text: $viewModel.book.title, field: .title, focus: $focus)
//                        customTextField("Description", text: $viewModel.book.description, field: .description, focus: $focus)
//                        customTextField("PathImage", text: $viewModel.book.pathImage, field: .pathImage, focus: $focus)
//                    }
//                    Section(header: Text("Author")) {
//                        customTextField("Author", text: $viewModel.book.author, field: .author, focus: $focus)
//                    }
//
//                    if viewModel.mode == .edit {
//                        Button("Delete book", role: .destructive) {
//                            self.presentActionSheet.toggle()
//                        }
//                    }
//                }
//                .navigationTitle(viewModel.mode == .new ? "New book" : viewModel.book.title)
//                .navigationBarTitleDisplayMode(viewModel.mode == .new ? .inline : .large)
//                .toolbar{
//                    ToolbarItem(placement: .topBarTrailing) {
//                        saveButton
//                    }
//                    ToolbarItem(placement: .topBarLeading) {
//                        cancelButton
//                    }
//                }
//                .alert("Error", isPresented: $showAlert, actions: {
//                    Button("Ok") {
//                        dismiss()
//                    }
//                }, message: {
//                    Text(FirebaseEnternalAppError.notSignedIn.errorDescription)
//                })
//                .confirmationDialog("Are you sure?", isPresented: $presentActionSheet) {
//                    Button("Delete book", role: .destructive) {
//                        isLoading ? {}() : handleDeleteTapped()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//                .onAppear {
//                    guard let _ = viewModel.getCurrentUserID() else {
//                        print(".onAppear CurrentUserID not null")
//                        return
//                    }
//                    showAlert = true
//                }
////                .onReceive(viewModel.$operationState) { state in
////                    switch state {
////
////                    case .idle:
////                        isLoading = false
////                    case .loading:
////                        isLoading = true
////                    case .success:
////                        isLoading = false
//////                        dismiss()
////                    case .failure(let textError):
////                        isLoading = false
////                        alertMessage = textError
////                        showAlert = true
////                    }
////                }
//
////                if isLoading {
////                    ProgressView("Loading...")
////                }
//            }
//        }
//    }
//
//    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField, focus: FocusState<FocusedField?>.Binding) -> some View {
//        ZStack(alignment: .leading) {
//            TextField(title, text: text)
//                .keyboardType(.default)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .focused(focus, equals: field)
//                .padding([.leading, .trailing], 30)
//                .tint(.pink)
//                .foregroundStyle(.secondary)
//                .onSubmit {
//                    withAnimation {
//                        switch field {
//                        case .title:
//                            focus.wrappedValue = .description
//                        case .description:
//                            focus.wrappedValue = .pathImage
//                        case .pathImage:
//                            focus.wrappedValue = .author
//                        case .author:
//                            focus.wrappedValue = nil
//                        }
//                    }
//                }
//            Button(action: {
//                print("Did tap Image")
//            }, label: {
//                Image(systemName: "swift")
//                    .foregroundStyle(.pink)
//                    .frame(width: 30, height: 30)
//                    .padding(.leading, -10)
//            })
//        }
//    }
//
//    private func handleCancelTapped() {
//        dismiss()
//    }
//
//    private func handleDoneTapped() {
//        viewModel.updateOrAddBook()
////        dismiss()
//    }
//
//    private func handleDeleteTapped() {
////        viewModel.removeBook()
//    }
//
//}
