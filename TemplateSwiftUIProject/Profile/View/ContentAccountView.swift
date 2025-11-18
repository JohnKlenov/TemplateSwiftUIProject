//
//  ContentAccountView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//




// MARK: - delete account

// delete account API in AuthorizationManager
// inject AuthorizationManager in ContentAccountView use wrapping ContentAccountViewInjected
// создаем новый case для deleteAccountButoon в AccountRow и в это View передаем viewModel ContentAccountView для того что бы при нажатии на эту кнопку дернуть API AuthorizationManager deleteAccount 
import SwiftUI

// MARK: - Основной экран профиля (AccountView)

enum AccountRow: Identifiable {
    case toggle(title: String, binding: Binding<Bool>)
    case navigation(title: String, destination: AccountFlow)
    case deleteAccount(AuthorizationManager.State)

    var id: String {
        switch self {
        case .toggle(let title, _):
            return title + "_toggle"
        case .navigation(let title, _):
            return title + "_nav"
        case .deleteAccount: return "delete_account"
        }
    }
}

extension AccountRow {
    @ViewBuilder
    var rowView: some View {
        switch self {
        case .toggle(let title, let binding):
            ToggleCellView(title: title, isOn: binding)
        case .navigation(let title, let destination):
            NavigationCellView(title: title, destination: destination)
        case .deleteAccount(let state):
            DeleteAccountCellView(accountDeletionState: state)
        }
    }
}

struct ContentAccountView: View {
    @ObservedObject var viewModel: ContentAccountViewModel
    @State private var notificationsEnabled: Bool = true
    @State private var darkModeEnabled: Bool = false
    
    // Формируем массив строк, где каждая строка описывает конкретный тип ячейки
    var rows: [AccountRow] {
        var rows: [AccountRow] = [
            .toggle(title: "Notification", binding: $notificationsEnabled),
            .navigation(title: "Change language", destination: .language),
            .toggle(title: "Dark mode", binding: $darkModeEnabled),
            .navigation(title: "About Us", destination: .aboutUs),
            .navigation(title: "Create Account", destination: .createAccount)
        ]
        ///if viewModel.shouldShowDeleteButton
        if !viewModel.isUserAnonymous {
            rows.append(.deleteAccount(viewModel.accountDeletionState))
        }
        
        return rows
    }
    
    var body: some View {
        let _ = Self._printChanges()
        List {
            UserInfoCellView(viewModel: viewModel)
            Section {
                ForEach(rows) { row in
                    if case .deleteAccount = row {
                        row.rowView
                            .onTapGesture {
                                if !viewModel.isAuthOperationInProgress {
                                    viewModel.showDeleteConfirmation = true
                                }
                            }
                    } else {
                        row.rowView
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button("Delete Account", role: .destructive) {
                viewModel.deleteAccount()
            }
            .disabled(viewModel.isAuthOperationInProgress)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}





// MARK: - before Local states

//import SwiftUI
//
//// MARK: - Основной экран профиля (AccountView)
//
//enum AccountRow: Identifiable {
//    case toggle(title: String, binding: Binding<Bool>)
//    case navigation(title: String, destination: AccountFlow)
//    case deleteAccount(AuthorizationManager.State)
//
//    var id: String {
//        switch self {
//        case .toggle(let title, _):
//            return title + "_toggle"
//        case .navigation(let title, _):
//            return title + "_nav"
//        case .deleteAccount: return "delete_account"
//        }
//    }
//}
//
//extension AccountRow {
//    @ViewBuilder
//    var rowView: some View {
//        switch self {
//        case .toggle(let title, let binding):
//            ToggleCellView(title: title, isOn: binding)
//        case .navigation(let title, let destination):
//            NavigationCellView(title: title, destination: destination)
//        case .deleteAccount(let state):
//            DeleteAccountCellView(accountDeletionState: state)
//        }
//    }
//}
//
//struct ContentAccountView: View {
//    @ObservedObject var viewModel: ContentAccountViewModel
//    @State private var notificationsEnabled: Bool = true
//    @State private var darkModeEnabled: Bool = false
//    
//    // Формируем массив строк, где каждая строка описывает конкретный тип ячейки
//    var rows: [AccountRow] {
//        var rows: [AccountRow] = [
//            .toggle(title: "Notification", binding: $notificationsEnabled),
//            .navigation(title: "Change language", destination: .language),
//            .toggle(title: "Dark mode", binding: $darkModeEnabled),
//            .navigation(title: "About Us", destination: .aboutUs),
//            .navigation(title: "Create Account", destination: .createAccount)
//        ]
//        ///if viewModel.shouldShowDeleteButton
//        if !viewModel.isUserAnonymous {
//            rows.append(.deleteAccount(viewModel.accountDeletionState))
//        }
//        
//        return rows
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        List {
//            UserInfoCellView(viewModel: viewModel)
//            Section {
//                ForEach(rows) { row in
//                    if case .deleteAccount = row {
//                        row.rowView
//                            .onTapGesture {
                                
//                                if viewModel.accountDeletionState != .loading {
//                                    viewModel.showDeleteConfirmation = true
//                                }
//                            }
//                    } else {
//                        row.rowView
//                    }
//                }
//            }
//        }
//        .listStyle(InsetGroupedListStyle())
//        .navigationTitle("Account")
//        .navigationBarTitleDisplayMode(.inline)
//        .confirmationDialog(
//            "Delete Account",
//            isPresented: $viewModel.showDeleteConfirmation
//        ) {
//            Button("Delete Account", role: .destructive) {
//                viewModel.deleteAccount()
//            }
//            .disabled(viewModel.accountDeletionState == .loading)
//            Button("Cancel", role: .cancel) {}
//        } message: {
//            Text("Are you sure you want to delete your account? This action cannot be undone.")
//        }
//    }
//}







//    var rows: [AccountRow] {
//        [
//            .toggle(title: "Notification", binding: $notificationsEnabled),
//            .navigation(title: "Change language", destination: .language),
//            .toggle(title: "Dark mode", binding: $darkModeEnabled),
//            .navigation(title: "About Us", destination: .aboutUs),
//            .navigation(title: "Create Account", destination: .createAccount),
//            .deleteAccount(viewModel.accountDeletionState)
//        ]
//    }


//        List {
//            UserInfoCellView()
//            Section {
//                ForEach(rows) { row in
//                    if case .deleteAccount = row {
//                        row.rowView
//                            .contentShape(Rectangle())
//                            .onTapGesture {
//                                viewModel.showDeleteConfirmation = true
//                            }
//                    } else {
//                        row.rowView
//                    }
//                }
//            }
//        }




// MARK: - old ProfileView
//struct ProfileView: View {
//
//    // Получаем сервис локализации через EnvironmentObject
//    @EnvironmentObject var localization: LocalizationService
//
//    // Список поддерживаемых языков
//    let supportedLanguages = ["en", "ru", "es"]
//
//    var body: some View {
//        List(supportedLanguages, id: \.self) { code in
//            Button(action: {
//                // Устанавливаем выбранный язык
//                localization.setLanguage(code)
//            }) {
//                HStack {
//                    // Отображаем название языка
//                    Text(languageName(for: code))
//                    Spacer()
//                    // Показываем галочку для текущего языка
//                    if code == localization.currentLanguage {
//                        Image(systemName: "checkmark")
//                    }
//                }
//            }
//        }
//        .onAppear{
//            print("GalleryView onAppear")
//        }
//    }
//
//    // Метод для получения названия языка
//    private func languageName(for code: String) -> String {
//        Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
//    }
//}


// MARK: - Модели

//struct Item: Identifiable {
//    let id = UUID()
//    let title: String
//    // Добавьте нужные свойства для каждой ячейки
//}
//
//struct SectionModel: Identifiable {
//    let id = UUID()
//    let section: String   // "Malls", "Shops", "PopularProducts"
//    let items: [Item]
//}

// MARK: - Главный View

//struct ProfileView: View {
//    let data: [SectionModel]
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                ForEach(data) { section in
//                    switch section.section {
//                    case "Malls":
//                        MallsSectionView(items: section.items,
//                                         headerTitle: "Торговые Центры")
//                    case "Shops":
//                        ShopsSectionView(items: section.items,
//                                         headerTitle: "Магазины")
//                    case "PopularProducts":
//                        PopularProductsSectionView(items: section.items,
//                                                   headerTitle: "Популярные товары")
//                    default:
//                        // Если тип секции не распознан, по умолчанию показываем malls
//                        MallsSectionView(items: section.items,
//                                         headerTitle: "Торговые Центры")
//                    }
//                }
//            }
//            .padding(.vertical)
//        }
//    }
//}

// MARK: - Секции

///// Секция Торговых Центров (Malls)
//struct MallsSectionView: View {
//    let items: [Item]
//    let headerTitle: String
//
//    var body: some View {
//        GeometryReader { geometry in
//            let horizontalPadding: CGFloat = 16
//            let cellSpacing: CGFloat = 10
//            let cellWidth = geometry.size.width - 2 * horizontalPadding - cellSpacing
//
//            VStack(alignment: .leading, spacing: 10) {
//                // Заголовок с одинаковыми отступами, как и в другой секции
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, horizontalPadding)
//                
//                // TabView с каруселью и внутренними отступами
//                TabView {
//                    ForEach(items) { item in
//                        MallCell(item: item)
//                            .frame(width: cellWidth, height: cellWidth * 0.55)
//                            .cornerRadius(10)
//                            .padding(.horizontal, cellSpacing / 2)  // Добавляем отступы между ячейками
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                .frame(height: cellWidth * 0.55)
//                .padding(.horizontal, horizontalPadding)
//            }
//        }
//        .frame(height: 250) // Подберите это значение под ваш контент
//    }
//}


///// Секция Магазинов (Shops)
//struct ShopsSectionView: View {
//    let items: [Item]
//    let headerTitle: String
//    
//    // Вычисляем размер так, чтобы ширина ячейки была 1/5 от ширины экрана
//    let cellSize = UIScreen.main.bounds.width / 5
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal)
//            
//            // Горизонтальный ScrollView для непрерывной прокрутки
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 10) {
//                    ForEach(items) { item in
//                        ShopCell(item: item)
//                            .frame(width: cellSize, height: cellSize)
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}

///// Секция Популярных товаров (PopularProducts)
//struct PopularProductsSectionView: View {
//    let items: [Item]
//    let headerTitle: String
//    
//    // Определяем 2 колонки для grid layout
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок. Для "прилипания" заголовка можно рассмотреть Section в List или
//            // новые возможности pinnedViews (iOS 16+)
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .padding(.bottom, 10)
//    }
//}

// MARK: - Ячейки

//struct MallCell: View {
//    let item: Item
//    var body: some View {
//        ZStack {
//            // Можно заменить на изображение или другой контент
//            Rectangle()
//                .fill(Color.blue)
//            Text(item.title)
//                .font(.headline)
//                .foregroundColor(.white)
//        }
//    }
//}

//struct ShopCell: View {
//    let item: Item
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(Color.purple)
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//    }
//}

//struct ProductCell: View {
//    let item: Item
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.green)
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//        .frame(height: 100)
//    }
//}

// MARK: - Превью

//ProfileView(data: [SectionModel(section: "Malls", items: [
//   Item(title: "Торговый центр 1"),
//   Item(title: "Торговый центр 2"),
//   Item(title: "Торговый центр 3")
//]), SectionModel(section: "Shops", items: [
//   Item(title: "Магазин 1"),
//   Item(title: "Магазин 2"),
//   Item(title: "Магазин 3"),
//   Item(title: "Магазин 4"),
//   Item(title: "Магазин 5")
//]), SectionModel(section: "PopularProducts", items: [
//   Item(title: "Товар 1"),
//   Item(title: "Товар 2"),
//   Item(title: "Товар 3"),
//   Item(title: "Товар 4")
//])])

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let malls = SectionModel(section: "Malls", items: [
//            Item(title: "Торговый центр 1"),
//            Item(title: "Торговый центр 2"),
//            Item(title: "Торговый центр 3")
//        ])
//        
//        let shops = SectionModel(section: "Shops", items: [
//            Item(title: "Магазин 1"),
//            Item(title: "Магазин 2"),
//            Item(title: "Магазин 3"),
//            Item(title: "Магазин 4"),
//            Item(title: "Магазин 5")
//        ])
//        
//        let popularProducts = SectionModel(section: "PopularProducts", items: [
//            Item(title: "Товар 1"),
//            Item(title: "Товар 2"),
//            Item(title: "Товар 3"),
//            Item(title: "Товар 4")
//        ])
//        
//        ProfileView(data: [malls, shops, popularProducts])
//    }
//}


//struct ProfileView: View {
//    
//    @State private var searchText = ""
//    let items = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape"]
//    var filteredItems: [String] {
//        if searchText.isEmpty {
//            return items
//        } else {
//            return items.filter { $0.contains(searchText) }
//        }
//    }
//    
//    init() {
//        print("ProfileView init")
//    }
//    var body: some View {
//        
//        NavigationStack {
//            List(filteredItems, id: \.self) { item in
//                Text(item)
//            }
//            .navigationTitle("Fruits")
//            .searchable(text: $searchText, prompt: "Search fruits")
//        }
//    }
//}

//#Preview {
//    ProfileView()
//}
