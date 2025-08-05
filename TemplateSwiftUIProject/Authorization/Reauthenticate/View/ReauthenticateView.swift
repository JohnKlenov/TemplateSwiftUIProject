//
//  ReauthenticateView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//

import SwiftUI
/// делаем только с полем email and password and forgot password (Apple and Google это отдельные reauthenticateView)
struct ReauthenticateView: View {
    @ObservedObject var viewModel: ReauthenticateViewModel
    // Состояние для переключения видимости пароля
    @State private var isPasswordVisible = false
    @FocusState var isFieldFocus: FieldToFocus?
    
//    @ObservedObject var viewModel: SignInViewModel
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
                        guard viewModel.reauthState != .loading else { return }
                        // Обработка нажатия "Forgot Password?"
                        print("Forgot Password tapped")
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)

                // button LogIn
                Button(action: login) {
                    Group {
                        if viewModel.reauthState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Confirm")
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
                .disabled(viewModel.reauthState == .loading)
                
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
                        guard viewModel.reauthState != .loading else { return }
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
                    
                    // Кнопка Google
                    Button(action: {
                        guard viewModel.reauthState != .loading else { return }
                        print("googlelogo")
                    }) {
                        Image("googlelogo")
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(width: 60, height: 60) // ← Жёсткий размер
                            .background(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                }
                .padding(.vertical, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Reauth")
        }
        // Применяем жест, который срабатывает одновременно с другими
        ///первым отрабатывает simultaneousGesture затем все другие обработчики
        ///поэтому при нажатии на TextField с открытой keyboard клавиатура пропадает а затем снова открывается
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
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
        // Защита от повторного срабатывания
        guard viewModel.reauthState != .loading else { return }
        
        // Обновляем валидацию полей
        viewModel.updateValidationEmail()
        viewModel.updateValidationPassword()
        
        if viewModel.isValid {
            print("Данные валидны. Начинаем reauthenticate.")
            viewModel.reauthenticate()
        } else {
            print("Некоторые поля заполнены неверно.")
        }
    }
//    var body: some View {
//        Text("ReauthenticateView")
//    }
}

//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Для выполнения удаления аккаунта нужна свежая авторизация")
//                .multilineTextAlignment(.center)
//                .padding()
//
//            TextField("Email", text: $viewModel.email)
//                .textFieldStyle(.roundedBorder)
//            SecureField("Пароль", text: $viewModel.password)
//                .textFieldStyle(.roundedBorder)
//
//            if let err = viewModel.emailError {
//                Text(err).foregroundColor(.red).font(.caption)
//            }
//
//            Button(action: viewModel.reauthenticate) {
//                if viewModel.registeringState == .loading {
//                    ProgressView()
//                } else {
//                    Text("Повторить вход")
//                }
//            }
//            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//    }
