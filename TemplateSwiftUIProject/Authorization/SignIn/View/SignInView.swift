//
//  SignInView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.05.25.
//

//check box
///Функция "Remember Me" особенно полезна в тех приложениях, где регистрация или вход в систему обязательны с первого запуска. Если при первом запуске пользователь вынужден регистрироваться или вводить данные для входа, то наличие флажка "Remember Me" позволяет сохранить его сессию. При последующих запусках приложение проверяет, что пользователь уже авторизован (то есть активна сессия, и флажок включён), и автоматически открывает приложение без запроса логина и пароля.
///Firebase Auth по умолчанию сохраняет сессию между перезапусками приложения, если пользователь не вышел явно. То есть, когда вы используете слушатель состояния аутентификации (например, через Auth.auth().addStateDidChangeListener), то при запуске приложения, если пользователь был ранее авторизован и не вышел, объект currentUser будет не равен nil и пользователь автоматически получает доступ к приложению.
///Таким образом, если ваша логика запуска проверяет состояние авторизации и автоматически переводит пользователя в залогиненное состояние, то дополнительный чекбокс «Remember Me» может оказаться избыточным.



import SwiftUI
import UIKit


// MARK: - Основное представление регистрации
struct SignInView: View {
    // Состояние для переключения видимости пароля
    @State private var isPasswordVisible = false
    @FocusState var isFieldFocus: FieldToFocusAuth?
    
    @ObservedObject var viewModel: SignInViewModel
    @EnvironmentObject var localization: LocalizationService
    @EnvironmentObject var accountCoordinator:AccountCoordinator
    
    
    var body: some View {
        let _ = Self._printChanges()
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Форма регистрации
                VStack(spacing: 15) {
                    // Поле "Email"
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Localized.SignUpView.email.localized())
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        TextField(Localized.SignUpView.emailPlaceholder.localized(), text: $viewModel.email)
                            .submitLabel(.next)
                            .focused($isFieldFocus, equals: .emailField)
                            .onSubmit { focusNextField() }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        // При тапе очищается ошибка
                            .onTapGesture {
                                viewModel.emailError = nil
                            }
                        if let error = viewModel.emailError {
                            Text(error.localized())
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Поле "Пароль" с кнопкой-переключателем "eye"
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Localized.SignUpView.password.localized())
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
                                        .submitLabel(.done)
                                        .focused($isFieldFocus, equals: .passwordField)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onSubmit { focusNextField() }
                                        .onChange(of: viewModel.password) { _ , _ in
                                            viewModel.updateValidationPassword()
                                        }
                                        .onTapGesture {
                                            viewModel.passwordError = nil
                                        }
                                } else {
                                    SecureField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
                                        .submitLabel(.done)
                                        .focused($isFieldFocus, equals: .securePasswordField)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onSubmit { focusNextField() }
                                        .onChange(of: viewModel.password) { _ , _ in
                                            viewModel.updateValidationPassword()
                                        }
                                        .onTapGesture {
                                            viewModel.passwordError = nil
                                        }
                                }
                            }
                            // Кнопка-переключатель видимости пароля
                            Button(action: {
                                isPasswordVisible.toggle()
                                isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        if let error = viewModel.passwordError {
                            Text(error.localized())
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // HStack с кнопкой "Forgot Password?"
                HStack {
                    Spacer()
                    Button(action: {
                        // Обработка нажатия "Forgot Password?"
                        print("Forgot Password tapped")
                        accountCoordinator.navigateTo(page: .forgotPassword)
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .disabled(viewModel.isAuthOperationInProgress)
                }
                .padding(.horizontal)

                // button LogIn
                Button(action: login) {
                    Group {
                        if viewModel.signInState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Login")
                                .animation(nil, value: viewModel.emailError)
                                .animation(nil, value: viewModel.passwordError)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .fontWeight(.semibold)
                .padding()
                .background(AppColors.activeColor)
                .foregroundColor(AppColors.primary)
                .cornerRadius(8)
                .padding(.horizontal)
                .disabled(viewModel.isAuthOperationInProgress)
                
                // Разделитель между регистрацией и альтернативными способами входа
                HStack {
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                    Text(Localized.SignUpView.or.localized())
                        .font(.footnote)
                        .foregroundColor(.primary)
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                }
                .padding([.horizontal, .vertical])
                
                // Блок альтернативной регистрации
                HStack(spacing: 40) {
                    // Кнопка Apple
                    Button(action: {
                        print("applelogo")
                    })  {
                        Image(systemName: "applelogo")
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(width: 60, height: 60) // ← Жёсткий размер
                            .tint(AppColors.primary)
                            .background(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                    .disabled(viewModel.isAuthOperationInProgress)
                    
                    // Кнопка Google
                    Button(action: {
                        print("googlelogo")
                    }) {
                        Image("googlelogo")
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(width: 60, height: 60) // ← Жёсткий размер
                            .background(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                    .disabled(viewModel.isAuthOperationInProgress)
                }
                .padding(.vertical, 10)
                
                // Ссылка для входа
                HStack {
                    Text("Don't have an account?")
                    Button(action: {
                        // Переход на экран регистрации
                        accountCoordinator.pop()
                    }) {
                        Text("SignUp")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("SignIn")
        }
        // Применяем жест, который срабатывает одновременно с другими
        ///первым отрабатывает simultaneousGesture затем все другие обработчики
        ///поэтому при нажатии на TextField с открытой keyboard клавиатура пропадает а затем снова открывается
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        .confirmationDialog(
            "Внимание",
            isPresented: $viewModel.showAnonymousWarning,
            titleVisibility: .visible
        ) {
            Button("Продолжить вход") {
                viewModel.confirmAnonymousSignIn()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы вошли как гость. После входа с email/password все несохранённые данные будут утеряны. Чтобы сохранить их — сначала зарегистрируйтесь.")
        }

    }
    
    private func focusNextField() {
        switch isFieldFocus {
        case .emailField:
            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
        case .securePasswordField, .passwordField:
            isFieldFocus = nil
        default:
            isFieldFocus = nil
        }
    }
    
    
    private func login() {
        
        // Обновляем валидацию полей
        viewModel.updateValidationEmail()
        viewModel.updateValidationPassword()
        
        if viewModel.isValid {
            print("Данные валидны. Начинаем регистрацию.")
            viewModel.trySignInWithWarningIfNeeded()
        } else {
            print("Некоторые поля заполнены неверно.")
        }
    }
}



// MARK: - before Local states



//import SwiftUI
//import UIKit
//
//
//// MARK: - Основное представление регистрации
//struct SignInView: View {
//    // Состояние для переключения видимости пароля
//    @State private var isPasswordVisible = false
//    @FocusState var isFieldFocus: FieldToFocusAuth?
//    
//    @ObservedObject var viewModel: SignInViewModel
//    @EnvironmentObject var localization: LocalizationService
//    @EnvironmentObject var accountCoordinator:AccountCoordinator
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        ScrollView(.vertical, showsIndicators: false) {
//            VStack(spacing: 20) {
//                // Форма регистрации
//                VStack(spacing: 15) {
//                    // Поле "Email"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(Localized.SignUpView.email.localized())
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        TextField(Localized.SignUpView.emailPlaceholder.localized(), text: $viewModel.email)
//                            .submitLabel(.next)
//                            .focused($isFieldFocus, equals: .emailField)
//                            .onSubmit { focusNextField() }
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                            .keyboardType(.emailAddress)
//                            .disableAutocorrection(true)
//                            .autocapitalization(.none)
//                        // При тапе очищается ошибка
//                            .onTapGesture {
//                                viewModel.emailError = nil
//                            }
//                        if let error = viewModel.emailError {
//                            Text(error.localized())
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                    }
//                    
//                    // Поле "Пароль" с кнопкой-переключателем "eye"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(Localized.SignUpView.password.localized())
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        HStack {
//                            Group {
//                                if isPasswordVisible {
//                                    TextField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .passwordField)
//                                        .textContentType(.password)
//                                        .autocapitalization(.none)
//                                        .disableAutocorrection(true)
//                                        .onSubmit { focusNextField() }
//                                        .onChange(of: viewModel.password) { _ , _ in
//                                            viewModel.updateValidationPassword()
//                                        }
//                                        .onTapGesture {
//                                            viewModel.passwordError = nil
//                                        }
//                                } else {
//                                    SecureField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .securePasswordField)
//                                        .textContentType(.password)
//                                        .autocapitalization(.none)
//                                        .disableAutocorrection(true)
//                                        .onSubmit { focusNextField() }
//                                        .onChange(of: viewModel.password) { _ , _ in
//                                            viewModel.updateValidationPassword()
//                                        }
//                                        .onTapGesture {
//                                            viewModel.passwordError = nil
//                                        }
//                                }
//                            }
//                            // Кнопка-переключатель видимости пароля
//                            Button(action: {
//                                isPasswordVisible.toggle()
//                                isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//                            }) {
//                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        if let error = viewModel.passwordError {
//                            Text(error.localized())
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.top, 20)
//                
//                // HStack с кнопкой "Forgot Password?"
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        guard viewModel.signInState != .loading else { return }
//                        // Обработка нажатия "Forgot Password?"
//                        print("Forgot Password tapped")
//                    }) {
//                        Text("Forgot Password?")
//                            .foregroundColor(.blue)
//                            .fontWeight(.semibold)
//                    }
//                }
//                .padding(.horizontal)
//
//                // button LogIn
//                Button(action: login) {
//                    Group {
//                        if viewModel.signInState == .loading {
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle())
//                        } else {
//                            Text("Login")
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .contentShape(Rectangle())
//                }
//                .fontWeight(.semibold)
//                .padding()
//                .background(AppColors.activeColor)
//                .foregroundColor(AppColors.primary)
//                .cornerRadius(8)
//                .padding(.horizontal)
//                .disabled(viewModel.signInState == .loading)
//                
//                // Разделитель между регистрацией и альтернативными способами входа
//                HStack {
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                    Text(Localized.SignUpView.or.localized())
//                        .font(.footnote)
//                        .foregroundColor(.primary)
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                }
//                .padding([.horizontal, .vertical])
//                
//                // Блок альтернативной регистрации
//                HStack(spacing: 40) {
//                    // Кнопка Apple
//                    Button(action: {
//                        guard viewModel.signInState != .loading else { return }
//                        print("applelogo")
//                    })  {
//                        Image(systemName: "applelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .padding()
//                            .frame(width: 60, height: 60) // ← Жёсткий размер
//                            .tint(AppColors.primary)
//                            .background(Circle().stroke(Color.gray, lineWidth: 1))
//                    }
//                    
//                    // Кнопка Google
//                    Button(action: {
//                        guard viewModel.signInState != .loading else { return }
//                        print("googlelogo")
//                    }) {
//                        Image("googlelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .padding()
//                            .frame(width: 60, height: 60) // ← Жёсткий размер
//                            .background(Circle().stroke(Color.gray, lineWidth: 1))
//                    }
//                }
//                .padding(.vertical, 10)
//                
//                // Ссылка для входа
//                HStack {
//                    Text("Don't have an account?")
//                    Button(action: {
//                        // Переход на экран регистрации
//                        guard viewModel.signInState != .loading else { return }
//                        accountCoordinator.pop()
//                    }) {
//                        Text("SignUp")
//                            .foregroundColor(.blue)
//                            .fontWeight(.semibold)
//                    }
//                }
//                .padding(.bottom, 20)
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("SignIn")
//        }
//        // Применяем жест, который срабатывает одновременно с другими
//        ///первым отрабатывает simultaneousGesture затем все другие обработчики
//        ///поэтому при нажатии на TextField с открытой keyboard клавиатура пропадает а затем снова открывается
//        .simultaneousGesture(
//            TapGesture().onEnded {
//                hideKeyboard()
//            }
//        )
//        .confirmationDialog(
//            "Внимание",
//            isPresented: $viewModel.showAnonymousWarning,
//            titleVisibility: .visible
//        ) {
//            Button("Продолжить вход") {
//                viewModel.confirmAnonymousSignIn()
//            }
//            Button("Отмена", role: .cancel) {}
//        } message: {
//            Text("Вы вошли как гость. После входа с email/password все несохранённые данные будут утеряны. Чтобы сохранить их — сначала зарегистрируйтесь.")
//        }
//
//    }
//    
//    private func focusNextField() {
//        switch isFieldFocus {
//        case .emailField:
//            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//        case .securePasswordField, .passwordField:
//            isFieldFocus = nil
//        default:
//            isFieldFocus = nil
//        }
//    }
//    
//    
//    private func login() {
//        // Защита от повторного срабатывания
//        guard viewModel.signInState != .loading else { return }
//        
//        // Обновляем валидацию полей
//        viewModel.updateValidationEmail()
//        viewModel.updateValidationPassword()
//        
//        if viewModel.isValid {
//            print("Данные валидны. Начинаем регистрацию.")
//            viewModel.trySignInWithWarningIfNeeded()
////            viewModel.signIn()
//        } else {
//            print("Некоторые поля заполнены неверно.")
//        }
//    }
//}






//            viewModel.isSignIn = true
// Симуляция асинхронного процесса регистрации, который может быть заменён реальным API-вызовом
//            viewModel.signInUser { success in
//                // Выключаем спиннер после завершения регистрации
//                DispatchQueue.main.async {
////                    viewModel.isSignIn = false
//                }
//            }
