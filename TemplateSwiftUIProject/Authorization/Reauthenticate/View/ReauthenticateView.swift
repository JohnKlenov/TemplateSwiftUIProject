//
//  ReauthenticateView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//


//когда мы выбрасываем пользователя на ReauthenticateView можем проверить через какой он провайдер входил в систему и именно такой интерфейс в ReauthenticateView сразу отобразить для пользователя!

///Firebase предоставляет массив user.providerData, и ты можешь взять оттуда providerId. Пример на Swift:
///if let provider = Auth.auth().currentUser?.providerData.first?.providerID {print("Пользователь вошёл через: \(provider)")}
///Рекомендуемое поведение при повторной аутентификации:
///providerId определён - Показывай только релевантный UI: например, форму пароля для password, Google-кнопку для google.com, и т.д.
///providerData пуст или не содержит нужного - Показывай все возможные провайдеры: email+пароль, Google, Apple и т.д.
///Почему providerData может быть пустым? - Если пользователь вошёл анонимно + Если ты очистил providerData вручную при миграции аккаунта + Если используется нестандартный провайдер или кастомный токен
///Чтобы в будущем не полагаться на user.providerData, можно при регистрации сохранить providerId в Firestore или UserDefaults.
///let providerID = Auth.auth().currentUser?.providerData.first?.providerID UserDefaults.standard.set(providerID, forKey: "authProvider")


import SwiftUI

struct ReauthenticateView: View {
    @ObservedObject var viewModel: ReauthenticateViewModel
    @State private var isPasswordVisible = false
    @FocusState var isFieldFocus: FieldToFocusAuth?
    
    @EnvironmentObject var localization: LocalizationService
    @EnvironmentObject var accountCoordinator: AccountCoordinator
    
    var body: some View {
        Group {
            switch viewModel.providerType {
            case .password, .unknown(_):
                // здесь форма может быть длинной → нужен ScrollView
                ScrollView(.vertical, showsIndicators: false) {
                    contentSection
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Reauth")
                }

            case .google, .apple:
                // здесь всего одна кнопка → ScrollView не нужен
                VStack {
                    Spacer()
                    Spacer()
                    contentSection
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Reauth")

            case .none:
                EmptyView()
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded { hideKeyboard() }
        )
    }
    
    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.providerType {
        case .password:
            VStack(spacing: 20) {
                formSection
                forgotPasswordSection
                confirmButton
            }

        case .google:
            googleFullButton   // полноценная кнопка по центру

        case .apple:
            appleFullButton    // полноценная кнопка по центру

        case .unknown(_):
            VStack(spacing: 20) {
                formSection
                forgotPasswordSection
                confirmButton
                
                divider
                
                HStack(spacing: 40) {
                    appleButton   // компактная версия
                    googleButton  // компактная версия
                }
            }

        case .none:
            EmptyView()
        }
    }

    
    // MARK: - Form
    
    private var formSection: some View {
        VStack(spacing: 15) {
            emailField
            passwordField
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var forgotPasswordSection: some View {
        HStack {
            Spacer()
            Button(action: {
                print("Forgot Password tapped")
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
            .disabled(viewModel.isAuthOperationInProgress)
        }
        .padding(.horizontal)
    }
    
    private var confirmButton: some View {
        Button(action: login) {
            Group {
                if viewModel.reauthState == .loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Confirm")
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
    }
    
    // MARK: - Providers
    
    private var divider: some View {
        HStack {
            VStack { Divider().frame(height: 1).background(Color.primary) }
            Text(Localized.SignUpView.or.localized())
                .font(.footnote)
                .foregroundColor(.primary)
            VStack { Divider().frame(height: 1).background(Color.primary) }
        }
        .padding([.horizontal, .vertical])
    }
    
    private var appleButton: some View {
        Button(action: {
            print("applelogo")
        }) {
            Image(systemName: "applelogo")
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: 60, height: 60)
                .tint(AppColors.primary)
                .background(Circle().stroke(Color.gray, lineWidth: 1))
        }
        .disabled(viewModel.isAuthOperationInProgress)
    }
    
    private var googleButton: some View {
        Button(action: {
            print("googlelogo")
        }) {
            Image("googlelogo")
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: 60, height: 60)
                .background(Circle().stroke(Color.gray, lineWidth: 1))
        }
        .disabled(viewModel.isAuthOperationInProgress)
    }

    // тут пока не понятно стоит ли блокировать нажатие при .disabled(viewModel.isAuthOperationInProgress)
    private var googleFullButton: some View {
        Button(action: {
            print("Google reauth tapped")
        }) {
            HStack(spacing: 12) {
                Image("googlelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("Reauthenticate with Google")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
        }
        .padding(.horizontal)
        .disabled(viewModel.isAuthOperationInProgress)
    }

    private var appleFullButton: some View {
        Button(action: {
            print("Apple reauth tapped")
        }) {
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .tint(AppColors.primary)
                Text("Reauthenticate with Apple")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
        }
        .padding(.horizontal)
        .disabled(viewModel.isAuthOperationInProgress)
    }

    
    // MARK: - Fields
    
    private var emailField: some View {
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
                .onTapGesture { viewModel.emailError = nil }
            if let error = viewModel.emailError {
                Text(error.localized())
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var passwordField: some View {
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
                            .onChange(of: viewModel.password) { _, _ in
                                viewModel.updateValidationPassword()
                            }
                            .onTapGesture { viewModel.passwordError = nil }
                    } else {
                        SecureField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
                            .submitLabel(.done)
                            .focused($isFieldFocus, equals: .securePasswordField)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit { focusNextField() }
                            .onChange(of: viewModel.password) { _, _ in
                                viewModel.updateValidationPassword()
                            }
                            .onTapGesture { viewModel.passwordError = nil }
                    }
                }
                
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
    
    
    // MARK: - Actions
    
    private func login() {
        
        viewModel.updateValidationEmail()
        viewModel.updateValidationPassword()
        
        if viewModel.isValid {
            print("Данные валидны. Начинаем reauthenticate.")
            viewModel.reauthenticate()
        } else {
            print("Некоторые поля заполнены неверно.")
        }
    }
}





// MARK: - before Local states

//import SwiftUI
//
//struct ReauthenticateView: View {
//    @ObservedObject var viewModel: ReauthenticateViewModel
//    @State private var isPasswordVisible = false
//    @FocusState var isFieldFocus: FieldToFocusAuth?
//    
//    @EnvironmentObject var localization: LocalizationService
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//    
//    var body: some View {
//        Group {
//            switch viewModel.providerType {
//            case .password, .unknown(_):
//                // здесь форма может быть длинной → нужен ScrollView
//                ScrollView(.vertical, showsIndicators: false) {
//                    contentSection
//                        .navigationBarTitleDisplayMode(.inline)
//                        .navigationTitle("Reauth")
//                }
//
//            case .google, .apple:
//                // здесь всего одна кнопка → ScrollView не нужен
//                VStack {
//                    Spacer()
//                    Spacer()
//                    contentSection
//                    Spacer()
//                }
//                .frame(maxHeight: .infinity)
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationTitle("Reauth")
//
//            case .none:
//                EmptyView()
//            }
//        }
//        .simultaneousGesture(
//            TapGesture().onEnded { hideKeyboard() }
//        )
//    }
//    
//    // MARK: - Content
//
//    @ViewBuilder
//    private var contentSection: some View {
//        switch viewModel.providerType {
//        case .password:
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//            }
//
//        case .google:
//            googleFullButton   // полноценная кнопка по центру
//
//        case .apple:
//            appleFullButton    // полноценная кнопка по центру
//
//        case .unknown(_):
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//                
//                divider
//                
//                HStack(spacing: 40) {
//                    appleButton   // компактная версия
//                    googleButton  // компактная версия
//                }
//            }
//
//        case .none:
//            EmptyView()
//        }
//    }
//
//    
//    // MARK: - Form
//    
//    private var formSection: some View {
//        VStack(spacing: 15) {
//            emailField
//            passwordField
//        }
//        .padding(.horizontal)
//        .padding(.top, 20)
//    }
//    
//    private var forgotPasswordSection: some View {
//        HStack {
//            Spacer()
//            Button(action: {
//                guard viewModel.reauthState != .loading else { return }
//                print("Forgot Password tapped")
//            }) {
//                Text("Forgot Password?")
//                    .foregroundColor(.blue)
//                    .fontWeight(.semibold)
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    private var confirmButton: some View {
//        Button(action: login) {
//            Group {
//                if viewModel.reauthState == .loading {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                } else {
//                    Text("Confirm")
//                }
//            }
//            .frame(maxWidth: .infinity)
//            .contentShape(Rectangle())
//        }
//        .fontWeight(.semibold)
//        .padding()
//        .background(AppColors.activeColor)
//        .foregroundColor(AppColors.primary)
//        .cornerRadius(8)
//        .padding(.horizontal)
//        .disabled(viewModel.reauthState == .loading)
//    }
//    
//    // MARK: - Providers
//    
//    private var divider: some View {
//        HStack {
//            VStack { Divider().frame(height: 1).background(Color.primary) }
//            Text(Localized.SignUpView.or.localized())
//                .font(.footnote)
//                .foregroundColor(.primary)
//            VStack { Divider().frame(height: 1).background(Color.primary) }
//        }
//        .padding([.horizontal, .vertical])
//    }
//    
//    private var appleButton: some View {
//        Button(action: {
//            guard viewModel.reauthState != .loading else { return }
//            print("applelogo")
//        }) {
//            Image(systemName: "applelogo")
//                .resizable()
//                .scaledToFit()
//                .padding()
//                .frame(width: 60, height: 60)
//                .tint(AppColors.primary)
//                .background(Circle().stroke(Color.gray, lineWidth: 1))
//        }
//    }
//    
//    private var googleButton: some View {
//        Button(action: {
//            guard viewModel.reauthState != .loading else { return }
//            print("googlelogo")
//        }) {
//            Image("googlelogo")
//                .resizable()
//                .scaledToFit()
//                .padding()
//                .frame(width: 60, height: 60)
//                .background(Circle().stroke(Color.gray, lineWidth: 1))
//        }
//    }
//
//    private var googleFullButton: some View {
//        Button(action: {
//            guard viewModel.reauthState != .loading else { return }
//            print("Google reauth tapped")
//        }) {
//            HStack(spacing: 12) {
//                Image("googlelogo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 24, height: 24)
//                Text("Reauthenticate with Google")
//                    .fontWeight(.semibold)
//                    .foregroundColor(.primary)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
//        }
//        .padding(.horizontal)
//    }
//
//    private var appleFullButton: some View {
//        Button(action: {
//            guard viewModel.reauthState != .loading else { return }
//            print("Apple reauth tapped")
//        }) {
//            HStack(spacing: 12) {
//                Image(systemName: "applelogo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 24, height: 24)
//                    .tint(AppColors.primary)
//                Text("Reauthenticate with Apple")
//                    .fontWeight(.semibold)
//                    .foregroundColor(.primary)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
//        }
//        .padding(.horizontal)
//    }
//
//    
//    // MARK: - Fields
//    
//    private var emailField: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            Text(Localized.SignUpView.email.localized())
//                .font(.subheadline)
//                .foregroundColor(AppColors.primary)
//            TextField(Localized.SignUpView.emailPlaceholder.localized(), text: $viewModel.email)
//                .submitLabel(.next)
//                .focused($isFieldFocus, equals: .emailField)
//                .onSubmit { focusNextField() }
//                .padding()
//                .background(Color.gray.opacity(0.1))
//                .cornerRadius(8)
//                .keyboardType(.emailAddress)
//                .disableAutocorrection(true)
//                .autocapitalization(.none)
//                .onTapGesture { viewModel.emailError = nil }
//            if let error = viewModel.emailError {
//                Text(error.localized())
//                    .font(.caption)
//                    .foregroundColor(.red)
//            }
//        }
//    }
//    
//    private var passwordField: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            Text(Localized.SignUpView.password.localized())
//                .font(.subheadline)
//                .foregroundColor(AppColors.primary)
//            HStack {
//                Group {
//                    if isPasswordVisible {
//                        TextField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
//                            .submitLabel(.done)
//                            .focused($isFieldFocus, equals: .passwordField)
//                            .textContentType(.password)
//                            .autocapitalization(.none)
//                            .disableAutocorrection(true)
//                            .onSubmit { focusNextField() }
//                            .onChange(of: viewModel.password) { _, _ in
//                                viewModel.updateValidationPassword()
//                            }
//                            .onTapGesture { viewModel.passwordError = nil }
//                    } else {
//                        SecureField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
//                            .submitLabel(.done)
//                            .focused($isFieldFocus, equals: .securePasswordField)
//                            .textContentType(.password)
//                            .autocapitalization(.none)
//                            .disableAutocorrection(true)
//                            .onSubmit { focusNextField() }
//                            .onChange(of: viewModel.password) { _, _ in
//                                viewModel.updateValidationPassword()
//                            }
//                            .onTapGesture { viewModel.passwordError = nil }
//                    }
//                }
//                
//                Button(action: {
//                    isPasswordVisible.toggle()
//                    isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//                }) {
//                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                        .foregroundColor(.gray)
//                }
//            }
//            .padding()
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(8)
//            if let error = viewModel.passwordError {
//                Text(error.localized())
//                    .font(.caption)
//                    .foregroundColor(.red)
//            }
//        }
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
//    // MARK: - Actions
//    
//    private func login() {
//        guard viewModel.reauthState != .loading else { return }
//        viewModel.updateValidationEmail()
//        viewModel.updateValidationPassword()
//        
//        if viewModel.isValid {
//            print("Данные валидны. Начинаем reauthenticate.")
//            viewModel.reauthenticate()
//        } else {
//            print("Некоторые поля заполнены неверно.")
//        }
//    }
//}





// MARK: - before AuthProviderType



//import SwiftUI
//
//struct ReauthenticateView: View {
//    @ObservedObject var viewModel: ReauthenticateViewModel
//    @State private var isPasswordVisible = false
//    @FocusState var isFieldFocus: FieldToFocusAuth?
//    
//    @EnvironmentObject var localization: LocalizationService
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//    
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            contentSection
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationTitle("Reauth")
//        }
//        .simultaneousGesture(
//            TapGesture().onEnded { hideKeyboard() }
//        )
//    }
//    
//    // MARK: - Content
//
//    @ViewBuilder
//    private var contentSection: some View {
//        switch viewModel.providerType {
//        case .password:
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//            }
//
//        case .google:
//            VStack(spacing: 20) {
//                googleFullButton
//            }
//            .padding(.vertical, 10)
//            
//        case .apple:
//            VStack(spacing: 20) {
//                appleFullButton
//            }
//            .padding(.vertical, 10)
//            
//        case .unknown(_):
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//                
//                divider
//                
//                HStack(spacing: 40) {
//                    appleButton   // компактная версия
//                    googleButton  // компактная версия
//                }
//            }
//            .padding(.vertical, 10)
//            
//        case .none:
//            EmptyView()
//        }
//    }






//    @ViewBuilder
//    private var contentSection: some View {
//        switch viewModel.providerType {
//        case .password:
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//            }
//
//        case .google:
//            VStack(spacing: 20) {
//                googleButton
//            }
//            .padding(.vertical, 10)
//
//        case .apple:
//            VStack(spacing: 20) {
//                appleButton
//            }
//            .padding(.vertical, 10)
//
//        case .unknown(_):
//            VStack(spacing: 20) {
//                formSection
//                forgotPasswordSection
//                confirmButton
//
//                divider
//
//                HStack(spacing: 40) {
//                    appleButton
//                    googleButton
//                }
//            }
//            .padding(.vertical, 10)
//
//        case .none:
//            // ⚡️ nil → аноним или logout → ничего не показываем
//            EmptyView()
//        }
//    }



//@ViewBuilder
//private var contentSection: some View {
//    switch viewModel.providerID {
//    case "password":
//        VStack(spacing: 20) {
//            formSection
//            forgotPasswordSection
//            confirmButton
//        }
//        
//    case "google.com":
//        VStack(spacing: 20) {
//            googleButton
//        }
//        .padding(.vertical, 10)
//        
//    case "apple.com":
//        VStack(spacing: 20) {
//            appleButton
//        }
//        .padding(.vertical, 10)
//        
//    default:
//        VStack(spacing: 20) {
//            formSection
//            forgotPasswordSection
//            confirmButton
//            
//            divider
//            
//            HStack(spacing: 40) {
//                appleButton
//                googleButton
//            }
//        }
//        .padding(.vertical, 10)
//    }
//}



//    @ViewBuilder
//    private var contentSection: some View {
//        if let providerID = viewModel.providerID {
//            switch providerID {
//            case "password":
//                VStack(spacing: 20) {
//                    formSection
//                    forgotPasswordSection
//                    confirmButton
//                }
//            case "google.com":
//                googleButton
//            case "apple.com":
//                appleButton
//            default:
//                VStack(spacing: 20) {
//                    formSection
//                    forgotPasswordSection
//                    confirmButton
//                    divider
//                    HStack(spacing: 40) {
//                        appleButton
//                        googleButton
//                    }
//                }
//            }
//        } else {
//            // ⚡️ nil → аноним или logout → ничего не показываем
//            EmptyView()
//        }
//    }




// MARK: - before get provaider



//import SwiftUI
//
//
//// это общий ReauthenticateView (со всеми провайдерами входа)
//struct ReauthenticateView: View {
//    @ObservedObject var viewModel: ReauthenticateViewModel
//    // Состояние для переключения видимости пароля
//    @State private var isPasswordVisible = false
//    @FocusState var isFieldFocus: FieldToFocusAuth?
//    
////    @ObservedObject var viewModel: SignInViewModel
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
//                        guard viewModel.reauthState != .loading else { return }
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
//                        if viewModel.reauthState == .loading {
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle())
//                        } else {
//                            Text("Confirm")
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
//                .disabled(viewModel.reauthState == .loading)
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
//                        guard viewModel.reauthState != .loading else { return }
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
//                        guard viewModel.reauthState != .loading else { return }
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
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Reauth")
//        }
//        // Применяем жест, который срабатывает одновременно с другими
//        ///первым отрабатывает simultaneousGesture затем все другие обработчики
//        ///поэтому при нажатии на TextField с открытой keyboard клавиатура пропадает а затем снова открывается
//        .simultaneousGesture(
//            TapGesture().onEnded {
//                hideKeyboard()
//            }
//        )
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
//        guard viewModel.reauthState != .loading else { return }
//        
//        // Обновляем валидацию полей
//        viewModel.updateValidationEmail()
//        viewModel.updateValidationPassword()
//        
//        if viewModel.isValid {
//            print("Данные валидны. Начинаем reauthenticate.")
//            viewModel.reauthenticate()
//        } else {
//            print("Некоторые поля заполнены неверно.")
//        }
//    }
//}











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
