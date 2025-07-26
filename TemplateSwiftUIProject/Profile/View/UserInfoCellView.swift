//
//  UserInfoCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.04.25.
//


// локализовать весь текст + inject AppColors

// делаем signUp смотрим логи в консоли
// подставляем signOut(активируем) вместо deleteAccount
// снова делаем signUp смотрим логи в консоли + добавляем в корзину новую запись
// теперь делаем SignIn на первый account смотрим логи в консоли
// добавляем в deleteAccount реальное удаление пользователя
// deleteAccount смотрим логи в консоли (проверяем как работает function)
// реализуем экран для ввода и сохранения личных данных пользователя в users/uid (текстовы поля name, email + iconImage)
// тестируем экран ProfileEditView 

// сейчас мы анон у которого есть личные данные в users/id/document
// когда мы signUp данные anon станут permanent
// когда мы удалим permanentUser то мы не можем сначала удалить личные данные пользователя а потом самого user, это не совсем логично!
// по этому сначала нужно удалить user account и лиш потом на стороне сервера Firebase через Firebase Functions удалить уже и данные только что удаленного users по пути users/id/

import SwiftUI


struct UserInfoCellView: View {
    @ObservedObject var viewModel: ContentAccountViewModel
    @EnvironmentObject var accountCoordinator: AccountCoordinator
    
    private var isLoading: Bool {
        viewModel.profileLoadingState == .loading
    }
    
    private var isError: Bool {
        if case .failure = viewModel.profileLoadingState {
            return true
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Аватарка
            avatarView
               
            // Текстовые данные
            VStack(alignment: .leading, spacing: 4) {
                if let name = displayName {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(displayEmail)
                    .font(.subheadline)
                    .foregroundColor(AppColors.gray)
            }
            
            Spacer()
            
            // Индикатор состояния
            stateIndicatorView
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isLoading else { return }
            accountCoordinator.navigateTo(page: .userInfo)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var avatarView: some View {
        if isLoading {
            ProgressView()
                .frame(width: 60, height: 60)
        } else if let url = viewModel.userProfile?.photoURL, !viewModel.isUserAnonymous {
            WebImageView(
                url: url,
                placeholderColor: .gray,
                displayStyle: .fixedFrame(width: 60, height: 60)
            )
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
        }
    }
    
    
    @ViewBuilder
    private var stateIndicatorView: some View {
        if isError {
            Button(action: viewModel.retryUserProfile) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.gray)
        }
    }

    
    // MARK: - Computed Properties
    
    private var displayName: String? {
        if viewModel.isUserAnonymous {
            return "Гость"
        }
        if case .failure = viewModel.profileLoadingState {
            return nil // В случае ошибки скроем displayName
        }
        
        if case .loading = viewModel.profileLoadingState {
            return nil // В случае первой или retry загрузки
        }
        return viewModel.userProfile?.name ?? "Без имени"
    }
    
    private var displayEmail: String {  // Делаем опциональным
        if viewModel.isUserAnonymous {
            return "Анонимный режим"
        }
        if case .failure = viewModel.profileLoadingState {
            return "Ошибка загрузки профиля"
        }
        if viewModel.profileLoadingState == .loading {
            return "Загрузка..."
        }
        return viewModel.userProfile?.email ?? "Email не указан"
    }
}




//    .foregroundColor(isError ? .red : .primary)

//            VStack(alignment: .leading, spacing: 4) {
//                Text(displayName)
//                    .font(.headline)
//
//                Text(displayEmail)
//                    .font(.subheadline)
//                    .foregroundColor(AppColors.gray)
//            }

//    private var displayName: String {
//        if viewModel.isUserAnonymous {
//            return "Гость"
//        }
//        return viewModel.userProfile?.name ?? "Без имени"
//    }
//
//    private var displayEmail: String {
//        if viewModel.isUserAnonymous {
//            return "Анонимный режим"
//        }
//        return viewModel.userProfile?.email ?? "Email не указан"
//    }

//    @ViewBuilder
//    private var stateIndicatorView: some View {
//        if isLoading {
//            ProgressView()
//                .frame(width: 24, height: 24)
//        } else if isError {
//            Button(action: {
//                viewModel.retryUserProfile()
//            }) {
//                Image(systemName: "arrow.clockwise.circle.fill")
//                    .resizable()
//                    .frame(width: 24, height: 24)
//                    .foregroundColor(.red)
//            }
//            .buttonStyle(.plain)
//        } else {
//            Image(systemName: "chevron.right")
//                .foregroundColor(AppColors.gray)
//        }
//    }


//struct UserInfoCellView: View {
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//    @ObservedObject var viewModel: ContentAccountViewModel // Передаем VM
//    
//    private var displayName: String {
//        if viewModel.isUserAnonymous {
//            return "Гость"
//        }
//        return viewModel.userProfile?.name ?? "Без имени"
//    }
//    
//    private var displayEmail: String {
//        if viewModel.isUserAnonymous {
//            return "Анонимный режим"
//        }
//        return viewModel.userProfile?.email ?? "Email не указан"
//    }
//    
//    private var photoURL: URL? {
//        viewModel.isUserAnonymous ?
//        nil : viewModel.userProfile?.photoURL
//    }
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            // Аватарка
//            if let url = photoURL {
//                WebImageView(
//                    url: url,
//                    placeholderColor: .gray,
//                    displayStyle: .fixedFrame(width: 60, height: 60)
//                )
//                .clipShape(Circle())
//            } else {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .frame(width: 60, height: 60)
//                    .foregroundColor(.gray)
//            }
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(displayName)
//                    .font(.headline)
//                
//                Text(displayEmail)
//                    .font(.subheadline)
//                    .foregroundColor(AppColors.gray)
//            }
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .foregroundColor(AppColors.gray)
//        }
//        .padding(.vertical, 8)
//        .contentShape(Rectangle())
//        .onTapGesture {
//            accountCoordinator.navigateTo(page: .userInfo)
//        }
//    }
//}


//struct UserInfoCellView: View {
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//
//    var body: some View {
//        HStack(spacing: 16) {
//            WebImageView(
//                url: URL(string: "https://firebasestorage.googleapis.com/v0/b/templateswiftui.appspot.com/o/GalleryShop%2FBooks-A-Million.jpeg?alt=media&token=12c59f38-9e1f-42ff-9c81-3074f9f229bf"),
//                placeholderColor: .gray,
//                displayStyle: .fixedFrame(width: 60, height: 60)
//            )
//            .clipShape(Circle())
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Константин")
//                    .font(.headline)
//                    .lineLimit(1)
//                    .minimumScaleFactor(0.8)
//
//                Text("example@example.com")
//                    .font(.subheadline)
//                    .foregroundColor(AppColors.gray)
//                    .lineLimit(1)
//                    .minimumScaleFactor(0.8)
//            }
//            Spacer()
//            // Chevron справа
//            Image(systemName: "chevron.right")
//                .foregroundColor(AppColors.gray)
//                .imageScale(.small)
//        }
//        .padding(.vertical, 8)
//        .contentShape(Rectangle())
//        .onTapGesture {
//            print("onTapGesture - UserInfoCellView")
//            accountCoordinator.navigateTo(page: .userInfo)
//        }
//    }
//}


